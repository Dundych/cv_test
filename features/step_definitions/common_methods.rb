require 'phashion'
require 'fileutils'
require 'benchmark'
require 'rmagick'
require 'time'
require 'uri'


def assert_false_custom(expression, msg = 'Failure')
  logc("method: '#{__method__}', params: '#{expression}', '#{msg[0, 50]}...'")
  if expression
    fail(msg)
  end
end

def assert_true_custom(expression, msg = 'Failure')
  logc("method: '#{__method__}', params: '#{expression}', '#{msg[0, 50]}...'")
  unless expression
    fail(msg)
  end
end

def enter_text_custom(text)
  logc("method: #{__method__}, params: #{text}")

  def input_text_by_adb(symbols)
    `adb -s #{ENV['DEVICE_ID']} shell input text #{symbols}`
  end

  text = text.to_s.gsub(' ', '%s')
  input_text_by_adb text
end

def perform_gesture(gesture_name)
  logc("method: #{__method__}, params: #{gesture_name}")

  assert_true_custom(File.exist?(File.join(PATH_GESTURE_LOCAL, gesture_name)),
                     "Can't find gesture with name '#{gesture_name}' in folder '#{PATH_GESTURE_LOCAL}'." +
                         " It means that gesture was not copied to device and it do not exist there in '#{PATH_GESTURE_DEVICE}'.")

  shell_exec_result = `adb -s #{ENV['DEVICE_ID']} shell "cat #{File.join(PATH_GESTURE_DEVICE, gesture_name)} > /dev/input/event2"`
  shell_exec_status = $?.success?
  assert_true_custom(shell_exec_status,
                     "Fail performing gesture '#{gesture_name}'. Shell_exec_result: #{shell_exec_result}")
end


def logc(msg)
  timestamp = Time.now.strftime("%H:%M:%S").to_s
  if EXTEND_LOGGING_TO_STDOUT
    STDOUT.puts("#{timestamp}: #{msg}\n")
  end

  if @logc_file_path
    File.open(@logc_file_path, "a") {|f| f.write("#{timestamp}: #{msg}\n")}
  end
end

# Open file, parse it with grep pattern and return result list
# @Param [String] file_path
# @Param [String/RegExp] grep_pattern
# @return [Array] Lists of strings which matched grep pattern
def grep_file(file_path, grep_pattern)
  logc("method: #{__method__}, params: #{file_path}, #{grep_pattern}")

  # with File.open(file_path, 'r').each.grep(grep_pattern) possible invalid byte sequence in UTF-8 (ArgumentError)
  # so we use "match" to check if line match pattern and 'scrub' to skip bad encoding symbols
  res = []
  File.open(file_path, 'r').each {|line| res << line if line.scrub.match(grep_pattern)}
  return res
end


def remove_screenshot_file()
  logc("method: #{__method__}")

  remove_file_if_exist $screenshot_file_path
  # FileUtils.mv($screenshot_file_path, "#{$screenshot_file_path[0..-5]}#{Time.now}.png")
end

def remove_file_if_exist(file_path)
  logc("method: #{__method__}, params: #{file_path}")

  FileUtils.rm(file_path) if !file_path.nil? && File.exist?(file_path)
end

def take_screenshot_faster(screenshot_path = File.join(@report_path, "screenshot.png"))
  logc("method: #{__method__}, params: #{screenshot_path}")

  shell_exec_result = `adb -s #{ENV['DEVICE_ID']} shell screencap /sdcard/tmp.png`
  shell_exec_status = $?.success?
  assert_true_custom(shell_exec_status, "Can't take screenshot: shell execution fail. shell_exec_result: #{shell_exec_result}")

  shell_exec_result = `adb -s #{ENV['DEVICE_ID']} pull /sdcard/tmp.png #{screenshot_path}`
  shell_exec_status = $?.success?
  assert_true_custom(shell_exec_status, "Can't pull screenshot from device: shell execution fail. shell_exec_result: #{shell_exec_result}")
  return screenshot_path
end

