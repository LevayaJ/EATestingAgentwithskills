---
name: backend-api-testing-skill
description: >
  Skill for API and backend testing of the Employee Manager Node.js/Express/SQLite application.
  Contains test templates, validation patterns, and execution instructions.
---

# Backend API Testing Skill

## Setup Instructions

```bash
# Install dependencies
npm init -y
npm install -D jest supertest axios

# Project structure
mkdir -p tests/api tests/helpers reports
```

## jest.config.js

```javascript
module.exports = {
  testDir: './tests/api',
  testMatch: ['**/*.test.js'],
  verbose: true,
  testTimeout: 10000,
  reporters: [
    'default',
    ['jest-json-reporter', { outputPath: 'reports/backend-results.json' }],
  ],
};
```

## Test Helpers

### tests/helpers/api-client.js
```javascript
const axios = require('axios');

const BASE_URL = 'http://localhost:4000';

const api = axios.create({
  baseURL: BASE_URL,
  timeout: 5000,
  headers: { 'Content-Type': 'application/json' },
  validateStatus: () => true, // Don't throw on non-2xx
});

module.exports = { api, BASE_URL };
```

### tests/helpers/test-data.js
```javascript
const validCredentials = [
  { username: 'admin', password: 'password' },
  { username: 'user', password: '123456' },
  { username: 'test', password: 'test123' },
];

const invalidCredentials = [
  { username: 'admin', password: 'wrong' },
  { username: 'nobody', password: 'nopass' },
  { username: '', password: '' },
];

const validEmployee = {
  name: 'Test Employee',
  email: 'test@example.com',
  position: 'QA Engineer',
};

const generateEmployee = (index = 0) => ({
  name: `Employee_${index}_${Date.now()}`,
  email: `emp${index}_${Date.now()}@test.com`,
  position: `Position_${index}`,
});

module.exports = {
  validCredentials,
  invalidCredentials,
  validEmployee,
  generateEmployee,
};
```

## Test Templates

### tests/api/auth.test.js
```javascript
const { api } = require('../helpers/api-client');
const { validCredentials, invalidCredentials } = require('../helpers/test-data');

describe('POST /login', () => {
  
  test.each(validCredentials)(
    'should login successfully with $username',
    async ({ username, password }) => {
      const res = await api.post('/login', { username, password });
      expect(res.status).toBe(200);
      expect(res.data.success).toBe(true);
      expect(res.data.user).toBeDefined();
      expect(res.data.user.username).toBe(username);
    }
  );

  test('should reject invalid credentials with 401', async () => {
    const res = await api.post('/login', {
      username: 'admin',
      password: 'wrongpassword',
    });
    expect(res.status).toBe(401);
    expect(res.data.success).toBe(false);
    expect(res.data.error).toBeDefined();
  });

  test('should return 400 when username is missing', async () => {
    const res = await api.post('/login', { password: 'password' });
    expect(res.status).toBe(400);
    expect(res.data.success).toBe(false);
  });

  test('should return 400 when password is missing', async () => {
    const res = await api.post('/login', { username: 'admin' });
    expect(res.status).toBe(400);
    expect(res.data.success).toBe(false);
  });

  test('should return 400 with empty body', async () => {
    const res = await api.post('/login', {});
    expect(res.status).toBe(400);
  });
});
```

