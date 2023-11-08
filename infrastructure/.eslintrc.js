module.exports = {
  "env": {
    "es2021": true,
    "node": true
  },
  "extends": [
    "eslint:recommended",
    "plugin:@typescript-eslint/recommended"
  ],
  "parser": "@typescript-eslint/parser",
  "parserOptions": {
    "ecmaVersion": "latest",
    "sourceType": "module"
  },
  "plugins": [
    "@typescript-eslint",
    "eslint-plugin-import",
    "eslint-plugin-node",
    "eslint-plugin-promise"
  ],
  "rules": {
    "array-bracket-spacing": [
      "error",
      "always"
    ],
    "import/newline-after-import": [
      "error",
      {
        "count": 1
      }
    ],
    "indent": [
      "error",
      2
    ],
    "linebreak-style": [
      "error",
      "unix"
    ],
    "object-curly-spacing": [
      "error",
      "always"
    ],
    "quotes": [
      "error",
      "double"
    ],
    "semi": [
      "error",
      "always"
    ]
  }
};