# Changelog

## [2.0.0] - 2026-02-14

**Breaking:** Migrated from `custom_lint_builder` to native `analysis_server_plugin` (Dart 3.10+).

- Requires Dart SDK `>=3.10.0 <4.0.0` / Flutter `>=3.38.0`
- Plugin is now configured via top-level `plugins:` section in `analysis_options.yaml`
- No `pubspec.yaml` dependency needed for IDE linting
- Added CLI fix tool: `dart run zeffya_lints:fix [path]`
- All rules include IDE quick fixes
- Rewritten README with quick start, code examples, and troubleshooting

### Rules

- `class_member_order` — enforces class member ordering by group
- `constructor_parameter_order` — enforces constructor parameter ordering
- `control_flow_spacing` — enforces blank lines around control-flow statements

## [1.1.0] - 2025-12-14

**Updated dependencies


## [1.0.0] - 2025-03-25

**🚀 zeffya_lints v1.0.0 — Initial Release**

---

Check out the [GitHub repository](https://github.com/zeffbtw/zeffya_lints) for more details and to contribute to the project!
