import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

import 'functions.dart';

class ConstructorParameterOrderFix extends ResolvedCorrectionProducer {
  ConstructorParameterOrderFix({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;
  @override
  FixKind get fixKind => const FixKind(
    'dart.fix.constructorParameterOrder',
    DartFixKindPriority.standard,
    'Sort constructor parameters',
  );

  @override
  Future<void> compute(ChangeBuilder builder) async {
    AstNode? node = coveringNode;

    while (node != null && node is! ConstructorDeclaration) {
      node = node.parent;
    }

    if (node is! ConstructorDeclaration) return;

    final ctorNode = node;

    final parameters = ctorNode.parameters.parameters;

    if (parameters.isEmpty) return;

    final content = unitResult.content;
    final start = parameters.first.offset;
    final end = parameters.last.end;

    final sortedParams = List<FormalParameter>.from(parameters)
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

    final sortedText = sortedParams
        .map((p) => content.substring(p.offset, p.end))
        .join(',\n ');

    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleReplacement(SourceRange(start, end - start), sortedText);
    });
  }
}
