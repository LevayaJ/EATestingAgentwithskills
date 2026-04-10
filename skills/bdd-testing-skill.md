---
name: bdd-testing-skill
description: >
  Skill for BDD/Cucumber testing of the Employee Manager application.
  Contains Gherkin templates, step definition patterns, and execution instructions.
---

# BDD Testing Skill

## Setup Instructions

```bash
# Install dependencies
npm init -y
npm install -D @cucumber/cucumber @playwright/test axios chai
npx playwright install --with-deps chromium

# Project structure
mkdir -p features step-definitions support reports
```

## cucumber.js (Config)

```javascript
module.exports = {
  default: {
    require: ['step-definitions/**/*.js', 'support/**/*.js'],
    format: [
      'progress-bar',
      'json:reports/cucumber-results.json',
      'html:reports/cucumber-report.html',
    ],
    paths: ['features/**/*.feature'],
    publishQuiet: true,
  },
};
```

## Support Files

### support/world.js
```javascript
const { setWorldConstructor, World } = require('@cucumber/cucumber');
const { chromium } = require('@playwright/test');
const axios = require('axios');

class CustomWorld extends World {
  constructor(options) {
    super(options);
    this.baseURL = 'http://localhost:5173';
    this.apiURL = 'http://localhost:4000';
    this.api = axios.create({
      baseURL: this.apiURL,
      timeout: 5000,
      validateStatus: () => true,
    });
  }

  async openBrowser() {
    this.browser = await chromium.launch({ headless: true });
    this.context = await this.browser.newContext({
      viewport: { width: 1280, height: 720 },
    });
    this.page = await this.context.newPage();
  }

  async closeBrowser() {
    if (this.browser) {
      await this.browser.close();
    }
  }
}

setWorldConstructor(CustomWorld);
```

### support/hooks.js
```javascript
const { Before, After, BeforeAll, AfterAll } = require('@cucumber/cucumber');

Before(async function () {
  await this.openBrowser();
});

After(async function (scenario) {
  if (scenario.result.status === 'FAILED' && this.page) {
    const screenshot = await this.page.screenshot();
    this.attach(screenshot, 'image/png');
  }
  await this.closeBrowser();
});

// Cleanup test employees after each scenario
After(async function () {
  if (this.createdEmployeeIds) {
    for (const id of this.createdEmployeeIds) {
      await this.api.delete(`/employees/${id}`);
    }
  }
});
```

## Feature Files

### features/auth.feature
```gherkin
@auth
Feature: User Authentication
  As a user of the Employee Manager
  I want to log in with my credentials
  So that I can access employee management features

  Scenario: Successful login with admin credentials
    Given I am on the login page
    When I enter username "admin" and password "password"
    And I click the Login button
    Then I should be redirected to the employee list
    And I should see the navigation menu bar

  Scenario: Failed login with wrong password
    Given I am on the login page
    When I enter username "admin" and password "wrongpassword"
    And I click the Login button
    Then I should see a login error message
    And I should remain on the login page

  Scenario: Cannot access protected page without login
    Given I am not logged in
    When I try to navigate to the employee list
    Then I should be redirected to the login page

  Scenario Outline: Login with all valid users
    Given I am on the login page
    When I enter username "<username>" and password "<password>"
    And I click the Login button
    Then I should be redirected to the employee list

    Examples:
      | username | password |
      | admin    | password |
      | user     | 123456   |
      | test     | test123  |
```

### features/employee-crud.feature
```gherkin
@crud
Feature: Employee CRUD Operations
  As an authenticated user
  I want to create, read, update, and delete employees
  So that I can manage the employee directory

  Background:
    Given I am logged in as "admin" with password "password"

  Scenario: View the employee list
    When I navigate to the employee list
    Then I should see a table with employee records
    And each row should display name, email, and position

  Scenario: Add a new employee via the form
    When I click the Add Employee button
    And I fill in the employee name "John Automation"
    And I fill in the employee email "john.auto@test.com"
    And I fill in the employee position "Test Engineer"
    And I submit the employee form
    Then I should see "John Automation" in the employee list

  Scenario: Edit an existing employee
    Given an employee named "Edit Target" with email "edit@test.com" and position "Junior" exists
    When I click edit on the employee "Edit Target"
    And I change the position to "Senior Engineer"
    And I submit the employee form
    Then the employee "Edit Target" should have position "Senior Engineer"

  Scenario: Delete an employee
    Given an employee named "Delete Target" with email "delete@test.com" and position "Temp" exists
    When I click delete on the employee "Delete Target"
    And I confirm the deletion
    Then "Delete Target" should no longer appear in the employee list

  Scenario: Add employee via API and verify in UI
    Given I create an employee via API with name "API Created" email "api@test.com" position "Backend"
    When I navigate to the employee list
    Then I should see "API Created" in the employee list
```

