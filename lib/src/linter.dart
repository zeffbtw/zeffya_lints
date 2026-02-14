import 'dart:math';

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/source/line_info.dart';

import 'rules/class_member_order/functions.dart';
import 'rules/constructor_parameter_order/functions.dart';
import 'utils.dart';

/// Data class for lint errors
class LintError {
  final String code;
  final String message;
  final String? correction;
  final int offset;
  final int length;
  final int line;
  final int column;
  final int endLine;
  final int endColumn;
  final bool hasFix;

  const LintError({
    required this.code,
    required this.message,
    required this.offset,
    required this.length,
    required this.line,
    required this.column,
    required this.endLine,
    required this.endColumn,
    this.correction,
    this.hasFix = false,
  });
}

/// Data class for source edits
class SourceEditData {
  final int offset;
  final int length;
  final String replacement;

  const SourceEditData({
    required this.offset,
    required this.length,
    required this.replacement,
  });
}

/// Data class for lint fixes
class LintFix {
  final String code;
  final String message;
  final String description;
  final String path;
  final int offset;
  final int length;
  final int priority;
  final List<SourceEditData> edits;

  const LintFix({
    required this.code,
    required this.message,
    required this.description,
    required this.path,
    required this.offset,
    required this.length,
    required this.priority,
    required this.edits,
  });
}

typedef _ErrorCallback =
    void Function(
      String code,
      int offset,
      int length,
      String message,
      String? correction,
      bool hasFix,
    );

/// Main linter for CLI usage — runs all rules via shared functions
class ZeffyaLinter {
  List<LintError> analyze(ResolvedUnitResult result) {
    final errors = <LintError>[];
    final unit = result.unit;
    final content = result.content;
    final lineInfo = result.lineInfo;

    void onError(
      String code,
      int offset,
      int length,
      String message,
      String? correction,
      bool hasFix,
    ) {
      final start = lineInfo.getLocation(offset);
      final end = lineInfo.getLocation(offset + length);
      errors.add(
        LintError(
          code: code,
          message: message,
          correction: correction,
          offset: offset,
          length: length,
          line: start.lineNumber,
          column: start.columnNumber,
          endLine: end.lineNumber,
          endColumn: end.columnNumber,
          hasFix: hasFix,
        ),
      );
    }

    // class_member_order
    unit.accept(_ClassMemberOrderCliVisitor(onError, content, lineInfo));
    // constructor_parameter_order
    unit.accept(_ConstructorParameterOrderCliVisitor(onError));
    // control_flow_spacing
    unit.accept(_ControlFlowSpacingCliVisitor(onError, content));

    return errors;
  }

