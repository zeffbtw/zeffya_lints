import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/source/line_info.dart';

import '../../base/lint_rule.dart';
import '../../linter.dart';

/// Rule: Control flow statements should be separated by empty lines
class ControlFlowSpacingRule extends LintRule {
  @override
  String get code => 'control_flow_spacing';

  @override
  String get message =>
      'Control flow statements should be separated by an empty line';

  @override
  String get correction =>
      'Add an empty line before and after control flow statements';

  @override
  bool get hasFix => true;

  @override
  AstVisitor<void> createVisitor({
    required ErrorCallback onError,
    required String content,
    required LineInfo lineInfo,
  }) {
    return _ControlFlowSpacingVisitor(
      onError: onError,
      content: content,
    );
  }

  @override
  List<LintFix> getFixes({
    required CompilationUnit unit,
    required String content,
    required String path,
    required int offset,
  }) {
    final fixes = <LintFix>[];
    final visitor = _FixVisitor(offset: offset);
    unit.accept(visitor);

    if (visitor.targetStatement != null) {
      final statement = visitor.targetStatement!;
      final edits = <SourceEditData>[];

      // Add newline before if needed
      if (visitor.needsNewlineBefore) {
        edits.add(SourceEditData(
          offset: statement.offset,
          length: 0,
          replacement: '\n',
        ));
      }

      // Add newline after if needed
      if (visitor.needsNewlineAfter) {
        edits.add(SourceEditData(
          offset: statement.end,
          length: 0,
          replacement: '\n',
        ));
      }

      if (edits.isNotEmpty) {
        fixes.add(LintFix(
          code: code,
          message: message,
          description: 'Add empty line before and after control flow statement',
          path: path,
          offset: statement.offset,
          length: statement.length,
          priority: 8,
          edits: edits,
        ));
      }
    }

    return fixes;
  }
}

class _ControlFlowSpacingVisitor extends RecursiveAstVisitor<void> {
  final ErrorCallback onError;
  final String content;

  _ControlFlowSpacingVisitor({
    required this.onError,
    required this.content,
  });

  @override
  void visitIfStatement(IfStatement node) {
    _checkStatement(node);
    super.visitIfStatement(node);
  }

  @override
  void visitForStatement(ForStatement node) {
    _checkStatement(node);
    super.visitForStatement(node);
  }

  @override
  void visitWhileStatement(WhileStatement node) {
    _checkStatement(node);
    super.visitWhileStatement(node);
  }

  @override
  void visitDoStatement(DoStatement node) {
    _checkStatement(node);
    super.visitDoStatement(node);
  }

  @override
  void visitSwitchStatement(SwitchStatement node) {
    _checkStatement(node);
    super.visitSwitchStatement(node);
  }

  void _checkStatement(Statement statement) {
    final parentBlock = statement.parent;
    if (parentBlock is! Block) return;

    final statements = parentBlock.statements;
    final index = statements.indexOf(statement);

    // Check before
    if (index > 0) {
      final previousStatement = statements[index - 1];
      final textBetween =
          content.substring(previousStatement.end, statement.offset);

      if (!textBetween.contains('\n\n')) {
        onError(
          statement.offset,
          statement.length,
          null,
          'Before the control flow statement should be an empty line',
        );
      }
    }

    // Check after
    if (index < statements.length - 1) {
      final nextStatement = statements[index + 1];
      final textBetween =
          content.substring(statement.end, nextStatement.offset);

      if (!textBetween.contains('\n\n')) {
        onError(
          statement.offset,
          statement.length,
          null,
          'After the control flow statement should be an empty line',
        );
      }
    }
  }
}

class _FixVisitor extends RecursiveAstVisitor<void> {
  final int offset;
  Statement? targetStatement;
  bool needsNewlineBefore = false;
  bool needsNewlineAfter = false;

  _FixVisitor({required this.offset});

  @override
  void visitIfStatement(IfStatement node) {
    _checkForFix(node);
    super.visitIfStatement(node);
  }

  @override
  void visitForStatement(ForStatement node) {
    _checkForFix(node);
    super.visitForStatement(node);
  }

  @override
  void visitWhileStatement(WhileStatement node) {
    _checkForFix(node);
    super.visitWhileStatement(node);
  }

  @override
  void visitDoStatement(DoStatement node) {
    _checkForFix(node);
    super.visitDoStatement(node);
  }

  @override
  void visitSwitchStatement(SwitchStatement node) {
    _checkForFix(node);
    super.visitSwitchStatement(node);
  }

  void _checkForFix(Statement statement) {
    if (statement.offset != offset) return;
    targetStatement = statement;

    // We'll add newlines on both sides for simplicity
    needsNewlineBefore = true;
    needsNewlineAfter = true;
  }
}
