export class EmployeeFormPage {
  constructor(page) {
    this.page = page;
    // Material-UI TextFields - get all text inputs and filter by position
    this.nameInput = page.getByLabel('Name *').last(); 
    this.emailInput = page.getByLabel('Email *');
    this.positionInput = page.locator('input[type="text"]').nth(2);
    this.submitButton = page.locator('button:has-text("Submit"), button:has-text("Save")')
    this.cancelButton = page.locator('button:has-text("Cancel")');
  }



  async goto() {
    await this.page.goto('/form');
    await this.page.waitForLoadState('networkidle');
  }

  async fillForm(name, email, position) {
    await this.nameInput.fill(name);
    await this.emailInput.fill(email);
    await this.positionInput.fill(position);
  }


  async clickAddEmployee() {
    await this.addbutton.click();
  }

  async cancel() {
    await this.cancelButton.click();
  }

  async isFormVisible() {
    return await this.nameInput.isVisible();
  }
}
