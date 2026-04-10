export class EmployeeListPage {
  constructor(page) {
    this.page = page;
    this.addButton = page.locator('button:has-text("Add Employee")');
    this.employeeTable = page.locator('table');
    this.searchInput = page.locator('input[placeholder*="search" i], input[placeholder*="filter" i]');
    this.editButtons = page.locator('[data-action="edit"]');
    this.deleteButtons = page.locator('[data-action="delete"]');
  }

  async goto() {
    await this.page.goto('/list');
  }

  async clickAddEmployee() {
    await this.addButton.click();
  }

  async getEmployeeCount() {
    const rows = await this.page.locator('table tbody tr').count();
    return rows;
  }

  async getEmployeeByName(name) {
    return await this.page.locator(`text=${name}`).first();
  }

  async search(term) {
    await this.searchInput.fill(term);
    await this.page.waitForTimeout(500); // Wait for filter to apply
  }

  async deleteEmployee(name) {
    const row = await this.page.locator(`text=${name}`);
    const deleteButton = row.locator('..').locator('[data-action="delete"]');
    await deleteButton.click();
  }

  async confirmDelete() {
    await this.page.locator('button:has-text("Confirm")').click();
  }

  async editEmployee(name) {
    const row = await this.page.locator(`text=${name}`);
    const editButton = row.locator('..').locator('[data-action="edit"]');
    await editButton.click();
  }
}
