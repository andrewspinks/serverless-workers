import eslint from "@eslint/js";
import globals from "globals";
import tseslint from "typescript-eslint";

export default tseslint.config(
  {
    ignores: [
      "dist/**",
      "node_modules/**",
      "terraform/**/.terraform/**",
      "terraform/**/*.tfstate*",
    ],
  },
  eslint.configs.recommended,
  ...tseslint.configs.recommendedTypeChecked.map((config) => ({
    ...config,
    files: ["src/**/*.ts"],
  })),
  {
    files: ["src/**/*.ts"],
    languageOptions: {
      parserOptions: {
        projectService: true,
        tsconfigRootDir: import.meta.dirname,
      },
    },
  },
  {
    files: ["src/activities.ts"],
    rules: {
      "@typescript-eslint/require-await": "off",
    },
  },
  {
    files: ["**/*.mjs"],
    languageOptions: {
      globals: globals.node,
    },
  },
);
