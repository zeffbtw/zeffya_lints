import 'package:analyzer/dart/analysis/results.dart';

import 'base/lint_rule.dart';
import 'rules/class_member_order/rule.dart';
import 'rules/constructor_parameter_order/rule.dart';
import 'rules/control_flow_spacing/rule.dart';

/// Data class for lint errors
class LintError {
  final String code;
  final String message;
  final String? correction;
  final int offset;
  final int length;
  final int line;
  final int column;
  final int endLine;
  final int endColumn;
  final bool hasFix;

  const LintError({
    required this.code,
    required this.message,
    this.correction,
    required this.offset,
    required this.length,
    required this.line,
    required this.column,
    required this.endLine,
    required this.endColumn,
    this.hasFix = false,
  });
}

/// Data class for source edits
class SourceEditData {
  final int offset;
  final int length;
  final String replacement;

  const SourceEditData({
    required this.offset,
    required this.length,
    required this.replacement,
  });
}

/// Data class for lint fixes
class LintFix {
  final String code;
  final String message;
  final String description;
  final String path;
  final int offset;
  final int length;
  final int priority;
  final List<SourceEditData> edits;

  const LintFix({
    required this.code,
    required this.message,
    required this.description,
    required this.path,
    required this.offset,
    required this.length,
    required this.priority,
    required this.edits,
  });
}

/// Main linter that runs all rules
class ZeffyaLinter {
  final List<LintRule> _rules = [
    ClassMemberOrderRule(),
    ConstructorParameterOrderRule(),
    ControlFlowSpacingRule(),
  ];

  /// Analyze a resolved unit and return all lint errors
  List<LintError> analyze(ResolvedUnitResult result) {
    final errors = <LintError>[];
    final unit = result.unit;
    final content = result.content;
    final lineInfo = result.lineInfo;

    for (final rule in _rules) {
      final visitor = rule.createVisitor(
        onError: (offset, length, message, correction) {
          final start = lineInfo.getLocation(offset);
          final end = lineInfo.getLocation(offset + length);

          errors.add(LintError(
            code: rule.code,
            message: message ?? rule.message,
            correction: correction ?? rule.correction,
            offset: offset,
            length: length,
            line: start.lineNumber,
            column: start.columnNumber,
            endLine: end.lineNumber,
            endColumn: end.columnNumber,
            hasFix: rule.hasFix,
          ));
        },
        content: content,
        lineInfo: lineInfo,
      );

      unit.accept(visitor);
    }

    return errors;
  }

  /// Get fixes for errors at a specific offset
  List<LintFix> getFixes(ResolvedUnitResult result, int offset) {
    final fixes = <LintFix>[];
    final unit = result.unit;
    final content = result.content;
    final path = result.path;

    for (final rule in _rules) {
      if (!rule.hasFix) continue;

      final ruleFixes = rule.getFixes(
        unit: unit,
        content: content,
        path: path,
        offset: offset,
      );

      fixes.addAll(ruleFixes);
    }

    return fixes;
  }
}
