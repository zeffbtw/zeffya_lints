import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../../utils.dart';

class ControlFlowSpacingRule extends AnalysisRule {
  ControlFlowSpacingRule()
    : super(
        name: 'control_flow_spacing',
        description:
            'Control flow statements should be separated by empty lines',
      );

  static const code = LintCode(
    'control_flow_spacing',
    'Control flow statements should be separated by an empty line.',
    correctionMessage:
        'Add an empty line before and after control flow statements',
  );

  @override
  DiagnosticCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _ControlFlowSpacingVisitor(this, context);
    registry.addIfStatement(this, visitor);
    registry.addForStatement(this, visitor);
    registry.addWhileStatement(this, visitor);
    registry.addDoStatement(this, visitor);
    registry.addSwitchStatement(this, visitor);
  }
}

class _ControlFlowSpacingVisitor extends SimpleAstVisitor<void> {
  final ControlFlowSpacingRule rule;
  final RuleContext context;

  _ControlFlowSpacingVisitor(this.rule, this.context);

  @override
  void visitIfStatement(IfStatement node) => _checkStatement(node);

  @override
  void visitForStatement(ForStatement node) => _checkStatement(node);

  @override
  void visitWhileStatement(WhileStatement node) => _checkStatement(node);

  @override
  void visitDoStatement(DoStatement node) => _checkStatement(node);

  @override
  void visitSwitchStatement(SwitchStatement node) => _checkStatement(node);

  void _checkStatement(Statement statement) {
    final parentBlock = statement.parent;

    if (parentBlock is! Block) return;

    final content = context.currentUnit!.content;
    final statements = parentBlock.statements;
    final index = statements.indexOf(statement);

    if (index > 0) {
      final previousStatement = statements[index - 1];
      final textBetween = content.substring(
        previousStatement.end,
        statement.offset,
      );

      if (!blankLineRegex.hasMatch(textBetween)) {
        rule.reportAtNode(statement);
        return;
      }
    }

    if (index < statements.length - 1) {
      final nextStatement = statements[index + 1];
      final textBetween = content.substring(
        statement.end,
        nextStatement.offset,
      );

      if (!blankLineRegex.hasMatch(textBetween)) {
        rule.reportAtNode(statement);
      }
    }
  }
}
