---
name: playwright-e2e-skill
description: >
  Skill for Playwright E2E testing of the Employee Manager application.
  Contains best practices, code templates, and execution instructions.
---

# Playwright E2E Testing Skill

## Setup Instructions

```bash
# Install dependencies
npm init -y
npm install -D @playwright/test
npx playwright install --with-deps chromium

# Project structure
mkdir -p tests/pages tests/e2e tests/fixtures
```

## playwright.config.js

```javascript
import { defineConfig } from '@playwright/test';

export default defineConfig({
  testDir: './tests/e2e',
  timeout: 30000,
  retries: 1,
  use: {
    baseURL: 'http://localhost:5173',
    headless: true,
    screenshot: 'only-on-failure',
    trace: 'on-first-retry',
    viewport: { width: 1280, height: 720 },
  },
  reporter: [
    ['list'],
    ['json', { outputFile: 'reports/results.json' }],
    ['html', { outputFolder: 'reports/html' }],
  ],
  projects: [
    { name: 'chromium', use: { browserName: 'chromium' } },
  ],
});
```

## Page Objects

### tests/pages/LoginPage.js
```javascript
export class LoginPage {
  constructor(page) {
    this.page = page;
    this.usernameInput = page.locator('input[type="text"], input[name="username"]').first();
    this.passwordInput = page.locator('input[type="password"]').first();
    this.loginButton = page.getByRole('button', { name: /login/i });
    this.errorMessage = page.locator('.MuiAlert-root, [role="alert"]');
  }

  async goto() {
    await this.page.goto('/login');
    await this.page.waitForLoadState('networkidle');
  }

  async login(username, password) {
    await this.usernameInput.fill(username);
    await this.passwordInput.fill(password);
    await this.loginButton.click();
  }

  async expectError() {
    await expect(this.errorMessage).toBeVisible({ timeout: 5000 });
  }
}
```

### tests/pages/EmployeeListPage.js
```javascript
export class EmployeeListPage {
  constructor(page) {
    this.page = page;
    this.searchInput = page.locator('input[type="text"]').first();
    this.addButton = page.getByRole('button', { name: /add/i });
    this.table = page.locator('table, .MuiTable-root');
    this.rows = page.locator('tbody tr, .MuiTableBody-root tr');
  }

  async goto() {
    await this.page.goto('/list');
    await this.page.waitForLoadState('networkidle');
  }

  async search(term) {
    await this.searchInput.fill(term);
    await this.page.waitForTimeout(500); // debounce
  }

  async getRowCount() {
    return await this.rows.count();
  }

  async clickAdd() {
    await this.addButton.click();
  }

  async editEmployee(name) {
    const row = this.page.locator(`tr:has-text("${name}")`);
    await row.getByRole('button', { name: /edit/i }).click();
  }

  async deleteEmployee(name) {
    const row = this.page.locator(`tr:has-text("${name}")`);
    await row.getByRole('button', { name: /delete/i }).click();
  }

  async expectEmployeeVisible(name) {
    await expect(this.page.getByText(name)).toBeVisible();
  }

  async expectEmployeeNotVisible(name) {
    await expect(this.page.getByText(name)).not.toBeVisible();
  }
}
```

### tests/pages/EmployeeFormPage.js
```javascript
export class EmployeeFormPage {
  constructor(page) {
    this.page = page;
    this.nameInput = page.locator('input[name="name"], label:has-text("Name") + div input').first();
    this.emailInput = page.locator('input[name="email"], label:has-text("Email") + div input').first();
    this.positionInput = page.locator('input[name="position"], label:has-text("Position") + div input').first();
    this.submitButton = page.getByRole('button', { name: /submit|save|add/i });
  }

  async fillForm(name, email, position) {
    await this.nameInput.fill(name);
    await this.emailInput.fill(email);
    await this.positionInput.fill(position);
  }

  async submit() {
    await this.submitButton.click();
  }
}
```

## Test Templates

### tests/e2e/auth.spec.js
```javascript
import { test, expect } from '@playwright/test';
import { LoginPage } from '../pages/LoginPage.js';

test.describe('Authentication', () => {
  let loginPage;

  test.beforeEach(async ({ page }) => {
    loginPage = new LoginPage(page);
    await loginPage.goto();
  });

  test('should login with valid credentials', async ({ page }) => {
    await loginPage.login('admin', 'password');
    await expect(page).toHaveURL(/.*list/);
  });

  test('should show error for invalid credentials', async ({ page }) => {
    await loginPage.login('admin', 'wrongpassword');
    await loginPage.expectError();
    await expect(page).toHaveURL(/.*login/);
  });

  test('should redirect to login when not authenticated', async ({ page }) => {
    await page.goto('/list');
    await expect(page).toHaveURL(/.*login/);
  });
});
```

### tests/e2e/employee-crud.spec.js
```javascript
import { test, expect } from '@playwright/test';
import { LoginPage } from '../pages/LoginPage.js';
import { EmployeeListPage } from '../pages/EmployeeListPage.js';
import { EmployeeFormPage } from '../pages/EmployeeFormPage.js';

test.describe('Employee CRUD', () => {
  test.beforeEach(async ({ page }) => {
    const loginPage = new LoginPage(page);
    await loginPage.goto();
    await loginPage.login('admin', 'password');
    await expect(page).toHaveURL(/.*list/);
  });

  test('should display employee list', async ({ page }) => {
    const listPage = new EmployeeListPage(page);
    await expect(listPage.table).toBeVisible();
  });

  test('should add a new employee', async ({ page }) => {
    const listPage = new EmployeeListPage(page);
    await listPage.clickAdd();
    
    const formPage = new EmployeeFormPage(page);
    await formPage.fillForm('Test User', 'test@test.com', 'QA Engineer');
    await formPage.submit();
    
    await page.waitForURL(/.*list/);
    await listPage.expectEmployeeVisible('Test User');
  });

  test('should search for employees', async ({ page }) => {
    const listPage = new EmployeeListPage(page);
    const initialCount = await listPage.getRowCount();
    await listPage.search('specific-name');
    // Verify filtered results
  });
});
```

## Execution Commands

```bash
# Run all tests
npx playwright test

# Run specific test file
npx playwright test tests/e2e/auth.spec.js

# Run with UI mode (debugging)
npx playwright test --ui

# Generate report
npx playwright show-report reports/html
```

## Best Practices for This App

1. **Always login first** — Use `test.beforeEach` to authenticate before CRUD tests
2. **Wait for network** — MUI components render asynchronously; use `waitForLoadState('networkidle')`
3. **MUI Selectors** — Use `role` selectors since MUI renders semantic HTML with ARIA roles
4. **Clean up test data** — Delete employees created during tests in `test.afterEach`
5. **Screenshot on failure** — Configured in playwright.config.js for debugging
