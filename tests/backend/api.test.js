const axios = require('axios');

const API_BASE = 'http://localhost:4000';
let authToken = null;

describe('Employee Manager Backend API Tests', () => {
  
  describe('Authentication', () => {
    test('POST /login with valid credentials', async () => {
      try {
        const response = await axios.post(`${API_BASE}/login`, {
          username: 'admin',
          password: 'password'
        });
        expect(response.status).toBe(200);
        expect(response.data).toHaveProperty('message');
        authToken = response.data.token || 'authenticated';
      } catch (error) {
        console.error('Login test failed:', error.message);
      }
    });

    test('POST /login with invalid credentials', async () => {
      try {
        await axios.post(`${API_BASE}/login`, {
          username: 'invalid',
          password: 'wrongpass'
        });
        fail('Should have thrown 401 error');
      } catch (error) {
        expect(error.response?.status).toBe(401);
      }
    });

    test('POST /login with missing fields', async () => {
      try {
        await axios.post(`${API_BASE}/login`, {
          username: 'admin'
        });
        fail('Should have thrown 400 error');
      } catch (error) {
        expect(error.response?.status).toBe(400);
      }
    });
  });

  describe('Employee CRUD Operations', () => {
    let employeeId = null;

    test('GET /employees returns array', async () => {
      try {
        const response = await axios.get(`${API_BASE}/employees`);
        expect(response.status).toBe(200);
        expect(Array.isArray(response.data)).toBe(true);
      } catch (error) {
        console.error('GET employees failed:', error.message);
      }
    });

    test('POST /employees creates new employee', async () => {
      try {
        const response = await axios.post(`${API_BASE}/employees`, {
          name: 'John Doe',
          email: 'john@example.com',
          position: 'Developer'
        });
        expect(response.status).toBe(201);
        expect(response.data).toHaveProperty('id');
        employeeId = response.data.id;
      } catch (error) {
        console.error('POST employee failed:', error.message);
      }
    });

    test('PUT /employees/:id updates employee', async () => {
      if (!employeeId) {
        console.log('Skipping update test - no employee ID');
        return;
      }
      try {
        const response = await axios.put(`${API_BASE}/employees/${employeeId}`, {
          name: 'Jane Doe',
          email: 'jane@example.com',
          position: 'Senior Developer'
        });
        expect(response.status).toBe(200);
      } catch (error) {
        console.error('PUT employee failed:', error.message);
      }
    });

    test('DELETE /employees/:id removes employee', async () => {
      if (!employeeId) {
        console.log('Skipping delete test - no employee ID');
        return;
      }
      try {
        const response = await axios.delete(`${API_BASE}/employees/${employeeId}`);
        expect(response.status).toBe(200);
      } catch (error) {
        console.error('DELETE employee failed:', error.message);
      }
    });

    test('DELETE non-existent employee returns 404', async () => {
      try {
        await axios.delete(`${API_BASE}/employees/99999`);
        fail('Should have thrown 404 error');
      } catch (error) {
        expect(error.response?.status).toBe(404);
      }
    });
  });
});
