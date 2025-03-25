import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:zeffya_lints/rules/control_flow_spacing/control_flow_spacing_quick_fix.dart';

class ControlFlowSpacingRule extends DartLintRule {
  const ControlFlowSpacingRule() : super(code: _code);

  static const LintCode _code = LintCode(
    name: 'control_flow_spacing',
    problemMessage: 'Control flow statements should be separated by an empty line',
  );

  @override
  List<Fix> getFixes() => [ControlFlowSpacingQuickFix()];

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addStatement((statement) {
      if (statement is IfStatement ||
          statement is ForStatement ||
          statement is WhileStatement ||
          statement is DoStatement ||
          statement is SwitchStatement) {
        final parentBlock = statement.parent;
        if (parentBlock is! Block) return;

        final source = resolver.source;
        final fileContent = source.contents.data;
        final statementStart = statement.offset;
        final statementEnd = statement.end;

        final parentStatements = parentBlock.statements;
        final statementIndex = parentStatements.indexOf(statement);

        if (statementIndex > 0) {
          final previousStatement = parentStatements[statementIndex - 1];
          final previousEnd = previousStatement.end;
          final textBetween = fileContent.substring(previousEnd, statementStart);

          if (textBetween.contains('\n\n') == false) {
            final error = AnalysisError.forValues(
              source: source,
              offset: statementStart,
              length: statement.length,
              errorCode: _code,
              message: _code.problemMessage,
              correctionMessage: 'Before the control flow statement should be an empty line',
            );

            reporter.reportError(error);
          }
        }

        if (statementIndex < parentStatements.length - 1) {
          final nextStatement = parentStatements[statementIndex + 1];
          final nextStart = nextStatement.offset;
          final textBetween = fileContent.substring(statementEnd, nextStart);

          if (textBetween.contains('\n\n') == false) {
            final error = AnalysisError.forValues(
              source: source,
              offset: statementStart,
              length: statement.length,
              errorCode: _code,
              message: _code.problemMessage,
              correctionMessage: 'After the control flow statement should be an empty line',
            );
            reporter.reportError(error);
          }
        }
      }
    });
  }
}
