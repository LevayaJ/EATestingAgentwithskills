Feature: User Authentication
  As a user
  I want to log in to the Employee Manager
  So that I can access employee management features

  Scenario: Login with valid credentials
    Given I am on the login page
    When I enter username "admin" and password "password"
    And I click the login button
    Then I should see the employee list

  Scenario: Login with invalid credentials
    Given I am on the login page
    When I enter username "invalid" and password "wrongpass"
    And I click the login button
    Then I should see an error message

  Scenario: Login with empty fields
    Given I am on the login page
    When I leave username empty
    And I click the login button
    Then I should see a validation error