### tests/api/employees-crud.test.js
```javascript
const { api } = require('../helpers/api-client');
const { generateEmployee } = require('../helpers/test-data');

describe('Employee CRUD Operations', () => {
  let createdId;

  // ---- CREATE ----
  describe('POST /employees', () => {
    test('should create a new employee', async () => {
      const emp = generateEmployee(1);
      const res = await api.post('/employees', emp);
      
      expect(res.status).toBe(200);
      expect(res.data.id).toBeDefined();
      expect(res.data.name).toBe(emp.name);
      expect(res.data.email).toBe(emp.email);
      expect(res.data.position).toBe(emp.position);
      
      createdId = res.data.id; // save for later tests
    });

    test('should reject when name is missing', async () => {
      const res = await api.post('/employees', {
        email: 'no-name@test.com',
        position: 'Dev',
      });
      expect(res.status).toBe(400);
      expect(res.data.error).toBeDefined();
    });

    test('should reject when email is missing', async () => {
      const res = await api.post('/employees', {
        name: 'No Email',
        position: 'Dev',
      });
      expect(res.status).toBe(400);
    });

    test('should reject when position is missing', async () => {
      const res = await api.post('/employees', {
        name: 'No Position',
        email: 'nopos@test.com',
      });
      expect(res.status).toBe(400);
    });

    test('should reject empty body', async () => {
      const res = await api.post('/employees', {});
      expect(res.status).toBe(400);
    });
  });

  // ---- READ ----
  describe('GET /employees', () => {
    test('should return an array of employees', async () => {
      const res = await api.get('/employees');
      expect(res.status).toBe(200);
      expect(Array.isArray(res.data)).toBe(true);
    });

    test('each employee should have required fields', async () => {
      const res = await api.get('/employees');
      for (const emp of res.data) {
        expect(emp).toHaveProperty('id');
        expect(emp).toHaveProperty('name');
        expect(emp).toHaveProperty('email');
        expect(emp).toHaveProperty('position');
      }
    });

    test('created employee should appear in list', async () => {
      const emp = generateEmployee(99);
      const createRes = await api.post('/employees', emp);
      const listRes = await api.get('/employees');
      
      const found = listRes.data.find(e => e.id === createRes.data.id);
      expect(found).toBeDefined();
      expect(found.name).toBe(emp.name);
      
      // cleanup
      await api.delete(`/employees/${createRes.data.id}`);
    });
  });

  // ---- UPDATE ----
  describe('PUT /employees/:id', () => {
    let tempId;

    beforeAll(async () => {
      const res = await api.post('/employees', generateEmployee(50));
      tempId = res.data.id;
    });

    afterAll(async () => {
      await api.delete(`/employees/${tempId}`);
    });

    test('should update an existing employee', async () => {
      const updated = {
        name: 'Updated Name',
        email: 'updated@test.com',
        position: 'Lead',
      };
      const res = await api.put(`/employees/${tempId}`, updated);
      expect(res.status).toBe(200);
      expect(res.data.name).toBe(updated.name);
    });

    test('should return 404 for non-existent ID', async () => {
      const res = await api.put('/employees/999999', {
        name: 'Ghost',
        email: 'ghost@test.com',
        position: 'None',
      });
      expect(res.status).toBe(404);
    });

    test('should reject update with missing fields', async () => {
      const res = await api.put(`/employees/${tempId}`, { name: 'Only Name' });
      expect(res.status).toBe(400);
    });
  });

  // ---- DELETE ----
  describe('DELETE /employees/:id', () => {
    test('should delete an existing employee', async () => {
      const emp = generateEmployee(77);
      const createRes = await api.post('/employees', emp);
      
      const delRes = await api.delete(`/employees/${createRes.data.id}`);
      expect(delRes.status).toBe(200);
      expect(delRes.data.success).toBe(true);
      
      // Verify gone
      const listRes = await api.get('/employees');
      const found = listRes.data.find(e => e.id === createRes.data.id);
      expect(found).toBeUndefined();
    });

    test('should return 404 for non-existent ID', async () => {
      const res = await api.delete('/employees/999999');
      expect(res.status).toBe(404);
    });
  });
});
```

### tests/api/edge-cases.test.js
```javascript
const { api } = require('../helpers/api-client');

describe('Edge Cases & Security', () => {
  
  test('should handle very long strings gracefully', async () => {
    const longString = 'A'.repeat(10000);
    const res = await api.post('/employees', {
      name: longString,
      email: longString + '@test.com',
      position: longString,
    });
    // Should either accept or reject gracefully (not crash)
    expect([200, 400, 413]).toContain(res.status);
  });

  test('should handle special characters in fields', async () => {
    const res = await api.post('/employees', {
      name: "O'Brien <script>alert('xss')</script>",
      email: 'obrien+test@example.com',
      position: 'Dev & Ops / "Lead"',
    });
    expect([200, 400]).toContain(res.status);
    if (res.status === 200) {
      // Cleanup
      await api.delete(`/employees/${res.data.id}`);
    }
  });

  test('should handle SQL injection attempt safely', async () => {
    const res = await api.post('/employees', {
      name: "'; DROP TABLE employees; --",
      email: 'hacker@evil.com',
      position: 'Hacker',
    });
    // App should not crash; table should still work
    const listRes = await api.get('/employees');
    expect(listRes.status).toBe(200);
    expect(Array.isArray(listRes.data)).toBe(true);
    
    if (res.status === 200) {
      await api.delete(`/employees/${res.data.id}`);
    }
  });

  test('should return proper CORS headers', async () => {
    const res = await api.get('/employees');
    const corsHeader = res.headers['access-control-allow-origin'];
    expect(corsHeader).toBeDefined();
  });

  test('should handle non-numeric employee ID gracefully', async () => {
    const res = await api.get('/employees/not-a-number');
    // Should not crash the server
    expect([400, 404, 500]).toContain(res.status);
  });
});
```

## Execution Commands

```bash
# Run all backend tests
npx jest --config jest.config.js

# Run specific test suite
npx jest tests/api/auth.test.js

# Run with coverage
npx jest --coverage

# Run in watch mode
npx jest --watch

# Generate JSON report
npx jest --json --outputFile=reports/backend-results.json
```

## Best Practices for This App

1. **Isolate test data** — Use `generateEmployee()` with timestamps to avoid collisions
2. **Cleanup after tests** — Delete created employees in afterAll/afterEach hooks
3. **Don't throw on HTTP errors** — Use `validateStatus: () => true` to test error responses
4. **Test both happy and sad paths** — Every endpoint needs positive AND negative tests
5. **Verify side effects** — After POST, verify with GET. After DELETE, verify absent from GET.
6. **Parameterize credentials** — Use `test.each` for multiple valid/invalid credential combos
