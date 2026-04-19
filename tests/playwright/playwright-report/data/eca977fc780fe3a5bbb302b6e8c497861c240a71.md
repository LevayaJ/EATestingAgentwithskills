# Instructions

- Following Playwright test failed.
- Explain why, be concise, respect Playwright best practices.
- Provide a snippet of code with the fix, if possible.

# Test info

- Name: auth-crud.spec.js >> Authentication Tests >> should login with valid credentials
- Location: EAEmployeeWithTestSprite\tests\playwright\e2e\auth-crud.spec.js:7:7

# Error details

```
Error: page.goto: net::ERR_CONNECTION_REFUSED at http://localhost:5173/login
Call log:
  - navigating to "http://localhost:5173/login", waiting until "load"

```

# Page snapshot

```yaml
- generic [ref=e3]:
  - generic [ref=e6]:
    - heading "This site can’t be reached" [level=1] [ref=e7]
    - paragraph [ref=e8]:
      - strong [ref=e9]: localhost
      - text: refused to connect.
    - generic [ref=e10]:
      - paragraph [ref=e11]: "Try:"
      - list [ref=e12]:
        - listitem [ref=e13]: Checking the connection
        - listitem [ref=e14]:
          - link "Checking the proxy and the firewall" [ref=e15] [cursor=pointer]:
            - /url: "#buttons"
    - generic [ref=e16]: ERR_CONNECTION_REFUSED
  - generic [ref=e17]:
    - button "Reload" [ref=e19] [cursor=pointer]
    - button "Details" [ref=e20] [cursor=pointer]
```

# Test source

```ts
  1  | export class LoginPage {
  2  |   constructor(page) {
  3  |     this.page = page;
  4  |     // Material-UI TextField inputs can be found by their label or by getByRole
  5  |     this.usernameInput = page.locator('input[type="text"]').first();
  6  |     this.passwordInput = page.locator('input[type="password"]');
  7  |     this.loginButton = page.locator('button[type="submit"]');
  8  |     this.errorMessage = page.locator('[role="alert"], .error, [class*="error"]');
  9  |   }
  10 | 
  11 |   async goto() {
> 12 |     await this.page.goto('/login');
     |                     ^ Error: page.goto: net::ERR_CONNECTION_REFUSED at http://localhost:5173/login
  13 |     await this.page.waitForLoadState('networkidle');
  14 |   }
  15 | 
  16 |   async login(username, password) {
  17 |     await this.usernameInput.fill(username);
  18 |     await this.passwordInput.fill(password);
  19 |     await this.loginButton.click();
  20 |   }
  21 | 
  22 |   async getErrorMessage() {
  23 |     return await this.errorMessage.textContent();
  24 |   }
  25 | 
  26 |   async isErrorVisible() {
  27 |     return await this.page.locator('text=/Invalid credentials|Login failed/i').isVisible().catch(() => false);
  28 |   }
  29 | }
  30 | 
```