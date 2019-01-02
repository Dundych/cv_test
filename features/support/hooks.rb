AfterConfiguration do |config|
  FEATURE_MEMORY.feature = nil
end

Before do |scenario|
  logc("Hooks. Before scenario")

  config_data_file = File.join(PROJECT_PATH, ENV['DEVICE_ID'])
  if FEATURE_MEMORY.feature.nil?
    @test_timestamp = Time.new.strftime("%Y_%m_%d__%H_%M_%S")
    @report_path = File.join(PROJECT_PATH, "reports", @test_timestamp)
    logc("Creating report folder: #{@report_path}")
    `mkdir -p #{@report_path}`
    File.open(config_data_file , 'w') {|f| f.write("#{@test_timestamp}")}

  else
    File.open(config_data_file , 'r') do |f|
      @test_timestamp = f.read
      @report_path = File.join(PROJECT_PATH, "reports", @test_timestamp)
    end
  end

  scenario = scenario.scenario_outline if scenario.respond_to?(:scenario_outline)
  feature_obj = scenario.feature
  if FEATURE_MEMORY.feature != feature_obj
    FEATURE_MEMORY.feature = feature_obj
  end

  @scenario_name = scenario.name
  @feature_name = scenario.feature
  @scenario_tags = scenario.tags.to_a.map {|tag_obj| tag_obj.name}
  @logc_file_path =  File.join(@report_path, "#{@scenario_name.gsub(' ', '_').gsub('/', 'sub')}_logc.txt")

  logc("Feature  : #{'-' * 10} #{@feature_name} #{'-' * 10}")
  logc("Scenario : #{'-' * 10} #{@scenario_name} #{'-' * 10}")
  logc("Test timestamp: #{'-' * 5}#{@test_timestamp}")


  logc("Push gestures to device")
  # create dir 
  shell_exec_result = `adb -s #{ENV['DEVICE_ID']} shell mkdir -p #{PATH_GESTURE_DEVICE}`
  shell_exec_status = $?.success?
  assert_true_custom(shell_exec_status, "Can't create folder in device. shell_exec_result: #{shell_exec_result}")
  # push files
  shell_exec_result = `adb -s #{ENV['DEVICE_ID']} push #{File.join( PATH_GESTURE_LOCAL, '*')} #{PATH_GESTURE_DEVICE}`
  shell_exec_status = $?.success?
  assert_true_custom(shell_exec_status, "Can't push gestures to device. shell_exec_result: #{shell_exec_result}")
end

After do |scenario|
  logc("Hooks. After scenario")

  remove_screenshot_file

  if scenario.failed?
    prepare_screenshot("#{@scenario_name.gsub(" ", "_")}_failed", false, false)
  end

end

FEATURE_MEMORY = Struct.new(:feature).new
