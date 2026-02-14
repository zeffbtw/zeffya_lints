# zeffya_lints

[![pub package](https://img.shields.io/pub/v/zeffya_lints.svg)](https://pub.dev/packages/zeffya_lints)
[![GitHub license](https://img.shields.io/github/license/zeffbtw/zeffya_lints)](https://github.com/zeffbtw/zeffya_lints/blob/main/LICENSE)
[![GitHub stars](https://img.shields.io/github/stars/zeffbtw/zeffya_lints)](https://github.com/zeffbtw/zeffya_lints/stargazers)

Custom linter rules for Dart/Flutter that enforce consistent code style. Built on the native Dart 3.10+ analyzer plugin system with IDE integration and auto-fixes.

## Quick Start

Add to your `analysis_options.yaml`:

```yaml
plugins:
  zeffya_lints: ^2.0.0
```

Restart the analysis server (VS Code: `Cmd+Shift+P` > `Dart: Restart Analysis Server`). Done.

> No changes to `pubspec.yaml` needed. The analysis server resolves plugin packages independently.

## Rules

All rules are **enabled by default** and include quick fixes.

### `class_member_order`

Enforces ordering of class members by group with blank line separators:

```dart
// Bad
class MyWidget extends StatelessWidget {
  final String title;
  MyWidget({required this.title});
  static const defaultTitle = 'Hello';

  @override
  Widget build(BuildContext context) => Text(title);
}

// Good
class MyWidget extends StatelessWidget {
  MyWidget({required this.title});

  static const defaultTitle = 'Hello';

  final String title;

  @override
  Widget build(BuildContext context) => Text(title);
}
```

<details>
<summary>Member group order</summary>

1. `constructorField`
2. `constructor`
3. `staticConst`
4. `staticFinal`
5. `static`
6. `constant`
7. `lateFinal`
8. `finalVar`
9. `lateVar`
10. `variable`
11. `optional`
12. `setter`
13. `getter`
14. `overrideMethod`
15. `staticMethod`
16. `method`
17. `privateMethod`
18. `widgetOverrideBuildMethod`
19. `widgetBuildMethod`

</details>

### `constructor_parameter_order`

Enforces parameter ordering in constructors:

```dart
// Bad
MyWidget({this.title, required this.id, super.key});

// Good
MyWidget({super.key, required this.id, this.title});
```

<details>
<summary>Parameter group order</summary>

1. `superField`
2. `requiredThisField`
3. `requiredVariable`
4. `thisField`
5. `thisFieldNullable`
6. `variableNullable`
7. `thisFieldWithValue`
8. `thisFieldNullableWithValue`
9. `variableWithValue`

</details>

### `control_flow_spacing`

Enforces blank lines before and after control-flow statements:

```dart
// Bad
final x = 1;
if (x > 0) {
  print(x);
}
return x;

// Good
final x = 1;

if (x > 0) {
  print(x);
}

return x;
```

## Configuration

All rules are warnings and enabled by default. To disable a specific rule:

```yaml
plugins:
  zeffya_lints:
    diagnostics:
      control_flow_spacing: false
```

### Exclude generated files

```yaml
plugins:
  zeffya_lints: ^2.0.0

analyzer:
  exclude:
    - "**/*.g.dart"
    - "**/*.freezed.dart"
    - "**/*.gr.dart"
    - "lib/generated/**"
```

### Suppress in code

```dart
// Single line
// ignore: zeffya_lints/class_member_order
final x = 1;

// Entire file
// ignore_for_file: zeffya_lints/control_flow_spacing
```

## CLI Fix Tool

Apply all fixes from the command line. Requires adding the package to `pubspec.yaml`:

```yaml
dev_dependencies:
  zeffya_lints: ^2.0.0
```

```bash
dart run zeffya_lints:fix [path]
```

Analyzes the project, applies auto-fixes, and runs `dart format` on modified files.

## Troubleshooting

**Rules not showing up in IDE**
1. Check that `plugins:` is a **top-level** key in `analysis_options.yaml` (not nested under `analyzer:`)
2. Restart the analysis server: VS Code `Cmd+Shift+P` > `Dart: Restart Analysis Server`
3. Check Dart version: `dart --version` (requires `>=3.10.0`)

**`plugins:` section not recognized**
- Update to Dart SDK `>=3.10.0` / Flutter `>=3.38.0`
- The `plugins:` key is part of the new native plugin system introduced in Dart 3.10

**CLI tool: `Could not find package "zeffya_lints"`**
- The CLI tool requires the package in `dev_dependencies`. Add it and run `dart pub get`
- Note: IDE linting does NOT require a pubspec dependency

## Requirements

- Dart SDK `>=3.10.0 <4.0.0`
- Flutter `>=3.38.0`

## License

BSD 3-Clause License. See [LICENSE](https://github.com/zeffbtw/zeffya_lints/blob/main/LICENSE).
