import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/source/line_info.dart';

import '../linter.dart';

/// Callback for reporting lint errors
typedef ErrorCallback = void Function(
  int offset,
  int length,
  String? message,
  String? correction,
);

/// Base class for all lint rules
abstract class LintRule {
  /// Unique code for this rule (e.g., 'class_member_order')
  String get code;

  /// Default message for this rule
  String get message;

  /// Optional correction message
  String? get correction => null;

  /// Whether this rule has quick fixes
  bool get hasFix => false;

  /// Create a visitor that will check this rule
  AstVisitor<void> createVisitor({
    required ErrorCallback onError,
    required String content,
    required LineInfo lineInfo,
  });

  /// Get fixes for errors at a specific offset (override if hasFix is true)
  List<LintFix> getFixes({
    required CompilationUnit unit,
    required String content,
    required String path,
    required int offset,
  }) {
    return [];
  }
}

/// Visitor that combines multiple rule visitors
class CompositeVisitor extends GeneralizingAstVisitor<void> {
  final List<AstVisitor<void>> _visitors;

  CompositeVisitor(this._visitors);

  @override
  void visitNode(AstNode node) {
    for (final visitor in _visitors) {
      node.accept(visitor);
    }
    super.visitNode(node);
  }
}
