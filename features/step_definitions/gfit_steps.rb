require 'benchmark'

Then(/^I see that for the last 7 days I had at least (\d+) active day(?:s)?$/) do |min_expected_occurrences|
  min_expected_occurrences = min_expected_occurrences.to_i

  template_file_path = eval_template_name_str_to_file_path("gfit ok steps day bar")

  res_of_finding, res_image_path = get_templates_on_the_screen(template_file_path, 0.85)

  occurrences = res_of_finding["point_clouds"].to_i
  is_expectation_reached = occurrences >= min_expected_occurrences
  assert_true_custom(is_expectation_reached, "For last 7 days found #{occurrences} successful days,"+
    " but expected more than #{min_expected_occurrences}")
  #remove_file_if_exist(res_image_path) if is_expectation_reached
end

Then(/^I see that I have( not)? done my "(cardio|activity)" day plan$/) do |is_not_done, plan_name|

  expected_status = is_not_done.nil? ? true : false


  activity_template_list = ["gfit ok activ bottom", "gfit ok activ top"]
  cardio_template_list = ["gfit ok cardio bottom", "gfit ok cardio top"]
  
  activity_tmpl_files = activity_template_list.map {|template_name| eval_template_name_str_to_file_path(template_name)}
  cardio_tmpl_files = cardio_template_list.map {|template_name| eval_template_name_str_to_file_path(template_name)}

  activity_find_results, activity_find_images = activity_tmpl_files.reduce([[],[]]) do |memo, tmpl|
    res, im_p = get_templates_on_the_screen(tmpl, 0.9)
    memo[0] << res
    memo[1] << im_p
    memo
  end

  cardio_find_results, cardio_find_images = cardio_tmpl_files.reduce([[],[]]) do |memo, tmpl|
    res, im_p = get_templates_on_the_screen(tmpl, 0.9)
    memo[0] << res
    memo[1] << im_p
    memo
  end

  is_activity_plan_done = activity_find_results.any? {|res| res["point_clouds"].to_i == 1}
  is_cardio_plan_done = cardio_find_results.any? {|res| res["point_clouds"].to_i == 1}
  
  is_actual_plan_done = eval("is_#{plan_name}_plan_done")
  is_expectation_reached = is_actual_plan_done == expected_status
  assert_true_custom(is_expectation_reached, "Day plan '#{plan_name}' is #{is_actual_plan_done ? '' : 'NOT'} done,"+
    " but expected #{expected_status ? '' : 'NOT'} done")
  #activity_find_images.each{|im_p| remove_file_if_exist(im_p)} if is_expectation_reached
  #cardio_find_images.each{|im_p| remove_file_if_exist(im_p)} if is_expectation_reached

end