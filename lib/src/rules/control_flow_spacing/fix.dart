import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

import '../../utils.dart';

class ControlFlowSpacingFix extends ResolvedCorrectionProducer {
  ControlFlowSpacingFix({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;
  @override
  FixKind get fixKind => const FixKind(
    'dart.fix.controlFlowSpacing',
    DartFixKindPriority.standard,
    'Add empty lines around control flow statement',
  );

  @override
  Future<void> compute(ChangeBuilder builder) async {
    AstNode? node = coveringNode;

    while (node != null && node is! Statement) {
      node = node.parent;
    }

    if (node is! Statement) return;

    final statement = node;

    final parentBlock = statement.parent;

    if (parentBlock is! Block) return;

    final statements = parentBlock.statements;
    final index = statements.indexOf(statement);
    final content = unitResult.content;

    await builder.addDartFileEdit(file, (builder) {
      // Add newline before if needed
      if (index > 0) {
        final previousStatement = statements[index - 1];
        final textBetween = content.substring(
          previousStatement.end,
          statement.offset,
        );

        if (!blankLineRegex.hasMatch(textBetween)) {
          builder.addSimpleInsertion(statement.offset, '\n');
        }
      }

      // Add newline after if needed
      if (index < statements.length - 1) {
        final nextStatement = statements[index + 1];
        final textBetween = content.substring(
          statement.end,
          nextStatement.offset,
        );

        if (!blankLineRegex.hasMatch(textBetween)) {
          builder.addSimpleInsertion(statement.end, '\n');
        }
      }
    });
  }
}
