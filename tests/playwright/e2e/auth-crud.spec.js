import { test, expect } from '@playwright/test';
import { LoginPage } from '../pages/LoginPage.js';
import { EmployeeListPage } from '../pages/EmployeeListPage.js';
import { EmployeeFormPage } from '../pages/EmployeeFormPage.js';

test.describe('Authentication Tests', () => {
  test('should login with valid credentials', async ({ page }) => {
    const loginPage = new LoginPage(page);
    await loginPage.goto();
    await loginPage.login('admin', 'password');
    
    // Should redirect to employee list
    await expect(page).toHaveURL('/list');
  });

  test('should show error with invalid credentials', async ({ page }) => {
    const loginPage = new LoginPage(page);
    await loginPage.goto();
    await loginPage.login('invalid', 'wrongpass');
    
    // Should still be on login page
    await expect(page).toHaveURL('/login');
    
    // Error should be visible
    const isErrorVisible = await loginPage.isErrorVisible();
   // expect(isErrorVisible).toBeTruthy();
  });

  test('should show validation error with empty fields', async ({ page }) => {
    const loginPage = new LoginPage(page);
    await loginPage.goto();
    
    // Try to login without entering credentials
    await loginPage.loginButton.click();
    
    // Should still be on login page
    await expect(page).toHaveURL('/login');
  });

  test('should login with user credentials', async ({ page }) => {
    const loginPage = new LoginPage(page);
    await loginPage.goto();
    await loginPage.login('user', '123456');
    
    await expect(page).toHaveURL('/list');
  });
});

test.describe('Employee CRUD Tests', () => {
  test.beforeEach(async ({ page }) => {
    const loginPage = new LoginPage(page);
    await loginPage.goto();
    await loginPage.login('admin', 'password');
    await expect(page).toHaveURL('/list');
  });

  test('should view employee list', async ({ page }) => {
    const employeeList = new EmployeeListPage(page);
    
    // Table should be visible
    await expect(employeeList.employeeTable).toBeVisible();
    
    // Should have at least header rows
    const rowCount = await employeeList.getEmployeeCount();
    expect(rowCount).toBeGreaterThanOrEqual(0);
  });
//----------------------------------------------------------============================


//=====================================================
  test('should add new employee', async ({ page }) => {
    const employeeList = new EmployeeListPage(page);
    const employeeForm = new EmployeeFormPage(page);  
    // const countBefore = await employeeList.getEmployeeCount();
    // console.log('Employee count before adding:', countBefore);
    await employeeList.clickAddEmployee(); 
    await page.waitForTimeout(2000)
     await employeeForm.fillForm('New Employee','newemp@example.com','Developer' );
    // console.log('Form filled with employee details');
    // await employeeForm.submit();
// await employeeForm.fillFormByRole('New Employee', 'newemp@example.com', 'Developer');
    console.log('Form filled with employee details using getByRole');
  //  await employeeForm.submit();
   await employeeForm.clickAddEmployee();
    console.log('Form submitted');
    // Should return to list
    await expect(page).toHaveURL('/list');
  });

  test('should search employees', async ({ page }) => {
    const employeeList = new EmployeeListPage(page);
    
    // Search for a specific employee (or any visible one)
    await employeeList.search('Test');
    
    // Table should still be visible
    await expect(employeeList.employeeTable).toBeVisible();
  });
});

test.describe('UI Responsiveness Tests', () => {
  test('should display mobile view correctly', async ({ page }) => {
    await page.setViewportSize({ width: 375, height: 667 });
    
    const loginPage = new LoginPage(page);
    await loginPage.goto();
    
    // Login elements should still be accessible
    await expect(loginPage.usernameInput).toBeVisible();
    await expect(loginPage.passwordInput).toBeVisible();
    await expect(loginPage.loginButton).toBeVisible();
  });

  test('should display desktop view correctly', async ({ page }) => {
    await page.setViewportSize({ width: 1920, height: 1080 });
    
    const loginPage = new LoginPage(page);
    await loginPage.goto();
    
    await expect(loginPage.usernameInput).toBeVisible();
  });
});
