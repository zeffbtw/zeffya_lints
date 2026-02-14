import 'dart:math';

import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

import 'functions.dart';

class ClassMemberOrderFix extends ResolvedCorrectionProducer {
  ClassMemberOrderFix({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;
  @override
  FixKind get fixKind => const FixKind(
    'dart.fix.classMemberOrder',
    DartFixKindPriority.standard,
    'Reorder class members',
  );

  @override
  Future<void> compute(ChangeBuilder builder) async {
    AstNode? node = coveringNode;

    while (node != null && node is! ClassDeclaration) {
      node = node.parent;
    }

    if (node is! ClassDeclaration) return;

    final classNode = node;

    final content = unitResult.content;
    final bodyStart = classNode.leftBracket.end;
    final bodyEnd = classNode.rightBracket.offset;

    final constructorMembers = classNode.members
        .whereType<ConstructorDeclaration>()
        .toList();

    final fieldsUsedInConstructorNames = <String>{};

    for (final ctor in constructorMembers) {
      for (final parameter in ctor.parameters.parameters) {
        final simpleParameter = parameter is DefaultFormalParameter
            ? parameter.parameter
            : parameter;

        if (simpleParameter is FieldFormalParameter) {
          fieldsUsedInConstructorNames.add(simpleParameter.name.lexeme);
        }
      }
    }

    final fieldsInCtor = <ClassMember>[];
    final constructors = <ConstructorDeclaration>[];
    final otherMembers = <ClassMember>[];

    for (final member in classNode.members) {
      if (member is ConstructorDeclaration) {
        constructors.add(member);
      } else if (member is FieldDeclaration) {
        final fieldNames = member.fields.variables.map((v) => v.name.lexeme);
        final isInCtor = fieldNames.any(fieldsUsedInConstructorNames.contains);

        if (isInCtor) {
          fieldsInCtor.add(member);
        } else {
          otherMembers.add(member);
        }
      } else {
        otherMembers.add(member);
      }
    }

    final newBody = _buildReorderedClassBody(
      content: content,
      fieldsInCtor: fieldsInCtor,
      constructors: constructors,
      otherMembers: otherMembers,
      fieldsInConstructor: fieldsUsedInConstructorNames,
    );

    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleReplacement(
        SourceRange(bodyStart, bodyEnd - bodyStart),
        newBody,
      );
    });
  }

  String _buildReorderedClassBody({
    required String content,
    required List<ClassMember> fieldsInCtor,
    required List<ConstructorDeclaration> constructors,
    required List<ClassMember> otherMembers,
    required Set<String> fieldsInConstructor,
  }) {
    final sb = StringBuffer();

    String getMemberSource(AstNode node) {
      return content.substring(node.offset, node.end);
    }

    fieldsInCtor.sort((a, b) {
      final aType = ClassMemberOrderFunctions.computeClassMemberType(
        a,
        fieldsInConstructor,
      );
      final bType = ClassMemberOrderFunctions.computeClassMemberType(
        b,
        fieldsInConstructor,
      );
      return aType.index.compareTo(bType.index);
    });

    otherMembers.sort((a, b) {
      final aType = ClassMemberOrderFunctions.computeClassMemberType(
        a,
        fieldsInConstructor,
      );
      final bType = ClassMemberOrderFunctions.computeClassMemberType(
        b,
        fieldsInConstructor,
      );
      return aType.index.compareTo(bType.index);
    });

    for (final member in fieldsInCtor) {
      sb.writeln(getMemberSource(member));
    }

    sb.writeln();

    for (final member in constructors) {
      sb.writeln(getMemberSource(member));
      sb.writeln();
    }

    sb.writeln();

    for (int i = 0; i < otherMembers.length; i++) {
      final member = otherMembers[i];
      sb.writeln(getMemberSource(member));

      final type = ClassMemberOrderFunctions.computeClassMemberType(
        member,
        fieldsInConstructor,
      );
      final otherType = ClassMemberOrderFunctions.computeClassMemberType(
        otherMembers[min(i + 1, otherMembers.length - 1)],
        fieldsInConstructor,
      );

      if (type.isDifferentGroups(otherType)) sb.writeln();
    }

    sb.writeln();

    return sb.toString().trimRight();
  }
}