def eval_name_str_to_file_path(path_to_folder, obj_with_pathes, name_str)
  logc("method: #{__method__}, params: #{obj_with_pathes}, #{obj_with_pathes}, #{name_str}")

  assert_true_custom(obj_with_pathes.has_key?(name_str),
                     "Can't get file name, obj #{obj_with_pathes} has no key '#{name_str}'.")

  file_path_without_ext = File.join(path_to_folder, obj_with_pathes[name_str])

  file_paths = Dir["#{file_path_without_ext}*"]
  assert_false_custom(file_paths.empty?, "Cant find any file in path '#{file_path_without_ext}'")

  file_path = file_paths.first

  return file_path
end

def eval_template_name_str_to_file_path(template_name)
  logc("method: #{__method__}, params: #{template_name}")
  return eval_name_str_to_file_path(PATH_TEMPLATES, TEMPLATES, template_name)
end

def eval_query_name_str_to_file_path(query_image_name)
  logc("method: #{__method__}, params: #{query_image_name}")
  return eval_name_str_to_file_path(PATH_QUERY_IMAGES, QUERY_IMAGES, query_image_name)
end


# Takes screenshot and pull it from device to report path. Set var $screenshot_file_path for reusing in other methods
# @Param: [String] Name for taken screenshot file
# @Param: [Bool] If needs to remove previous screenshot
# @Param: [Bool] If needs crop taken screenshot
# @Return: [String] Path to taken screenshot
def prepare_screenshot(screenshot_name = "screenshot.png", is_remove_previous = true, is_crop = true)
  logc("method: #{__method__}, params: #{screenshot_name}, #{is_remove_previous}, #{is_crop}")

  remove_screenshot_file if is_remove_previous

  $screenshot_file_path = take_screenshot_faster(File.join(@report_path, screenshot_name))

  crop_image($screenshot_file_path) if is_crop

  logc("screenshot saved: #{$screenshot_file_path}")
  return $screenshot_file_path
end

