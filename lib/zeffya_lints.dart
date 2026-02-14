/// Custom lint rules for Dart/Flutter projects.
///
/// This package provides the following lint rules:
/// - `class_member_order`: Ensures class members are ordered correctly
/// - `constructor_parameter_order`: Ensures constructor parameters are ordered
/// - `control_flow_spacing`: Ensures control flow statements have proper spacing
library zeffya_lints;

export 'main.dart' show ZeffyaLintsPlugin;
export 'src/linter.dart' show ZeffyaLinter, LintError, LintFix, SourceEditData;
