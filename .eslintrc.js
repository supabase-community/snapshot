const baseConfig = {
  ignorePatterns: [
    'node_modules/*',
    'node_modules/**/*.d.ts',
    '**/__fixtures__/**/*.ts',
    '**/cloudSnapshots/**/*.ts',
  ],
  extends: '@redwoodjs/eslint-config',
  plugins: ['import'],
  rules: {
    'import/extensions': [
      'warn',
      'always',
      {
        ignorePackages: true,
      },
    ],
    'no-console': [
      'error',
      {
        allow: ['log', 'time', 'timeEnd'],
      },
    ],
    'prettier/prettier': 'warn',
    'react/react-in-jsx-scope': 'off',
    'react/no-unescaped-entities': 'off',
    '@typescript-eslint/explicit-module-boundary-types': 'off',
    '@typescript-eslint/ban-ts-comment': 'off',
    '@typescript-eslint/no-non-null-assertion': 'off',
    '@typescript-eslint/no-explicit-any': 'off',
    '@typescript-eslint/no-unused-vars': 'warn',
    '@typescript-eslint/no-restricted-imports': [
      'error',
      {
        paths: [
          {
            name: 'api',
            message:
              'Only type imports are allowed for the api to avoid bundling api code in the cli',
            allowTypeImports: true,
          },
        ],
      },
    ],
    'no-unused-vars': 'off',
    'no-new': 'off',
    'react-hooks/exhaustive-deps': 'off',
    'react/prop-types': 'off',
  },
  overrides: [
    {
      files: ['infrastructure/**/*', 'web/**/*', 'extension/src/webview/**/*'],
      rules: {
        'import/extensions': 'off',
      },
    },
  ],
}

const typescriptAdvancedConfig = {
  ...baseConfig,
  parser: '@typescript-eslint/parser',
  parserOptions: {
    project: [
      './cli/tsconfig.json',
      './packages/cli/tsconfig.json',
      './packages/sdk/tsconfig.json',
    ],
  },
  rules: {
    ...baseConfig.rules,
    '@typescript-eslint/no-floating-promises': 'error',
  },
}

module.exports = typescriptAdvancedConfig
