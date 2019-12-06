# There is possible warning - recording already initialized variable.
# So use LAST_CONSTANT check to avoid that warn
unless defined? LAST_CONSTANT
  EXTEND_LOGGING_TO_STDOUT = true
  PROJECT_PATH = File.expand_path('../..', File.dirname(__FILE__) )

  PATH_QUERY_IMAGES = File.join(PROJECT_PATH, "query_images")
  PATH_TEMPLATES = File.join(PROJECT_PATH, "templates")
  PATH_GESTURE_DEVICE = "/sdcard/GESTURES/"
  PATH_GESTURE_LOCAL = File.join(PROJECT_PATH, "gestures")
  PATH_SCRIPTS = File.join(PROJECT_PATH, "scripts")


  ### Template images
  TEMPLATES = {
      "menu btn" => "menu_btn",
      "app search field" => "app_search_field",

      # gmaps app
      "gmaps app icon" => "gmaps/app_icon",
      "gmaps clear search field btn" => "gmaps/clear_search_field_btn",
      "gmaps empty search field" => "gmaps/empty_search_field",
      "gmaps layers btn" => "gmaps/layers_btn",
      "gmaps satelite btn" => "gmaps/satelite_btn",
      "gmaps shema btn" => "gmaps/shema_btn",
      "gmaps relief btn" => "gmaps/relief_btn",
      "gmaps traffic btn" => "gmaps/traffic_btn",
      "gmaps pub transp btn" => "gmaps/pub_transp_btn",
      "gmaps 3d btn" => "gmaps/3d_btn",
      "gmaps street view btn" => "gmaps/street_view_btn",

      # gfit app
      "gfit app icon" => "gfit/app_icon",
      "gfit ok activ bottom" => "gfit/ok_activ_bottom",
      "gfit ok activ top" => "gfit/ok_activ_top",
      "gfit ok cardio bottom" => "gfit/ok_cardio_bottom",
      "gfit ok cardio top" => "gfit/ok_cardio_top",
      "gfit ok steps day bar" => "gfit/ok_steps_day_bar",
      "gfit steps bar chart" => "gfit/steps_bar_chart",
      "gfit main btn" => "gfit/main_btn",
      "gfit log btn" => "gfit/log_btn",
      "gfit profile btn" => "gfit/profile_btn",

      # gboard app
      "gboard search btn" => "gboard/search_btn"
  }

  ### Query images
  QUERY_IMAGES = {
  "location intellias kyrylivska 39" => "location_intellias_kyrylivska_39.png",
  "location intellias kyrylivska 15" => "location_intellias_kyrylivska_15.png"
  }

  ### KEEP LAST
  LAST_CONSTANT = 'Last Constant Initialized - KEEP THIS CONSTANT LAST'
end