  List<LintFix> getFixes(
    ResolvedUnitResult result,
    int offset, {
    String? code,
  }) {
    final fixes = <LintFix>[];
    final unit = result.unit;
    final content = result.content;
    final path = result.path;

    // class_member_order fix
    if (code == null || code == 'class_member_order') {
      final cmoFix = _ClassMemberOrderCliFix(offset: offset, content: content);
      unit.accept(cmoFix);

      if (cmoFix.targetClass != null && cmoFix.newBody != null) {
        final bodyStart = cmoFix.targetClass!.leftBracket.end;
        final bodyEnd = cmoFix.targetClass!.rightBracket.offset;
        fixes.add(
          LintFix(
            code: 'class_member_order',
            message: 'Class members should be ordered.',
            description: 'Reorder class members',
            path: path,
            offset: bodyStart,
            length: bodyEnd - bodyStart,
            priority: 10,
            edits: [
              SourceEditData(
                offset: bodyStart,
                length: bodyEnd - bodyStart,
                replacement: cmoFix.newBody!,
              ),
            ],
          ),
        );
      }
    }

    // constructor_parameter_order fix
    if (code == null || code == 'constructor_parameter_order') {
      final cpoFix = _ConstructorParameterOrderCliFix(
        offset: offset,
        content: content,
      );
      unit.accept(cpoFix);

      if (cpoFix.targetConstructor != null && cpoFix.sortedParamsText != null) {
        final params = cpoFix.targetConstructor!.parameters.parameters;

        if (params.isNotEmpty) {
          final start = params.first.offset;
          final end = params.last.end;
          fixes.add(
            LintFix(
              code: 'constructor_parameter_order',
              message: 'Constructor parameters should be ordered correctly.',
              description: 'Sort constructor parameters',
              path: path,
              offset: start,
              length: end - start,
              priority: 9,
              edits: [
                SourceEditData(
                  offset: start,
                  length: end - start,
                  replacement: cpoFix.sortedParamsText!,
                ),
              ],
            ),
          );
        }
      }
    }

    // control_flow_spacing fix
    if (code == null || code == 'control_flow_spacing') {
      final cfsFix = _ControlFlowSpacingCliFix(
        offset: offset,
        content: content,
      );
      unit.accept(cfsFix);

      if (cfsFix.targetStatement != null) {
        final statement = cfsFix.targetStatement!;
        final edits = <SourceEditData>[];

        if (cfsFix.needsNewlineBefore) {
          edits.add(
            SourceEditData(
              offset: statement.offset,
              length: 0,
              replacement: '\n',
            ),
          );
        }

        if (cfsFix.needsNewlineAfter) {
          edits.add(
            SourceEditData(offset: statement.end, length: 0, replacement: '\n'),
          );
        }

        if (edits.isNotEmpty) {
          fixes.add(
            LintFix(
              code: 'control_flow_spacing',
              message:
                  'Control flow statements should be separated by an empty line.',
              description: 'Add empty lines around control flow statement',
              path: path,
              offset: statement.offset,
              length: statement.length,
              priority: 8,
              edits: edits,
            ),
          );
        }
      }
    }

    return fixes;
  }
}

// --- CLI Visitors for detection ---

class _ClassMemberOrderCliVisitor extends RecursiveAstVisitor<void> {
  final _ErrorCallback onError;
  final String content;
  final LineInfo lineInfo;

  _ClassMemberOrderCliVisitor(this.onError, this.content, this.lineInfo);

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    final Set<String> fieldsInConstructor = {};

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

    final types = ClassMemberOrderFunctions.getTypes(
      node.members,
      fieldsInConstructor,
    );
    final violations = ClassMemberOrderFunctions.getOrderViolations(types);
    violations.addAll(
      ClassMemberOrderFunctions.checkBlankLinesAroundConstructors(
        node,
        content,
        lineInfo,
      ),
    );

    if (violations.isNotEmpty) {
      onError(
        'class_member_order',
        node.offset,
        node.length,
        'Class members should be ordered. ${violations.join(', ')}',
        'Reorder class members',
        true,
      );
    }

    super.visitClassDeclaration(node);
  }
}

class _ConstructorParameterOrderCliVisitor extends RecursiveAstVisitor<void> {
  final _ErrorCallback onError;

  _ConstructorParameterOrderCliVisitor(this.onError);

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    final parameters = node.parameters.parameters;

    if (parameters.isEmpty) return;

    final sortedOrder = List<FormalParameter>.from(parameters)
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

    for (int i = 0; i < parameters.length; i++) {
      if (parameters[i] != sortedOrder[i]) {
        final start = parameters.first.offset;
        final end = parameters.last.end;
        onError(
          'constructor_parameter_order',
          start,
          end - start,
          'Constructor parameters should be ordered correctly.',
          'Reorder constructor parameters',
          true,
        );
        break;
      }
    }

    super.visitConstructorDeclaration(node);
  }
}

class _ControlFlowSpacingCliVisitor extends RecursiveAstVisitor<void> {
  final _ErrorCallback onError;
  final String content;

  _ControlFlowSpacingCliVisitor(this.onError, this.content);

  @override
  void visitIfStatement(IfStatement node) {
    _checkStatement(node);
    super.visitIfStatement(node);
  }

  @override
  void visitForStatement(ForStatement node) {
    _checkStatement(node);
    super.visitForStatement(node);
  }

  @override
  void visitWhileStatement(WhileStatement node) {
    _checkStatement(node);
    super.visitWhileStatement(node);
  }

  @override
  void visitDoStatement(DoStatement node) {
    _checkStatement(node);
    super.visitDoStatement(node);
  }