# Exec python script 'find_templates_on_img.py' to get info about occurrence template on image
# @Param: [String] 'template_path' - full path to template image
# @Param: [String] 'image_path' - full path to main image
# @Param: [String] 'output_path' - path to save result image. Default is '' (result won't saved)
# @Param: [Number<Float>] 'threshold' -Threshold ratio (0.01 - 1) Default 0.65
# @Return: [Hash] 'res' {"template_size" => [35, 36],
#                        "found" => 2,
#                        "threshold" => 0.65,
#                        "accepted_values" => [0.7, 0.8],
#                        "min" => 0.7,
#                        "max" => 0.8,
#                        "accepted_points" => [[440, 523], [441, 523]],
#                        "point_clouds" => 1,
#                        "point_clouds_coords" => [[440, 523]]
#                        "rectangle_centers" => [[640, 723]]}
def find_templates_on_img(template_path, image_path, output_path = '', threshold = 0.8)
  logc("method: #{__method__}, params: '#{template_path}', #{image_path}, #{output_path}, #{threshold}")

  ts = Time.now

  # Create shell command to execute
  shell_command = "python #{File.join(PATH_SCRIPTS, "find_templates_on_img.py")} -t '#{template_path}' -i '#{image_path}' -r #{threshold}"
  shell_command += " -o '#{output_path}'" unless output_path.to_s.empty?

  logc("Exec python script:\n     #{shell_command}")

  shell_exec_result = `#{shell_command}`
  shell_exec_status = $?.success?

  assert_true_custom(shell_exec_status,
                     "Execution 'find_templates_on_img.py' fail. Shell_exec_result: #{shell_exec_result}")

  logc("Result of exec python script:\n     #{shell_exec_result}")


  res_hash = {"template_size" => nil,
              "found" => nil,
              "threshold" => nil,
              "accepted_values" => nil,
              "min" => nil,
              "max" => nil,
              "accepted_points" => nil,
              "point_clouds" => nil,
              "point_clouds_coords" => nil,
              "rectangle_centers" => nil}

  # Parse output to get 'template_size'
  match_size = shell_exec_result.match(/^Template size\(h, w\): '(\d+), (\d+)'\.$/)
  assert_false_custom(match_size.nil?,
                      "Script should always output 'Template size' info")
  res_hash["template_size"] = [match_size.captures[0].to_i, match_size.captures[1].to_i]

  # Parse output to get 'found'
  match_found = shell_exec_result.match(/^Found: '(\d+)'\.$/)
  assert_false_custom(match_found.nil?,
                      "Script should always output 'Found' info")

  res_hash["found"] = match_found.captures.first.to_i

  # Parse output to get 'threshold'
  match_threshold = shell_exec_result.match(/^Threshold: '(\d+(?:\.\d+)?)'\.$/)
  assert_false_custom(match_threshold.nil?,
                      "Script should always output 'Threshold' info")

  res_hash["threshold"] = match_threshold.captures.first.to_f

  # if template found, script provide detail info about template locations.
  if res_hash["found"] > 0

    # Parse output to get 'accepted_values'
    match_accepted_values = shell_exec_result.match(/^Accepted values: '\[(.*?)\]'\..*$/)
    assert_false_custom(match_accepted_values.nil?,
                        "Script should always output 'Accepted values' info if 'Found' more than 0 templates")
    res_hash["accepted_values"] = match_accepted_values.captures.first.split(', ').map {|s| s.to_f}

    # Parse output to get 'min'
    match_min = shell_exec_result.match(/.*Min: '(\d+(?:\.\d+)?)'\..*$/)
    assert_false_custom(match_min.nil?,
                        "Script should always output 'Min' info if 'Found' more than 0 templates")
    res_hash["min"] = match_min.captures.first.to_f

    # Parse output to get 'max'
    match_max = shell_exec_result.match(/.*Max: '(\d+(?:\.\d+)?)'\..*$/)
    assert_false_custom(match_max.nil?,
                        "Script should always output 'Max' info if 'Found' more than 0 templates")
    res_hash["max"] = match_max.captures.first.to_f

    # Parse output to get 'accepted_points'
    match_accepted_points = shell_exec_result.match(/^Accepted points: '\[(.*?)\]'\..*$/)
    assert_false_custom(match_accepted_points.nil?,
                        "Script should always output 'Accepted points' info if 'Found' more than 0 templates")
    res_hash["accepted_points"] = match_accepted_points.captures.first.gsub('),',');').split('; ').map {|s| s.gsub(/\((\d+), (\d+)\)/, '\1, \2').split(', ')}

    # Parse output to get 'point_clouds'
    match_point_clouds = shell_exec_result.match(/^Point clouds: '(\d+)'\..*$/)
    assert_false_custom(match_point_clouds.nil?,
                        "Script should always output 'Point cloud' info if 'Found' more than 0 templates")
    res_hash["point_clouds"] = match_point_clouds.captures.first.to_i

    # Parse output to get 'point_clouds_coords'
    match_point_clouds_coords = shell_exec_result.match(/.*With coords: '\[(.*?)\]'\..*$/)
    assert_false_custom(match_point_clouds_coords.nil?,
                        "Script should always output 'With coords' info if 'Found' more than 0 templates")
    res_hash["point_clouds_coords"] = match_point_clouds_coords.captures.first.gsub('),',');').split('; ').map {|s| s.gsub(/\((\d+), (\d+)\)/, '\1, \2').split(', ')}

    # Parse output to get 'rectangle_centers'
    match_rectangle_centers = shell_exec_result.match(/^Rectangle centers: '\[(.*?)\]'\..*$/)
    assert_false_custom(match_rectangle_centers.nil?,
                        "Script should always output 'Rectangle centers' info if 'Found' more than 0 templates")
    res_hash["rectangle_centers"] = match_rectangle_centers.captures.first.gsub('),',');').split('; ').map {|s| s.gsub(/\((\d+), (\d+)\)/, '\1, \2').split(', ')}
  end

  logc("Finding template on image took: #{(Time.now - ts)}s")
  logc("Return value: #{res_hash}")

  return res_hash
end

