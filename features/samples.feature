@all
Feature: CV Samples

  @location
  Scenario: Location Office Intellias Kyrylivska 39
    Given I enable location services
    When I press home button
    And I wait for template "menu btn" on the screen
    Then I tap on template "menu btn"
    When I scroll to template "gmaps app icon" on the screen
    Then I tap on template "gmaps app icon"
    And I wait for template "gmaps layers btn" on the screen
    And I tap on template "gmaps clear search field btn" if template exist
    And I wait for template "gmaps empty search field" on the screen
    And I tap on template "gmaps empty search field"
    When I enter text "Intellias Kyrylivska 39"
    And I tap on template "gboard search btn"
    Then I wait 20 seconds to 1 template "gmaps location intellias kyrylivska 39" exist on the screen, use strict comparison

  @location
  @failed
  Scenario: Failed Location Office Intellias Kyrylivska 39
    Given I enable location services
    When I press home button
    And I wait for template "menu btn" on the screen
    Then I tap on template "menu btn"
    When I scroll to template "gmaps app icon" on the screen
    Then I tap on template "gmaps app icon"
    And I wait for template "gmaps layers btn" on the screen
    And I tap on template "gmaps clear search field btn" if template exist
    And I wait for template "gmaps empty search field" on the screen
    And I tap on template "gmaps empty search field"
    When I enter text "Intellias Kyrylivska 15/1"
    And I tap on template "gboard search btn"
    Then I wait 20 seconds to 1 template "gmaps location intellias kyrylivska 39" exist on the screen, use strict comparison