  @override
  void visitSwitchStatement(SwitchStatement node) {
    _checkStatement(node);
    super.visitSwitchStatement(node);
  }

  void _checkStatement(Statement statement) {
    final parentBlock = statement.parent;

    if (parentBlock is! Block) return;

    final statements = parentBlock.statements;
    final index = statements.indexOf(statement);

    if (index > 0) {
      final previousStatement = statements[index - 1];
      final textBetween = content.substring(
        previousStatement.end,
        statement.offset,
      );

      if (!blankLineRegex.hasMatch(textBetween)) {
        onError(
          'control_flow_spacing',
          statement.offset,
          statement.length,
          'Control flow statements should be separated by an empty line.',
          'Add an empty line before and after control flow statements',
          true,
        );
        return;
      }
    }

    if (index < statements.length - 1) {
      final nextStatement = statements[index + 1];
      final textBetween = content.substring(
        statement.end,
        nextStatement.offset,
      );

      if (!blankLineRegex.hasMatch(textBetween)) {
        onError(
          'control_flow_spacing',
          statement.offset,
          statement.length,
          'Control flow statements should be separated by an empty line.',
          'Add an empty line before and after control flow statements',
          true,
        );
      }
    }
  }
}

// --- CLI Visitors for fixes ---

class _ClassMemberOrderCliFix extends RecursiveAstVisitor<void> {
  final int offset;
  final String content;

  _ClassMemberOrderCliFix({required this.offset, required this.content});

  ClassDeclaration? targetClass;
  String? newBody;

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    if (offset < node.offset || offset > node.end) {
      super.visitClassDeclaration(node);
      return;
    }

    targetClass = node;

    final fieldsUsedInConstructorNames = <String>{};

    for (final ctor in node.members.whereType<ConstructorDeclaration>()) {
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

class _ConstructorParameterOrderCliFix extends RecursiveAstVisitor<void> {
  final int offset;
  final String content;

  _ConstructorParameterOrderCliFix({
    required this.offset,
    required this.content,
  });

  ConstructorDeclaration? targetConstructor;
  String? sortedParamsText;

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    final parameters = node.parameters.parameters;

    if (parameters.isEmpty) return;

    final start = parameters.first.offset;
    final end = parameters.last.end;

    if (offset >= start && offset <= end) {
      targetConstructor = node;

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

      sortedParamsText = sortedParams
          .map((p) => content.substring(p.offset, p.end))
          .join(',\n ');
    }

    super.visitConstructorDeclaration(node);
  }
}

class _ControlFlowSpacingCliFix extends RecursiveAstVisitor<void> {
  final int offset;
  final String content;

  _ControlFlowSpacingCliFix({required this.offset, required this.content});

  bool needsNewlineBefore = false;
  bool needsNewlineAfter = false;
  Statement? targetStatement;

  @override
  void visitIfStatement(IfStatement node) {
    _checkForFix(node);
    super.visitIfStatement(node);
  }

  @override
  void visitForStatement(ForStatement node) {
    _checkForFix(node);
    super.visitForStatement(node);
  }

  @override
  void visitWhileStatement(WhileStatement node) {
    _checkForFix(node);
    super.visitWhileStatement(node);
  }

  @override
  void visitDoStatement(DoStatement node) {
    _checkForFix(node);
    super.visitDoStatement(node);
  }

  @override
  void visitSwitchStatement(SwitchStatement node) {
    _checkForFix(node);
    super.visitSwitchStatement(node);
  }

  void _checkForFix(Statement statement) {
    if (statement.offset != offset) return;

    targetStatement = statement;

    final parentBlock = statement.parent;

    if (parentBlock is! Block) return;

    final statements = parentBlock.statements;
    final index = statements.indexOf(statement);

    if (index > 0) {
      final previousStatement = statements[index - 1];
      final textBetween = content.substring(
        previousStatement.end,
        statement.offset,
      );
      needsNewlineBefore = !blankLineRegex.hasMatch(textBetween);
    }

    if (index < statements.length - 1) {
      final nextStatement = statements[index + 1];
      final textBetween = content.substring(
        statement.end,
        nextStatement.offset,
      );
      needsNewlineAfter = !blankLineRegex.hasMatch(textBetween);
    }
  }
}
