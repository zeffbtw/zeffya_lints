import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:zeffya_lints/rules/constructor_parameter_order/constructor_parameter_order_functions.dart';
import 'package:zeffya_lints/rules/constructor_parameter_order/constructor_parameter_order_quick_fix.dart';

class ConstructorParameterOrderRule extends DartLintRule {
  const ConstructorParameterOrderRule() : super(code: _code);

  static const LintCode _code = LintCode(
    name: 'constructor_parameter_order',
    problemMessage: 'Constructor parameters should be ordered correctly',
  );

  @override
  List<Fix> getFixes() => [ConstructorParameterOrderQuickFix()];

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addConstructorDeclaration((constructor) {
      final parameters = constructor.parameters.parameters;
      if (parameters.isEmpty) return;

      parameters
          .map(ConstructorParameterOrderFunctions
              .computeConstructorParameterType)
          .toList();

      final sortedOrder = List<FormalParameter>.from(parameters)
        ..sort((a, b) =>
            ConstructorParameterOrderFunctions.computeConstructorParameterType(
                    a)
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
        final source = resolver.source;
        final start = parameters.first.offset;
        final end = parameters.last.end;
        final length = end - start + 1;

        final error = AnalysisError.forValues(
          source: source,
          offset: start,
          length: length,
          errorCode: _code,
          message: _code.problemMessage,
          correctionMessage: 'Correct constructor parameter order',
        );
        reporter.reportError(error);
      }
    });
  }
}