# Obsolete
# Exec method 'find_templates_on_img', check result, and calculate threshold value to reduce noise,
#   and 1-st (false positives) 2-nd (true negatives) kind errors.
#   We assume, that:
#     - image does not contains templates if method found '0' templates with 'threshold' ~ '0.6',
#     - correct number of templates that contains image, can be located with  threshold,
#         that give density of 'found' / 'point_clouds' < '80' - it means, that for every template,
#         we have < '80' points for each cloud in range of 'threshold' '0.6 - 0.8' with steps '0.02'
# @Param: [String] 'template_path' - full path to template image
# @Param: [String] 'image_path' - full path to main image
# @Param: [String] 'output_path' - path to save result image. Default is '' (result won't saved)
# @Return: [Hash] 'res' find_templates_on_img
def xxx_find_templates_on_img_with_dynamic_threshold(template_path, image_path, output_path = '')
  logc("method: #{__method__}, params: '#{template_path}', #{image_path}, #{output_path}")

  ts = Time.now

  calculated_threshold = nil
  current_density = nil

  min_threshold = 0.6
  max_threshold = 0.8
  threshold_with_no_results = max_threshold
  threshold_step = 0.02
  accepted_density = 80.0


  res = find_templates_on_img(template_path, image_path, output_path)

  # case of 'not found'
  # decrease threshold to ensure that image does not contains templates or find templates
  if res["found"] == 0
    logc("Enter to cycle of decreasing threshold to ensure that image does not contains templates or find templates")
    while true
      logc("Cycle of decreasing threshold")

      threshold_with_no_results = res["threshold"]
      previous_threshold = res["threshold"]
      next_threshold = previous_threshold - threshold_step

      logc("Can't find templates on the screen with threshold '#{threshold_with_no_results}'." +
               " Decreasing threshold to '#{next_threshold}'")

      if next_threshold <= min_threshold
        calculated_threshold = previous_threshold
        logc("Next threshold value '#{next_threshold}' smaller or equal than min threshold '#{min_threshold}'." +
                 " End calculation with threshold value '#{calculated_threshold}'.")
        break
      end

      res = find_templates_on_img(template_path, image_path, nil, next_threshold)
      if res["found"] != 0
        logc("Found '#{res["found"]}' templates on the screen with threshold '#{next_threshold}'" +
                 " Exit from 'decreasing threshold' cycle to function to find accepted level of density")
        break
      end
    end
  end

  # case of 'found' or 'calculated_threshold' is still 'nil'
  # increase threshold to reach 'accepted_density' or 'max_threshold' or 'threshold_with_no_results'
  if calculated_threshold.nil? && !res["point_clouds"].to_s.empty?
    logc("Enter to cycle of increasing threshold to" +
             " reach 'accepted_density' or 'max_threshold' or 'threshold_with_no_results'")
    while true
      logc("Cycle of increasing threshold")

      previous_threshold = res["threshold"]
      current_density = res["found"].to_f / res["point_clouds"].to_f
      next_threshold = previous_threshold + threshold_step

      logc("Found '#{res["point_clouds"]}' point clouds." +
               " Increasing threshold to '#{next_threshold}'")

      if current_density <= accepted_density
        calculated_threshold = previous_threshold
        logc("Accepted density '#{accepted_density}' reached with value '#{current_density}'." +
                 " End calculation with threshold value '#{calculated_threshold}'.")
        break
      end

      if next_threshold >= threshold_with_no_results
        calculated_threshold = previous_threshold
        logc("Next threshold value '#{next_threshold}' greater or equal" +
                 " than threshold with no results '#{threshold_with_no_results}'." +
                 " End calculation with threshold value '#{calculated_threshold}'.")
        break
      end

      if next_threshold >= max_threshold
        calculated_threshold = previous_threshold
        logc("Next threshold value '#{next_threshold}' greater or equal than  max threshold '#{max_threshold}'." +
                 " End calculation with threshold value '#{calculated_threshold}'.")
        break
      end

      res = find_templates_on_img(template_path, image_path, nil, next_threshold)

      if res["point_clouds"].to_s.empty?
        calculated_threshold = previous_threshold

        logc("Next threshold value '#{next_threshold}' cause 'not found' result." +
                 "Exit from 'increasing threshold' cycle with threshold value '#{calculated_threshold}'.")
        break
      end
    end
  end

  assert_false_custom(calculated_threshold.nil?,
                      "Function logic fail. After set of conditions threshold value must be found.")


  logc("Threshold for template '#{File.basename(template_path)}' calculated." +
           "\n  Accepted threshold value: '#{calculated_threshold}'." +
           "\n  Calculated density: '#{current_density}'." +
           "\n    Time spent for threshold calculating: #{(Time.now - ts)}s" +
           "\n     In the end - Finding template with calculated threshold to return it")

  if !res.nil? && (res["threshold"] == calculated_threshold)
    # result with calculated threshold is already exist and saved in res variable
    logc("Template with calculated threshold is already found and saved in 'res' variable. Return it")
  else
    # get result with calculated threshold
    res = find_templates_on_img(template_path, image_path, output_path, calculated_threshold)
  end

  return res
