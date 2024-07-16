// https://prettier.io/docs/en/options.html
module.exports = {
  trailingComma: 'es5',
  bracketSpacing: true,
  tabWidth: 2,
  semi: false,
  singleQuote: true,
  arrowParens: 'always',
  importOrder: ['^~api/(.*)$', '^src/(.*)$', '^~/(.*)$', '^[./]'],
  importOrderSeparation: true,
  overrides: [
    {
      files: 'Routes.*',
      options: {
        printWidth: 999,
      },
    },
  ],
}
