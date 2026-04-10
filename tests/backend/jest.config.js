module.exports = {
  testEnvironment: 'node',
  testTimeout: 10000,
  collectCoverageFrom: ['src/**/*.js'],
  coverageReporters: ['json', 'text', 'lcov'],
  testMatch: ['**/__tests__/**/*.js', '**/?(*.)+(spec|test).js']
};