end

# Obsolete
# Take screenshot get number of occurrence template on it (calculate and use dynamic threshold)
# @Param: [String] template_path - full path to template image
# @Param: [String] output_path - path to save result image. Default is '' (result won't saved)
# @Return: [Hash] res_of_finding
def xxx_find_templates_on_the_screen(template_path, output_file_path = '')
  logc("method: #{__method__}, params: '#{template_path}', #{output_file_path}")

  screenshot_path = prepare_screenshot("screenshot.png", true, false)

  res_of_finding = find_templates_on_img_with_dynamic_threshold(template_path, screenshot_path, output_file_path)

  return res_of_finding
end

# Take screenshot get number of occurrence template on it (use strict threshold)
# @Param: [String] template_path - full path to template image
# @Param: [String] output_path - path to save result image. Default is '' (result won't saved)
# @Param: [Float] threshold - Threshold ratio
# @Return: [Hash] res_of_finding
def find_templates_on_the_screen(template_path, output_file_path = '', threshold = 0.8)
  logc("method: #{__method__}, params: '#{template_path}', #{output_file_path}, '#{threshold}',")

  screenshot_path = prepare_screenshot("screenshot.png", true, false)

  res_of_finding = find_templates_on_img(template_path, screenshot_path, output_file_path, threshold)

  return res_of_finding
end

# Get number of templates on the screen, save result image. (Right now, without wait)
# @Param: [String] template_path - full path to template image
# @Param: [Float] threshold - Threshold ratio
# @Return: [Hash] res_of_finding, res_image_path
def get_templates_on_the_screen(template_path, threshold = 0.8)
  logc("method: #{__method__}, params: '#{template_path}', '#{threshold}',")

  res_image_path = File.join(@report_path,
    "#{@scenario_name.to_s.gsub(" ", "_").downcase}" +
    "_result_find_template_" +
    "#{File.basename(template_path)}")

  res_of_finding = find_templates_on_the_screen(template_path, res_image_path, threshold)

  return res_of_finding, res_image_path
end

# Wait until screen will contains 'expected_num_templates_on_screen' or timeout is reached
# @Param: [Number] 'expected_num_templates_on_screen'
# @Param: [String] 'template_path'
# @Param: [Int] 'timeout' in sec
# @Param: [Float] 'threshold_value'.
# @Param: [Bool] 'take_res_if_expect_fail'
# @Return: [Hash] res_of_finding
def wait_templates_on_the_screen(expected_num_templates_on_screen, template_path, timeout = 20, threshold_value = 0.8, take_res_if_expect_fail = true)
  logc("method: #{__method__}, params: #{expected_num_templates_on_screen}, #{template_path}," + 
    " #{timeout}, #{threshold_value} #{take_res_if_expect_fail}")

  time_start = Time.now
  time_end = time_start + timeout.to_i
  logc("Checking will be ended at '#{time_end}'")

  res_image_path = File.join(@report_path,
                             "#{@scenario_name.to_s.gsub(" ", "_").downcase}" +
                             "_result_find_template_" +
                             "#{File.basename(template_path)}")

  #wait for time_end reached OR expectation reached
  res_of_finding = nil
  occurrences = nil
  attempt_counter = 1
  while true
    attempt_time = Time.now
    logc("Attempt: '#{attempt_counter}', time: #{attempt_time}")
    res_of_finding = find_templates_on_the_screen(template_path, res_image_path, threshold_value)
    occurrences = res_of_finding["point_clouds"].to_i

    if (occurrences == expected_num_templates_on_screen) || (attempt_time > time_end)
      break
    else
      attempt_counter += 1
      sleep 1
    end
  end

  assert_false_custom(occurrences.nil? || res_of_finding.nil?,
     "Error: template occurrences or res_of_finding on image can't be nil. Check find method")

  logc("Occurrences found: #{occurrences}\n     Time spent to wait expected result: #{Time.now - time_start}")

  is_expectation_reached = (occurrences == expected_num_templates_on_screen)
  # remove_file_if_exist(res_image_path) if is_expectation_reached || !take_res_if_expect_fail

  return res_of_finding
end

