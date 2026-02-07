import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/source/line_info.dart';

import '../../base/lint_rule.dart';
import '../../linter.dart';
import 'functions.dart';

/// Rule: Constructor parameters should be ordered correctly
class ConstructorParameterOrderRule extends LintRule {
  @override
  String get code => 'constructor_parameter_order';

  @override
  String get message => 'Constructor parameters should be ordered correctly';

  @override
  String get correction => 'Reorder constructor parameters';

  @override
  bool get hasFix => true;

  @override
  AstVisitor<void> createVisitor({
    required ErrorCallback onError,
    required String content,
    required LineInfo lineInfo,
  }) {
    return _ConstructorParameterOrderVisitor(
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
    final visitor = _FixVisitor(offset: offset, content: content);
    unit.accept(visitor);

    if (visitor.targetConstructor != null && visitor.sortedParamsText != null) {
      final params = visitor.targetConstructor!.parameters.parameters;
      if (params.isNotEmpty) {
        final start = params.first.offset;
        final end = params.last.end;

        fixes.add(LintFix(
          code: code,
          message: message,
          description: 'Sort constructor parameters',
          path: path,
          offset: start,
          length: end - start,
          priority: 9,
          edits: [
            SourceEditData(
              offset: start,
              length: end - start,
              replacement: visitor.sortedParamsText!,
            ),
          ],
        ));
      }
    }

    return fixes;
  }
}

class _ConstructorParameterOrderVisitor extends RecursiveAstVisitor<void> {
  final ErrorCallback onError;
  final String content;

  _ConstructorParameterOrderVisitor({
    required this.onError,
    required this.content,
  });

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    final parameters = node.parameters.parameters;
    if (parameters.isEmpty) return;

    final sortedOrder = List<FormalParameter>.from(parameters)
      ..sort((a, b) => ConstructorParameterOrderFunctions
              .computeConstructorParameterType(a)
          .index
          .compareTo(ConstructorParameterOrderFunctions
                  .computeConstructorParameterType(b)
              .index));

    bool orderCorrect = true;
    for (int i = 0; i < parameters.length; i++) {
      if (parameters[i] != sortedOrder[i]) {
        orderCorrect = false;
        break;
      }
    }

    if (!orderCorrect) {
      final start = parameters.first.offset;
      final end = parameters.last.end;

      onError(start, end - start, null, null);
    }

    super.visitConstructorDeclaration(node);
  }
}

class _FixVisitor extends RecursiveAstVisitor<void> {
  final int offset;
  final String content;
  ConstructorDeclaration? targetConstructor;
  String? sortedParamsText;

  _FixVisitor({required this.offset, required this.content});

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    final parameters = node.parameters.parameters;
    if (parameters.isEmpty) return;

    final start = parameters.first.offset;
    final end = parameters.last.end;

    // Check if this constructor contains the offset
    if (offset >= start && offset <= end) {
      targetConstructor = node;

      final sortedParams = List<FormalParameter>.from(parameters)
        ..sort((a, b) => ConstructorParameterOrderFunctions
                .computeConstructorParameterType(a)
            .index
            .compareTo(ConstructorParameterOrderFunctions
                    .computeConstructorParameterType(b)
                .index));

      sortedParamsText =
          sortedParams.map((p) => content.substring(p.offset, p.end)).join(',\n ');
    }

    super.visitConstructorDeclaration(node);
  }
}