### features/search.feature
```gherkin
@search
Feature: Employee Search and Filtering
  As an authenticated user
  I want to search through employees
  So that I can quickly find specific people

  Background:
    Given I am logged in as "admin" with password "password"
    And the following employees exist via API:
      | name          | email               | position      |
      | Alice Search  | alice@search.com    | Designer      |
      | Bob Search    | bob@search.com      | Developer     |
      | Carol Search  | carol@search.com    | Manager       |

  Scenario: Search employee by name
    When I navigate to the employee list
    And I type "Alice" in the search field
    Then I should see "Alice Search" in the results
    And I should not see "Bob Search" in the results

  Scenario: Search employee by position
    When I navigate to the employee list
    And I type "Developer" in the search field
    Then I should see "Bob Search" in the results

  Scenario: Clear search restores full list
    When I navigate to the employee list
    And I type "Alice" in the search field
    And I clear the search field
    Then I should see all employees in the list
```

### features/api-backend.feature
```gherkin
@api
Feature: Backend API Validation
  As a testing agent
  I want to validate the API directly
  So that I can ensure data integrity independent of the UI

  Scenario: API - Create employee returns correct schema
    When I POST to "/employees" with:
      | name         | email            | position   |
      | API Test     | apitest@test.com | Tester     |
    Then the response status should be 200
    And the response should contain "id"
    And the response "name" should be "API Test"

  Scenario: API - Get all employees returns array
    When I GET "/employees"
    Then the response status should be 200
    And the response should be an array

  Scenario: API - Update employee works
    Given I create an employee via API with name "Update Me" email "update@test.com" position "Old"
    When I PUT to "/employees/{lastId}" with:
      | name      | email            | position |
      | Update Me | update@test.com  | New      |
    Then the response status should be 200
    And the response "position" should be "New"

  Scenario: API - Delete employee works
    Given I create an employee via API with name "Delete Me" email "deleteme@test.com" position "Temp"
    When I DELETE "/employees/{lastId}"
    Then the response status should be 200
    And the response "success" should be true

  Scenario: API - Reject incomplete employee data
    When I POST to "/employees" with:
      | name     |
      | Only Name |
    Then the response status should be 400
    And the response should contain "error"
```

## Step Definitions

### step-definitions/auth.steps.js
```javascript
const { Given, When, Then } = require('@cucumber/cucumber');
const { expect } = require('chai');

Given('I am on the login page', async function () {
  await this.page.goto(`${this.baseURL}/login`);
  await this.page.waitForLoadState('networkidle');
});

Given('I am not logged in', async function () {
  await this.page.goto(this.baseURL);
});

Given('I am logged in as {string} with password {string}', async function (user, pass) {
  await this.page.goto(`${this.baseURL}/login`);
  await this.page.waitForLoadState('networkidle');
  await this.page.locator('input[type="text"]').first().fill(user);
  await this.page.locator('input[type="password"]').first().fill(pass);
  await this.page.getByRole('button', { name: /login/i }).click();
  await this.page.waitForURL(/.*list/);
});

When('I enter username {string} and password {string}', async function (user, pass) {
  await this.page.locator('input[type="text"]').first().fill(user);
  await this.page.locator('input[type="password"]').first().fill(pass);
});

When('I click the Login button', async function () {
  await this.page.getByRole('button', { name: /login/i }).click();
  await this.page.waitForTimeout(1000);
});

When('I try to navigate to the employee list', async function () {
  await this.page.goto(`${this.baseURL}/list`);
  await this.page.waitForLoadState('networkidle');
});

Then('I should be redirected to the employee list', async function () {
  await this.page.waitForURL(/.*list/, { timeout: 5000 });
  expect(this.page.url()).to.include('/list');
});

Then('I should see the navigation menu bar', async function () {
  const menuBar = this.page.locator('header, nav, .MuiAppBar-root');
  expect(await menuBar.isVisible()).to.be.true;
});

Then('I should see a login error message', async function () {
  const alert = this.page.locator('.MuiAlert-root, [role="alert"]');
  await alert.waitFor({ state: 'visible', timeout: 5000 });
  expect(await alert.isVisible()).to.be.true;
});

Then('I should remain on the login page', async function () {
  expect(this.page.url()).to.include('/login');
});

Then('I should be redirected to the login page', async function () {
  await this.page.waitForURL(/.*login/, { timeout: 5000 });
  expect(this.page.url()).to.include('/login');
});
```