# Exec python script 'find_obj_on_img.py' to get info about occurrence objects on image
# @Param: [String] 'query_image_path' - full path to query image
# @Param: [String] 'image_path' - full path to main image
# @Param: [String] 'output_path' - path to save result image. Default is '' (result won't saved)
# @Return: [Hash] 'res' {"rectangle_centers" => [[640, 723]]}
def find_objects_on_img(query_image_path, image_path, output_path = '')
  logc("method: #{__method__}, params: '#{query_image_path}', #{image_path}, #{output_path}")

  ts = Time.now

  # Create shell command to execute
  shell_command = "python #{File.join(PATH_SCRIPTS, "find_objs_on_img.py")} -q '#{query_image_path}' -t '#{image_path}'"
  shell_command += " -o '#{output_path}'" unless output_path.to_s.empty?

  logc("Exec python script:\n     #{shell_command}")

  shell_exec_result = `#{shell_command}`
  shell_exec_status = $?.success?

  assert_true_custom(shell_exec_status,
                     "Execution 'find_objs_on_img.py' fail. Shell_exec_result: #{shell_exec_result}")

  logc("Result of exec python script:\n     #{shell_exec_result}")


  res_hash = {"rectangle_centers" => nil}

  # Parse output to get 'rectangle_centers'
  match_rectangle_centers = shell_exec_result.match(/^Accepted rectangle centers: '\[(.*?)\]'\..*$/)
  assert_false_custom(match_rectangle_centers.nil?,
                      "Script should always output 'Accepted rectangle centers'.")
  res_hash["rectangle_centers"] = match_rectangle_centers.captures.first.gsub('),',');').split('; ').map {|s| s.gsub(/\((\d+), (\d+)\)/, '\1, \2').split(', ')}


  logc("Finding object on image took: #{(Time.now - ts)}s")
  logc("Return value: #{res_hash}")

  return res_hash
end

# Take screenshot get number of occurrence query object on it
# @Param: [String] query_image_path - full path to query image
# @Param: [String] output_path - path to save result image. Default is '' (result won't saved)
# @Return: [Hash] res_of_finding
def find_objects_on_the_screen(query_image_path, output_file_path = '')
  logc("method: #{__method__}, params: '#{query_image_path}', #{output_file_path}")

  screenshot_path = prepare_screenshot("screenshot.png", true, false)

  res_of_finding = find_objects_on_img(query_image_path, screenshot_path, output_file_path)

  return res_of_finding
end

# Wait until screen will contains 'expected_num_objects_on_screen' or timeout is reached
# @Param: [Number] 'expected_num_objects_on_screen'
# @Param: [String] 'query_image_path'
# @Param: [Int] 'timeout' in sec
# @Param: [Bool] 'take_res_if_expect_fail'
# @Return: [Hash] res_of_finding
def wait_objects_on_the_screen(expected_num_objects_on_screen, query_image_path, timeout = 20, take_res_if_expect_fail = true)
  logc("method: #{__method__}, params: #{expected_num_objects_on_screen}, #{query_image_path}," + 
    " #{timeout}, #{take_res_if_expect_fail}")

  time_start = Time.now
  time_end = time_start + timeout.to_i
  logc("Checking will be ended at '#{time_end}'")

  res_image_path = File.join(@report_path,
                             "#{@scenario_name.to_s.gsub(" ", "_").downcase}" +
                             "_result_find_object_" +
                             "#{File.basename(query_image_path)}")

  #wait for time_end reached OR expectation reached
  res_of_finding = nil
  occurrences = nil
  attempt_counter = 1
  while true
    attempt_time = Time.now
    logc("Attempt: '#{attempt_counter}', time: #{attempt_time}")
    res_of_finding = find_objects_on_the_screen(query_image_path, res_image_path)
    occurrences = res_of_finding["rectangle_centers"].size.to_i

    if (occurrences == expected_num_objects_on_screen) || (attempt_time > time_end)
      break
    else
      attempt_counter += 1
      sleep 1
    end
  end

  assert_false_custom(occurrences.nil? || res_of_finding.nil?,
     "Error: object occurrences or res_of_finding on image can't be nil. Check find method")

  logc("Occurrences found: #{occurrences}\n     Time spent to wait expected result: #{Time.now - time_start}")

  is_expectation_reached = (occurrences == expected_num_objects_on_screen)
  # remove_file_if_exist(res_image_path) if is_expectation_reached || !take_res_if_expect_fail

  return res_of_finding
