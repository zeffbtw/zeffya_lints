# zeffya_lints

[![pub package](https://img.shields.io/pub/v/zeffya_lints.svg)](https://pub.dev/packages/zeffya_lints)
[![GitHub license](https://img.shields.io/github/license/zeffbtw/zeffya_lints)](https://github.com/zeffbtw/zeffya_lints/blob/main/LICENSE)
[![GitHub stars](https://img.shields.io/github/stars/zeffbtw/zeffya_lints)](https://github.com/zeffbtw/zeffya_lints/stargazers)

A custom set of linter rules to enforce consistent and clean Dart/Flutter code style.

---

## 🌟 Features

### ✅ `ClassMemberOrderRule`

Enforces specific ordering and spacing between different groups of class members:

- `constructorField`
- `constructor`
- `staticConst`
- `staticFinal`
- `static`
- `constant`
- `lateFinal`
- `finalVar`
- `lateVar`
- `variable`
- `optional`
- `setter`
- `getter`
- `overrideMethod`
- `staticMethod`
- `method`
- `privateMethod`
- `widgetOverrideBuildMethod`
- `widgetBuildMethod`
- `none`

### ✅ `ConstructorParameterOrderRule`

Ensures constructor parameters follow the desired order:

- `superField`
- `requiredThisField`
- `requiredVariable`
- `thisField`
- `thisFieldNullable`
- `variableNullable`
- `thisFieldWithValue`
- `thisFieldNullableWithValue`
- `variableWithValue`
- `none`

### ✅ `ControlFlowSpacingRule`

Enforces spacing rules around control-flow statements such as `if`, `for`, `while`, etc.

---

## 📦 Installation

Add the package to your `dev_dependencies`:

```yaml
dev_dependencies:
  zeffya_lints:
  custom_lint:
```

Then, in your `analysis_options.yaml`, enable the plugin and optionally exclude generated files:

```yaml
analyzer:
  plugins:
    - custom_lint

  exclude:
    - "**/*.g.dart"
    - "**/*.freezed.dart"
    - "**/*.gr.dart"
    - "lib/generated/**"
    - "lib/firebase_options.dart"
```

Restart the Dart/Flutter analysis server after making changes to apply the new rules.

---

## 📝 License

This project is licensed under the BSD 3-Clause License – see the [LICENSE](https://github.com/zeffbtw/circlify/blob/main/LICENSE) file for details.

---

Made with ❤️ by [zeffbtw](https://github.com/zeffbtw).
