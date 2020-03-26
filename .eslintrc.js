module.exports = {
  'parser': 'babel-eslint',
  'extends': 'airbnb-base',
  'rules': {
    'semi': ['error', 'always'],
    'quotes': ['error', 'single'],
    'no-unused-vars': ['error', { 'vars': 'all', 'args': 'none' }],
    'no-trailing-spaces': ['error'],
    'no-multiple-empty-lines': ['error', { 'max': 2 }],
    'prefer-const': ['error'],
    'getter-return': ['error'],
    'curly': ['error', 'multi-line'],
    'max-len': ['error', { 'code': 120 }],
    'no-underscore-dangle': 'off'
  },
  'env': {
    'browser': true,
    'node': true,
    'es6': true,
    'jquery': true
  }
};
