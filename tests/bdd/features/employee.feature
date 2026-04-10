Feature: Employee Management
  As a manager
  I want to manage employees
  So that I can maintain a complete employee database

  Scenario: View employee list
    Given I am logged in
    When I navigate to the employee list
    Then I should see a list of employees
    And the table should have columns for name, email, and position

  Scenario: Add a new employee
    Given I am logged in
    When I click the "Add Employee" button
    And I fill the form with name "Alice Johnson", email "alice@example.com", position "Designer"
    And I submit the form
    Then the new employee should appear in the list

  Scenario: Edit an employee
    Given I am logged in
    And there is an employee with name "Bob Smith"
    When I click the edit button for "Bob Smith"
    And I change the position to "Senior Manager"
    And I save the changes
    Then "Bob Smith" should have position "Senior Manager"

  Scenario: Delete an employee
    Given I am logged in
    And there is an employee with name "Charlie Brown"
    When I click the delete button for "Charlie Brown"
    And I confirm the deletion
    Then "Charlie Brown" should no longer appear in the list

  Scenario: Search employees by name
    Given I am logged in
    When I enter "Alice" in the search field
    Then only employees with "Alice" in their name should be displayed
