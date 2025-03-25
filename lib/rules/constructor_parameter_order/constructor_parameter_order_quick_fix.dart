import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/source/source_range.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:zeffya_lints/rules/constructor_parameter_order/constructor_parameter_order_functions.dart';

class ConstructorParameterOrderQuickFix extends DartFix {
  @override
  void run(
    CustomLintResolver resolver,
    ChangeReporter reporter,
    CustomLintContext context,
    AnalysisError analysisError,
    List<AnalysisError> others,
  ) {
    context.registry.addConstructorDeclaration((constructor) {
      if (!analysisError.sourceRange.intersects(constructor.sourceRange))
        return;

      final parameters = constructor.parameters.parameters;
      if (parameters.isEmpty) return;

      final source = resolver.source;
      String getParameterText(FormalParameter param) {
        final fileContent = source.contents.data;
        return fileContent.substring(param.offset, param.end);
      }

      final sortedParams = List<FormalParameter>.from(parameters)
        ..sort(
          (a, b) => ConstructorParameterOrderFunctions
                  .computeConstructorParameterType(a)
              .index
              .compareTo(ConstructorParameterOrderFunctions
                      .computeConstructorParameterType(b)
                  .index),
        );

      final newParamsText = sortedParams.map(getParameterText).join(',\n ');

      final start = parameters.first.offset;
      final end = parameters.last.end;
      final length = end - start;

      final changeBuilder = reporter.createChangeBuilder(
        message: 'Sort constructor parameters',
        priority: 9,
      );
      changeBuilder.addDartFileEdit((builder) {
        builder.addSimpleReplacement(
          SourceRange(start, length),
          newParamsText,
        );
        builder.format(SourceRange(start, length));
      });
    });
  }
}