end

# Wait until screen will contains  1 template, get it coordinates, and tap it
# @Param: [String] 'template_path'
# @Param: [Int] 'template_index' starts from 0
# @Param: [Bool] is_raise_error_if_templ_not_found
# @Param: [Bool] 'take_res_if_find_fail'
def tap_template_on_the_screen(template_path, template_index, is_raise_error_if_templ_not_found = true, take_res_if_find_fail = true)
  logc("method: #{__method__}, params: #{template_path}, #{template_index}," +
    " #{is_raise_error_if_templ_not_found},  #{take_res_if_find_fail}")

  res_image_path = File.join(@report_path,
    "#{@scenario_name.to_s.gsub(" ", "_").downcase}" +
    "_result_find_template_" +
    "#{File.basename(template_path)}")

  find_res = find_templates_on_the_screen(template_path, res_image_path)
  occurrences = find_res["point_clouds"].to_i
  
  is_possible_to_tap_template = (occurrences >= (template_index + 1))
  if is_possible_to_tap_template
    template_center_coords = find_res["rectangle_centers"][template_index]
    tap_on_screen(*template_center_coords)
  else
    msg = "Found '#{occurrences}' occurrences" +
      " templates '#{File.basename(template_path)}' on the screen." +
      " But expected more than or equal to '#{template_index + 1}' occurrences to tap on template with index  #{template_index}." +
      " Check report folder '#{@report_path}' to details."
    if is_raise_error_if_templ_not_found
      assert_true_custom(false, "Fail - " + msg )
    else
      logc("Method is not strict, so Error has not been raised - " + msg)
    end
  end

  # remove_file_if_exist(res_image_path) if is_possible_to_tap_template || !take_res_if_find_fail

end

# Wait until screen will contains 1 template, if not - swipe to it
# @Param: [String] 'template_path'
# @Param: [String] 'direction'
# @Param: [Int] 'max_swipes'
def swipes_to_template_on_the_screen(template_path, direction = "down", max_swipes = 5)
  logc("method: #{__method__}, params: #{template_path}, #{direction}, #{max_swipes}")
  direction_list = ["up", "down", "left", "right"]
  assert_true_custom(direction_list.include?(direction),
    "Wrong param 'direction'. Should be one of #{direction_list}, but found '#{direction}'")

  #wait for swipes numbers reached OR expectation reached
  res_of_finding = nil
  res_image_path = nil
  occurrences = nil
  is_expectation_reached = false
  attempt_counter = 1
  while true
    logc("Attempt: '#{attempt_counter}'")
    res_of_finding, res_image_path = get_templates_on_the_screen(template_path, 0.85)
    occurrences = res_of_finding["point_clouds"].to_i
    is_expectation_reached = occurrences > 0

    if is_expectation_reached || (attempt_counter > max_swipes)
      break
    else
      swipe(direction)
      attempt_counter += 1
    end
  end

  assert_true_custom(is_expectation_reached,
    "During #{attempt_counter} swipes, found '#{occurrences}' occurrences templates '#{File.basename(template_path)}' on the screen." +
        " Check report folder '#{@report_path}' to details.")
  # remove_file_if_exist(res_image_path) if is_expectation_reached
end

def tap_on_screen(x, y)
  logc("method: #{__method__}, params: #{x}, #{y}")
  shell_exec_result = `adb -s #{ENV['DEVICE_ID']} shell "input tap #{x} #{y}"`
  shell_exec_status = $?.success?
  assert_true_custom(shell_exec_status, "Can't tap on device. Shell_exec_result: #{shell_exec_result}")
end

def press_back_button_custom(occurrences = 1)
  logc("method: '#{__method__}', params: #{occurrences}")

  while occurrences > 0 do
    logc("pressing back button")
    `adb -s #{ENV['DEVICE_ID']} shell input keyevent KEYCODE_BACK`
    occurrences -= 1
    sleep 2
  end
end

def swipe(direction, occurrences = 1)
  logc("method: '#{__method__}', params: '#{direction}', '#{occurrences}'")

  while occurrences > 0 do
    perform_gesture("swipe_#{direction}")
    sleep 1
    occurrences -= 1
  end
end