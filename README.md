# zeffya_lints

[![pub package](https://img.shields.io/pub/v/zeffya_lints.svg)](https://pub.dev/packages/zeffya_lints)
[![GitHub license](https://img.shields.io/github/license/zeffbtw/zeffya_lints)](https://github.com/zeffbtw/zeffya_lints/blob/main/LICENSE)
[![GitHub stars](https://img.shields.io/github/stars/zeffbtw/zeffya_lints)](https://github.com/zeffbtw/zeffya_lints/stargazers)

A custom set of linter rules to enforce consistent and clean Dart/Flutter code style. Built on the native Dart 3.10+ `analysis_server_plugin` system with full IDE integration.

---

## Features

### `class_member_order`

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

Includes quick fix to auto-reorder members.

### `constructor_parameter_order`

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

Includes quick fix to auto-sort parameters.

### `control_flow_spacing`

Enforces empty lines before and after control-flow statements (`if`, `for`, `while`, `do`, `switch`).

Includes quick fix to auto-add spacing.

---

## Requirements

- Dart SDK `>=3.10.0 <4.0.0`
- Flutter `>=3.38.0`

## Installation

Add the package to your `dependencies`:

```yaml
dependencies:
  zeffya_lints: ^2.0.0
```

Then enable the plugin in your `analysis_options.yaml`:

```yaml
plugins:
  zeffya_lints:
    diagnostics:
      class_member_order: true
      constructor_parameter_order: true
      control_flow_spacing: true

analyzer:
  exclude:
    - "**/*.g.dart"
    - "**/*.freezed.dart"
    - "**/*.gr.dart"
    - "lib/generated/**"
    - "lib/firebase_options.dart"
```

Restart the Dart/Flutter analysis server after making changes.

## CLI Fix Tool

Apply all fixes automatically from the command line:

```bash
dart run zeffya_lints:fix [path]
```

This will analyze, apply fixes, and run `dart format` on modified files.

---

## License

This project is licensed under the BSD 3-Clause License – see the [LICENSE](https://github.com/zeffbtw/zeffya_lints/blob/main/LICENSE) file for details.

---

Made with ❤️ by [zeffbtw](https://github.com/zeffbtw).
