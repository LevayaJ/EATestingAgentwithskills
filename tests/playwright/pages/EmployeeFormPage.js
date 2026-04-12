export class EmployeeFormPage {
  constructor(page) {
    this.page = page;
    // Material-UI TextFields - get all text inputs and filter by position
    this.nameInput = page.getByLabel('Name *').last(); // Assuming name is the last text input
    //page.locator('input[type="text"]').last(); // Assuming name is the last text input
    this.emailInput = page.getByLabel('Email *');
    // page.locator('input[type="email"], input[type="text"]').nth(1);

    this.positionInput = page.locator('input[type="text"]').nth(2);
    this.submitButton = page.locator('button:has-text("Submit"), button:has-text("Save")')
    //page.getByRole('button', { name: 'Add Employee' }).nth(1);
    //page.locator('button:has-text("Submit"), button:has-text("Save")');
    this.cancelButton = page.locator('button:has-text("Cancel")');


this.name = page.getByRole('textbox', { name: 'Name *' });
this.email = page.getByRole('textbox', { name: 'Email *' });
this.position = page.getByRole('textbox', { name: 'Position *' });
this.addbutton =page.getByRole('button', { name: 'Add Employee' });






  }

//page.getByRole('button', { name: 'Add Employee' });

  async goto() {
    await this.page.goto('/form');
    await this.page.waitForLoadState('networkidle');
  }

  async fillForm(name, email, position) {
    await this.nameInput.fill(name);
    await this.emailInput.fill(email);
    await this.positionInput.fill(position);
  }
//========================
  async fillFormByRole(name, email, position) {
    await this.name.fill(name);
    await this.email.fill(email);
    await this.position.fill(position);
  }

  async clickAddEmployee() {
    await this.addbutton.click();
  }

//==
  // async submit() {
  //   await this.submitButton.click();
  // }

  async cancel() {
    await this.cancelButton.click();
  }

  async isFormVisible() {
    return await this.nameInput.isVisible();
  }
}
