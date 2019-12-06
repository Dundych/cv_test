@all
Feature: CV Samples

  @location
  @k_39
  Scenario: Location Office Intellias Kyrylivska 39
    Given I enable location services
    When I press home button
    And I wait for template "menu btn" on the screen
    Then I tap on template "menu btn"
    When I scroll to template "gmaps app icon" on the screen
    Then I tap on template "gmaps app icon"
    And I wait for template "gmaps layers btn" on the screen
    And On gmail app I configure map view
    And I tap on template "gmaps clear search field btn" if template exist
    And I wait for template "gmaps empty search field" on the screen
    And I tap on template "gmaps empty search field"
    When I enter text "Intellias Kyiv Kyrylivska 39"
    And I tap on template "gboard search btn"
    Then I wait 20 seconds to 1 object "location intellias kyrylivska 39" exist on the screen

  @location
  @k_15
  Scenario: Location Office Intellias Kyrylivska 15
    Given I enable location services
    When I press home button
    And I wait for template "menu btn" on the screen
    Then I tap on template "menu btn"
    When I scroll to template "gmaps app icon" on the screen
    Then I tap on template "gmaps app icon"
    And I wait for template "gmaps layers btn" on the screen
    And On gmail app I configure map view
    And I tap on template "gmaps clear search field btn" if template exist
    And I wait for template "gmaps empty search field" on the screen
    And I tap on template "gmaps empty search field"
    When I enter text "Intellias Kyiv Kyrylivska 15"
    And I tap on template "gboard search btn"
    Then I wait 20 seconds to 1 object "location intellias kyrylivska 15" exist on the screen

  @steps
  Scenario: Steps Number Of Active Days For The Last 7 Days
    Given I press home button
    When I wait for template "menu btn" on the screen
    Then I tap on template "menu btn"
    When I wait for template "app search field" on the screen
    Then I tap on template "app search field"
    When I enter text "google"
    And I wait for template "gfit app icon" on the screen
    Then I tap on template "gfit app icon"
    And I tap on template "gfit main btn" if template exist
    And I scroll to template "gfit steps bar chart" on the screen
    And I see that for the last 7 days I had at least 5 active days

  @activity
  @cardio
  Scenario: Activity Cardio Check if day plan is done
    Given I press home button
    When I wait for template "menu btn" on the screen
    Then I tap on template "menu btn"
    When I wait for template "app search field" on the screen
    Then I tap on template "app search field"
    When I enter text "google"
    And I wait for template "gfit app icon" on the screen
    Then I tap on template "gfit app icon"
    And I swipe up 5 times
    Then I see that I have done my "cardio" day plan
    And I see that I have not done my "activity" day plan