import 'dart:math';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/source/source.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:zeffya_lints/rules/class_member_order/class_member_order_functions.dart';

class ClassMemberOrderQuickFix extends DartFix {
  @override
  void run(
    CustomLintResolver resolver,
    ChangeReporter reporter,
    CustomLintContext context,
    AnalysisError analysisError,
    List<AnalysisError> others,
  ) {
    context.registry.addClassDeclaration((classNode) {
      if (!analysisError.sourceRange.intersects(classNode.sourceRange)) return;

      final constructorMembers = classNode.members.whereType<ConstructorDeclaration>().toList();
      final source = resolver.source;

      final fieldsUsedInConstructorNames = <String>{};
      for (final ctor in constructorMembers) {
        for (final parameter in ctor.parameters.parameters) {
          final simpleParameter =
              parameter is DefaultFormalParameter ? parameter.parameter : parameter;
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

      final bodyStart = classNode.leftBracket.end;
      final bodyEnd = classNode.rightBracket.offset;
      final length = bodyEnd - bodyStart;

      final newBody = _buildReorderedClassBody(
        fieldsInCtor: fieldsInCtor,
        constructors: constructors,
        otherMembers: otherMembers,
        source: source,
      );

      final changeBuilder = reporter.createChangeBuilder(
        message: 'Reorder class members',
        priority: 10,
      );

      changeBuilder.addDartFileEdit((builder) {
        builder.addSimpleReplacement(
          SourceRange(bodyStart, length),
          newBody,
        );
        builder.format(classNode.sourceRange);
      });
    });
  }

  String _buildReorderedClassBody({
    required List<ClassMember> fieldsInCtor,
    required List<ConstructorDeclaration> constructors,
    required List<ClassMember> otherMembers,
    required Source source,
  }) {
    final sb = StringBuffer();

    final Set<String> fieldsInConstructor = {};
    for (final constructor in constructors) {
      for (final parameter in constructor.parameters.parameters) {
        final simpleParameter =
            parameter is DefaultFormalParameter ? parameter.parameter : parameter;
        if (simpleParameter is FieldFormalParameter) {
          fieldsInConstructor.add(simpleParameter.name.lexeme);
        }
      }
    }

    String getMemberSource(AstNode node) {
      final fileContent = source.contents.data;
      return fileContent.substring(node.offset, node.end);
    }

    fieldsInCtor.sort((a, b) {
      final aType = ClassMemberOrderFunctions.computeClassMemberType(a, fieldsInConstructor);
      final bType = ClassMemberOrderFunctions.computeClassMemberType(b, fieldsInConstructor);
      return aType.index.compareTo(bType.index);
    });

    otherMembers.sort((a, b) {
      final aType = ClassMemberOrderFunctions.computeClassMemberType(a, fieldsInConstructor);
      final bType = ClassMemberOrderFunctions.computeClassMemberType(b, fieldsInConstructor);
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

      final type = ClassMemberOrderFunctions.computeClassMemberType(member, fieldsInConstructor);
      final othertype = ClassMemberOrderFunctions.computeClassMemberType(
        otherMembers[min(i + 1, otherMembers.length - 1)],
        fieldsInConstructor,
      );

      if (type.isDifferentGropus(othertype)) sb.writeln();
    }
    sb.writeln();

    return sb.toString().trimRight();
  }
}
