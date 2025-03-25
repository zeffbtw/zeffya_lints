import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

class ControlFlowSpacingQuickFix extends DartFix {
  @override
  void run(
    CustomLintResolver resolver,
    ChangeReporter reporter,
    CustomLintContext context,
    AnalysisError analysisError,
    List<AnalysisError> others,
  ) {
    context.registry.addStatement(
      (statement) {
        if (statement is IfStatement ||
            statement is ForStatement ||
            statement is WhileStatement ||
            statement is DoStatement ||
            statement is SwitchStatement) {
          if (statement.offset != analysisError.offset) {
            return;
          }

          final statementStart = statement.offset;
          final statementEnd = statement.end;

          final changeBuilder = reporter.createChangeBuilder(
            message: 'Add empty line before and after control flow statement',
            priority: 8,
          );

          changeBuilder.addDartFileEdit(
            (builder) {
              builder.addSimpleInsertion(statementStart, '\n');
              builder.addSimpleInsertion(statementEnd, '\n');
            },
          );
        }
      },
    );
  }
}