### step-definitions/employee.steps.js
```javascript
const { Given, When, Then } = require('@cucumber/cucumber');
const { expect } = require('chai');

// Track created employees for cleanup
Given('an employee named {string} with email {string} and position {string} exists',
  async function (name, email, position) {
    const res = await this.api.post('/employees', { name, email, position });
    if (!this.createdEmployeeIds) this.createdEmployeeIds = [];
    this.createdEmployeeIds.push(res.data.id);
    this.lastCreatedId = res.data.id;
  }
);

Given('I create an employee via API with name {string} email {string} position {string}',
  async function (name, email, position) {
    const res = await this.api.post('/employees', { name, email, position });
    expect(res.status).to.equal(200);
    if (!this.createdEmployeeIds) this.createdEmployeeIds = [];
    this.createdEmployeeIds.push(res.data.id);
    this.lastCreatedId = res.data.id;
  }
);

When('I navigate to the employee list', async function () {
  await this.page.goto(`${this.baseURL}/list`);
  await this.page.waitForLoadState('networkidle');
});

When('I click the Add Employee button', async function () {
  await this.page.getByRole('button', { name: /add/i }).click();
  await this.page.waitForLoadState('networkidle');
});

When('I fill in the employee name {string}', async function (name) {
  const input = this.page.locator('input').nth(0);
  await input.fill(name);
});

When('I fill in the employee email {string}', async function (email) {
  const input = this.page.locator('input').nth(1);
  await input.fill(email);
});

When('I fill in the employee position {string}', async function (position) {
  const input = this.page.locator('input').nth(2);
  await input.fill(position);
});

When('I submit the employee form', async function () {
  await this.page.getByRole('button', { name: /submit|save|add/i }).click();
  await this.page.waitForTimeout(1000);
});

When('I click edit on the employee {string}', async function (name) {
  const row = this.page.locator(`tr:has-text("${name}")`);
  await row.getByRole('button', { name: /edit/i }).click();
  await this.page.waitForTimeout(500);
});

When('I change the position to {string}', async function (position) {
  const posInput = this.page.locator('input').nth(2);
  await posInput.clear();
  await posInput.fill(position);
});

When('I click delete on the employee {string}', async function (name) {
  const row = this.page.locator(`tr:has-text("${name}")`);
  await row.getByRole('button', { name: /delete/i }).click();
  await this.page.waitForTimeout(500);
});

When('I confirm the deletion', async function () {
  const confirm = this.page.getByRole('button', { name: /confirm|yes|ok/i });
  if (await confirm.isVisible()) {
    await confirm.click();
  }
  await this.page.waitForTimeout(1000);
});

Then('I should see a table with employee records', async function () {
  const table = this.page.locator('table, .MuiTable-root');
  expect(await table.isVisible()).to.be.true;
});

Then('each row should display name, email, and position', async function () {
  const headers = await this.page.locator('th').allTextContents();
  const headerText = headers.join(' ').toLowerCase();
  expect(headerText).to.include('name');
  expect(headerText).to.include('email');
  expect(headerText).to.include('position');
});

Then('I should see {string} in the employee list', async function (name) {
  await this.page.waitForTimeout(500);
  const cell = this.page.getByText(name);
  expect(await cell.isVisible()).to.be.true;
});

Then('{string} should no longer appear in the employee list', async function (name) {
  await this.page.waitForTimeout(500);
  const cell = this.page.getByText(name);
  expect(await cell.isVisible()).to.be.false;
});

Then('the employee {string} should have position {string}', async function (name, position) {
  const row = this.page.locator(`tr:has-text("${name}")`);
  const rowText = await row.textContent();
  expect(rowText).to.include(position);
});
```

### step-definitions/api.steps.js
```javascript
const { When, Then } = require('@cucumber/cucumber');
const { expect } = require('chai');

When('I POST to {string} with:', async function (endpoint, dataTable) {
  const data = dataTable.hashes()[0];
  this.lastResponse = await this.api.post(endpoint, data);
});

When('I GET {string}', async function (endpoint) {
  this.lastResponse = await this.api.get(endpoint);
});

When('I PUT to {string} with:', async function (endpoint, dataTable) {
  const url = endpoint.replace('{lastId}', this.lastCreatedId);
  const data = dataTable.hashes()[0];
  this.lastResponse = await this.api.put(url, data);
});

When('I DELETE {string}', async function (endpoint) {
  const url = endpoint.replace('{lastId}', this.lastCreatedId);
  this.lastResponse = await this.api.delete(url);
});

Then('the response status should be {int}', function (status) {
  expect(this.lastResponse.status).to.equal(status);
});

Then('the response should contain {string}', function (field) {
  expect(this.lastResponse.data).to.have.property(field);
});

Then('the response {string} should be {string}', function (field, value) {
  expect(String(this.lastResponse.data[field])).to.equal(value);
});

Then('the response {string} should be true', function (field) {
  expect(this.lastResponse.data[field]).to.be.true;
});

Then('the response should be an array', function () {
  expect(Array.isArray(this.lastResponse.data)).to.be.true;
});
```

## Execution Commands

```bash
# Run all BDD tests
npx cucumber-js

# Run tagged scenarios
npx cucumber-js --tags @auth
npx cucumber-js --tags @crud
npx cucumber-js --tags @api
npx cucumber-js --tags @search

# Run with custom format
npx cucumber-js --format json:reports/results.json

# Dry run (check step definitions match)
npx cucumber-js --dry-run
```

## Best Practices for This App

1. **Use Background** for shared login steps across scenarios
2. **Tag scenarios** (@auth, @crud, @api, @search) for selective execution
3. **API setup for UI tests** — Create test data via API, verify in UI (faster than UI-only)
4. **Cleanup hooks** — Track created employee IDs, delete in After hook
5. **Scenario Outline** — Parameterize similar tests (e.g., multi-user login)
6. **Living documentation** — Feature files serve as readable specs for stakeholders
