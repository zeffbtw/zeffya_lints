import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import 'functions.dart';

class ConstructorParameterOrderRule extends AnalysisRule {
  ConstructorParameterOrderRule()
    : super(
        name: 'constructor_parameter_order',
        description: 'Constructor parameters should be ordered correctly',
      );

  static const code = LintCode(
    'constructor_parameter_order',
    'Constructor parameters should be ordered correctly.',
    correctionMessage: 'Reorder constructor parameters',
  );

  @override
  DiagnosticCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _ConstructorParameterOrderVisitor(this);
    registry.addConstructorDeclaration(this, visitor);
  }
}

class _ConstructorParameterOrderVisitor extends SimpleAstVisitor<void> {
  final ConstructorParameterOrderRule rule;

  _ConstructorParameterOrderVisitor(this.rule);

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    final parameters = node.parameters.parameters;

    if (parameters.isEmpty) return;

    final sortedOrder = List<FormalParameter>.from(parameters)
      ..sort(
        (a, b) =>
            ConstructorParameterOrderFunctions.computeConstructorParameterType(
              a,
            ).index.compareTo(
              ConstructorParameterOrderFunctions.computeConstructorParameterType(
                b,
              ).index,
            ),
      );

    for (int i = 0; i < parameters.length; i++) {
      if (parameters[i] != sortedOrder[i]) {
        final start = parameters.first.offset;
        final end = parameters.last.end;
        rule.reportAtOffset(start, end - start);
        break;
      }
    }
  }
}
