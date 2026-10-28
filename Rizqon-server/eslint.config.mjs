
import eslint from "@eslint/js";
import tseslint from "typescript-eslint";
import globals from "globals";

export default tseslint.config(
  {
    ignores: [
      ".agents/**",
      ".claude/**",
      ".cursor/**",
      ".devin/**",
      "node_modules/**",
      "dist/**",
      "build/**",
      "coverage/**",
      ".prisma/**",
      "generated/**",
      "**/generated/**"
    ]
  },

  eslint.configs.recommended,
  ...tseslint.configs.recommended,

  {
    files: ["**/*.{js,mjs,cjs,ts,mts,cts}"],

    languageOptions: {
      globals: {
        ...globals.node
      },
      ecmaVersion: "latest",
      sourceType: "module"
    },

    rules: {
      "no-console": "off",
      "no-debugger": "warn",
      "prefer-const": "error",

      "@typescript-eslint/no-unused-vars": [
        "warn",
        {
          argsIgnorePattern: "^_",
          varsIgnorePattern: "^_"
        }
      ],

      "@typescript-eslint/no-explicit-any": "warn",
      "@typescript-eslint/no-require-imports": "off"
    }
  }
);
