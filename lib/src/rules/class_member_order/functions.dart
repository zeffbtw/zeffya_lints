import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/source/line_info.dart';

import 'types.dart';

class ClassMemberOrderFunctions {
  static List<ClassMemberType> getTypes(
    NodeList<ClassMember> members,
    Set<String> fieldsInConstructor,
  ) {
    final types = <ClassMemberType>[];

    for (final member in members) {
      types.add(computeClassMemberType(member, fieldsInConstructor));
    }

    return types;
  }

  static List<String> getOrderViolations(List<ClassMemberType> types) {
    final List<String> violations = [];

    for (int i = 1; i < types.length; i++) {
      if (types[i].index < types[i - 1].index) {
        violations.add(
          '| <${types[i].name}> must be before <${types[i - 1].name}> |',
        );
        break;
      }
    }

    return violations;
  }

  static ClassMemberType computeClassMemberType(
    ClassMember member,
    Set<String> fieldsInConstructor,
  ) {
    if (member is ConstructorDeclaration) {
      return ClassMemberType.constructor;
    } else if (member is FieldDeclaration) {
      final names = member.fields.variables.map((v) => v.name.lexeme);
      final inCtor = names.any(fieldsInConstructor.contains);

      if (inCtor) return ClassMemberType.constructorField;

      if (member.isStatic && member.fields.isConst) {
        return ClassMemberType.staticConst;
      }

      if (member.isStatic && member.fields.isFinal) {
        return ClassMemberType.staticFinal;
      }

      if (member.isStatic) return ClassMemberType.static;

      if (member.fields.isConst) return ClassMemberType.constant;

      if (member.fields.isFinal && member.fields.isLate) {
        return ClassMemberType.lateFinal;
      }

      if (member.fields.isFinal) return ClassMemberType.finalVar;

      if (member.fields.variables.any(
        (v) =>
            v.declaredFragment?.element.type.nullabilitySuffix ==
            NullabilitySuffix.question,
      )) {
        return ClassMemberType.optional;
      }

      if (member.fields.isLate) return ClassMemberType.lateVar;

      return ClassMemberType.variable;
    } else if (member is MethodDeclaration) {
      if (member.isGetter) return ClassMemberType.getter;

      if (member.isSetter) return ClassMemberType.setter;

      if (member.isStatic) return ClassMemberType.staticMethod;

      if (member.name.lexeme.toLowerCase().contains('build') &&
          member.returnType?.toSource() == 'Widget') {
        if (member.metadata.any((m) => m.name.name == 'override')) {
          return ClassMemberType.widgetOverrideBuildMethod;
        }

        return ClassMemberType.widgetBuildMethod;
      }

      if (member.metadata.any((m) => m.name.name == 'override')) {
        return ClassMemberType.overrideMethod;
      }

      if (member.name.lexeme.startsWith('_')) {
        return ClassMemberType.privateMethod;
      }

      return ClassMemberType.method;
    }

    return ClassMemberType.none;
  }

  /// Check blank lines before/after each constructor in a class.
  /// Used by both IDE rule and CLI visitor.
  static List<String> checkBlankLinesAroundConstructors(
    ClassDeclaration node,
    String content,
    LineInfo lineInfo,
  ) {
    final List<String> violations = [];

    for (final member in node.members) {
      if (member is ConstructorDeclaration) {
        violations.addAll(
          _checkBlankLinesAroundConstructor(node, member, content, lineInfo),
        );
      }
    }

    return violations;
  }

  static List<String> _checkBlankLinesAroundConstructor(
    ClassDeclaration classNode,
    ConstructorDeclaration constructorDecl,
    String content,
    LineInfo lineInfo,
  ) {
    final List<String> violations = [];

    final classBodyBraceLine = lineInfo
        .getLocation(classNode.leftBracket.offset)
        .lineNumber;

    final startLine = lineInfo.getLocation(constructorDecl.offset).lineNumber;
    final endLine = lineInfo.getLocation(constructorDecl.end).lineNumber;

    if (startLine > 1 && startLine > (classBodyBraceLine + 1)) {
      final prevLineText = _getLineText(content, lineInfo, startLine - 1);

      if (prevLineText.trim().isNotEmpty) {
        violations.add('Before constructor should be empty line');
      }
    }

    final classClosingBraceLine = lineInfo
        .getLocation(classNode.rightBracket.offset)
        .lineNumber;

    if (endLine + 1 < classClosingBraceLine) {
      final nextLineText = _getLineText(content, lineInfo, endLine + 1);

      if (nextLineText.trim().isNotEmpty) {
        violations.add('After constructor should be empty line');
      }
    }

    return violations;
  }

  static String _getLineText(String content, LineInfo lineInfo, int lineNumber) {
    final offset = lineInfo.getOffsetOfLine(lineNumber - 1);
    final endOffset = (lineNumber == lineInfo.lineCount)
        ? content.length
        : lineInfo.getOffsetOfLine(lineNumber);
    return content.substring(offset, endOffset);
  }
}
