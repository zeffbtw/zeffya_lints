import 'dart:math';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/source/line_info.dart';

import '../../base/lint_rule.dart';
import '../../linter.dart';
import 'functions.dart';

/// Rule: Class members should be ordered correctly
class ClassMemberOrderRule extends LintRule {
  @override
  String get code => 'class_member_order';

  @override
  String get message => 'Class members should be ordered.';

  @override
  String get correction => 'Reorder class members';

  @override
  bool get hasFix => true;

  @override
  AstVisitor<void> createVisitor({
    required ErrorCallback onError,
    required String content,
    required LineInfo lineInfo,
  }) {
    return _ClassMemberOrderVisitor(
      onError: onError,
      content: content,
      lineInfo: lineInfo,
      ruleMessage: message,
    );
  }

  @override
  List<LintFix> getFixes({
    required CompilationUnit unit,
    required String content,
    required String path,
    required int offset,
  }) {
    final fixes = <LintFix>[];
    final visitor = _FixVisitor(offset: offset, content: content);
    unit.accept(visitor);

    if (visitor.targetClass != null && visitor.newBody != null) {
      final classNode = visitor.targetClass!;
      final bodyStart = classNode.leftBracket.end;
      final bodyEnd = classNode.rightBracket.offset;

      fixes.add(LintFix(
        code: code,
        message: message,
        description: 'Reorder class members',
        path: path,
        offset: bodyStart,
        length: bodyEnd - bodyStart,
        priority: 10,
        edits: [
          SourceEditData(
            offset: bodyStart,
            length: bodyEnd - bodyStart,
            replacement: visitor.newBody!,
          ),
        ],
      ));
    }

    return fixes;
  }
}

class _ClassMemberOrderVisitor extends RecursiveAstVisitor<void> {
  final ErrorCallback onError;
  final String content;
  final LineInfo lineInfo;
  final String ruleMessage;

  _ClassMemberOrderVisitor({
    required this.onError,
    required this.content,
    required this.lineInfo,
    required this.ruleMessage,
  });

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    final hasConstructor =
        node.members.any((m) => m is ConstructorDeclaration);

    final Set<String> fieldsInConstructor = {};
    final List<String> violations = [];

    // Collect fields used in constructors
    for (final member in node.members) {
      if (member is ConstructorDeclaration) {
        for (final parameter in member.parameters.parameters) {
          final simpleParameter = parameter is DefaultFormalParameter
              ? parameter.parameter
              : parameter;
          if (simpleParameter is FieldFormalParameter) {
            fieldsInConstructor.add(simpleParameter.name.lexeme);
          }
        }
      }
    }

    bool constructorSeen = false;

    for (final member in node.members) {
      if (member is ConstructorDeclaration) {
        constructorSeen = true;
        violations.addAll(_checkBlankLinesAroundConstructor(node, member));
        continue;
      }

      if (member is FieldDeclaration) {
        for (final variable in member.fields.variables) {
          final fieldName = variable.name.lexeme;
          final isInConstructor = fieldsInConstructor.contains(fieldName);

          if (isInConstructor && constructorSeen && hasConstructor) {
            violations.add('Field "$fieldName" should be before constructor');
          }

          if (!isInConstructor && !constructorSeen && hasConstructor) {
            violations.add('Field "$fieldName" should be after constructor');
          }
        }
      }
    }

    final types = ClassMemberOrderFunctions.getTypes(
      node.members,
      fieldsInConstructor,
    );
    violations.addAll(ClassMemberOrderFunctions.getOrderViolations(types));

    if (violations.isNotEmpty) {
      onError(
        node.offset,
        node.length,
        '$ruleMessage ${violations.join(', ')}',
        null,
      );
    }

    super.visitClassDeclaration(node);
  }

  List<String> _checkBlankLinesAroundConstructor(
    ClassDeclaration classNode,
    ConstructorDeclaration constructorDecl,
  ) {
    final List<String> violations = [];

    final classBodyBraceOffset = classNode.leftBracket.offset;
    final classBodyBraceLine =
        lineInfo.getLocation(classBodyBraceOffset).lineNumber;

    final startOffset =
        constructorDecl.firstTokenAfterCommentAndMetadata.offset;
    final startLine = lineInfo.getLocation(startOffset).lineNumber;

    final endOffset = constructorDecl.end;
    final endLine = lineInfo.getLocation(endOffset).lineNumber;

    if (startLine > 1 && startLine > (classBodyBraceLine + 1)) {
      final prevLineText = _getLineText(startLine - 1);
      if (prevLineText.trim().isNotEmpty) {
        violations.add('Before constructor should be empty line');
      }
    }

    final classClosingBraceLine =
        lineInfo.getLocation(classNode.rightBracket.offset).lineNumber;
    if (endLine + 1 < classClosingBraceLine) {
      final nextLineText = _getLineText(endLine + 1);
      if (nextLineText.trim().isNotEmpty) {
        violations.add('After constructor should be empty line');
      }
    }

    return violations;
  }

  String _getLineText(int lineNumber) {
    final offset = lineInfo.getOffsetOfLine(lineNumber - 1);
    final endOffset = (lineNumber == lineInfo.lineCount)
        ? content.length
        : lineInfo.getOffsetOfLine(lineNumber);
    return content.substring(offset, endOffset);
  }
}

class _FixVisitor extends RecursiveAstVisitor<void> {
  final int offset;
  final String content;
  ClassDeclaration? targetClass;
  String? newBody;

  _FixVisitor({required this.offset, required this.content});

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    if (offset < node.offset || offset > node.end) {
      super.visitClassDeclaration(node);
      return;
    }

    targetClass = node;

    final constructorMembers =
        node.members.whereType<ConstructorDeclaration>().toList();

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

    for (final member in node.members) {
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

    newBody = _buildReorderedClassBody(
      fieldsInCtor: fieldsInCtor,
      constructors: constructors,
      otherMembers: otherMembers,
      fieldsInConstructor: fieldsUsedInConstructorNames,
    );

    super.visitClassDeclaration(node);
  }

  String _buildReorderedClassBody({
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
      final aType =
          ClassMemberOrderFunctions.computeClassMemberType(a, fieldsInConstructor);
      final bType =
          ClassMemberOrderFunctions.computeClassMemberType(b, fieldsInConstructor);
      return aType.index.compareTo(bType.index);
    });

    otherMembers.sort((a, b) {
      final aType =
          ClassMemberOrderFunctions.computeClassMemberType(a, fieldsInConstructor);
      final bType =
          ClassMemberOrderFunctions.computeClassMemberType(b, fieldsInConstructor);
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
          member, fieldsInConstructor);
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
