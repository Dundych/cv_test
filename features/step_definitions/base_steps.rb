require 'benchmark'



Then(/^I press home button$/) do
  `adb -s #{ENV['DEVICE_ID']} shell input keyevent KEYCODE_HOME`
end

Then(/^I press back button$/) do
  press_back_button_custom
end

Then(/^I enter text "([^"]*)"$/) do |text_to_enter|
  enter_text_custom text_to_enter
end

When(/^I enable location services$/) do
  shell_exec_result = `adb -s #{ENV['DEVICE_ID']} shell settings put secure location_providers_allowed +gps,network`
  shell_exec_status = $?.success?
  assert_true_custom(shell_exec_status, "Can't enable location services. shell_exec_result: #{shell_exec_result}")
  sleep 5
end

Then(/^I take screenshot$/) do
  sleep(1)
  prepare_screenshot
end

Then(/^I wait (\d+) seconds$/) do |seconds|
  seconds = seconds.to_i

  logc("Wait for #{seconds}s." +
           " Script will continue executing at: #{(Time.now + seconds).strftime("%H:%M:%S")}")

  sleep seconds
end

Then(/^I wait (\d+) seconds to (\d+) object(?:s)? "([^"]*)" exist on the screen?$/) do |timeout, expected_occurrences, query_image_name|
  expected_occurrences = expected_occurrences.to_i
  query_image_name = query_image_name.to_s.downcase

  query_image_file_path = eval_query_name_str_to_file_path(query_image_name)
  occurrences = wait_objects_on_the_screen(expected_occurrences, query_image_file_path, timeout)["rectangle_centers"].size.to_i

  assert_true_custom(occurrences == expected_occurrences,
                     "During #{timeout}s, found '#{occurrences}' occurrences objects '#{File.basename(query_image_file_path)}' on the screen." +
                         " But expected '#{expected_occurrences}'. Check report folder '#{@report_path}' to details.")
end

Then(/^I wait for object "([^"]*)" on the screen$/) do |query_name|
  step %Q{I wait 30 seconds to 1 object "#{query_name}" exist on the screen}
end

Then(/^I wait (\d+) seconds to (\d+) template(?:s)? "([^"]*)" exist on the screen?$/) do |timeout, expected_occurrences, template_name|
  expected_occurrences = expected_occurrences.to_i
  template_name = template_name.to_s.downcase

  template_file_path = eval_template_name_str_to_file_path(template_name)
  occurrences = wait_templates_on_the_screen(expected_occurrences, template_file_path, timeout)["point_clouds"].to_i

  assert_true_custom(occurrences == expected_occurrences,
                     "During #{timeout}s, found '#{occurrences}' occurrences templates '#{File.basename(template_file_path)}' on the screen." +
                         " But expected '#{expected_occurrences}'. Check report folder '#{@report_path}' to details.")
end

Then(/^I wait for template "([^"]*)" on the screen$/) do |template_name|
  step %Q{I wait 30 seconds to 1 template "#{template_name}" exist on the screen}
end

Then(/^I wait for template "([^"]*)" disappeared from the screen$/) do |template_name|
  step %Q{I wait 10 seconds to 0 template "#{template_name}" exist on the screen}
end

Then(/^I scroll to template "([^"]*)" on the screen$/) do |template_name|
  template_name = template_name.to_s.downcase

  template_file_path = eval_template_name_str_to_file_path(template_name)
  swipes_to_template_on_the_screen(template_file_path, "down")
end

Then(/^I tap on template "([^"]*)"( if template exist)?$/) do |template_name, is_strict|
  template_name = template_name.to_s.downcase

  template_file_path = eval_template_name_str_to_file_path(template_name)
  tap_template_on_the_screen(template_file_path, 0, is_strict.to_s.empty?)
end