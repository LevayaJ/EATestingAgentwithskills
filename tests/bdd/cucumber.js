module.exports = {
  default: {
    require: ['step-definitions/**/*.js'],
    format: ['progress', 'html:cucumber-report.html'],
    formatOptions: { snippetInterface: 'async-await' }
  }
};
