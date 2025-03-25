import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer/source/source.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:zeffya_lints/rules/class_member_order/class_member_order_functions.dart';
import 'package:zeffya_lints/rules/class_member_order/class_member_order_quick_fix.dart';
import 'package:zeffya_lints/rules/class_member_order/class_member_type.dart';

class ClassMemberOrderRule extends DartLintRule {
  const ClassMemberOrderRule() : super(code: _code);

  static const LintCode _code = LintCode(
    name: 'class_member_order',
    problemMessage: 'Class members should be ordered.',
  );

  @override
  List<Fix> getFixes() {
    return [ClassMemberOrderQuickFix()];
  }

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addClassDeclaration((classNode) {
      final hasConstructor = classNode.members.any((m) => m is ConstructorDeclaration);

      final source = resolver.source;
      final lineInfo = resolver.lineInfo;
      final Set<String> fieldsInConstructor = {};
      final List<String> violations = [];

      for (final member in classNode.members) {
        if (member is ConstructorDeclaration) {
          for (final parameter in member.parameters.parameters) {
            final simpleParameter =
                parameter is DefaultFormalParameter ? parameter.parameter : parameter;
            if (simpleParameter is FieldFormalParameter) {
              fieldsInConstructor.add(simpleParameter.name.lexeme);
            }
          }
        }
      }

      bool constructorSeen = false;

      for (final member in classNode.members) {
        if (member is ConstructorDeclaration) {
          constructorSeen = true;

          violations.addAll(
            _checkBlankLinesAroundConstructor(
              classNode,
              member,
              lineInfo,
              source,
            ),
          );

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

      final List<ClassMemberType> types = ClassMemberOrderFunctions.getTypes(
        classNode.members,
        fieldsInConstructor,
      );
      violations.addAll(ClassMemberOrderFunctions.getOrderViolations(types));

      if (violations.isNotEmpty) {
        _report(classNode, source, reporter, '${_code.problemMessage} ${violations.join(', ')}');
      }
    });
  }

  List<String> _checkBlankLinesAroundConstructor(
    ClassDeclaration classNode,
    ConstructorDeclaration constructorDecl,
    LineInfo lineInfo,
    Source source,
  ) {
    final List<String> violations = [];

    final classBodyBraceOffset = classNode.leftBracket.offset;
    final classBodyBraceLine = lineInfo.getLocation(classBodyBraceOffset).lineNumber;

    final startOffset = constructorDecl.firstTokenAfterCommentAndMetadata.offset;
    final startLine = lineInfo.getLocation(startOffset).lineNumber;

    final endOffset = constructorDecl.end;
    final endLine = lineInfo.getLocation(endOffset).lineNumber;

    if (startLine > 1 && startLine > (classBodyBraceLine + 1)) {
      final prevLineText = _getLineText(lineInfo, source, startLine - 1);
      if (prevLineText.trim().isNotEmpty) {
        violations.add('Before constructor should be empty line');
      }
    }

    final classClosingBraceLine = lineInfo.getLocation(classNode.rightBracket.offset).lineNumber;
    if (endLine + 1 < classClosingBraceLine) {
      final nextLineText = _getLineText(lineInfo, source, endLine + 1);
      if (nextLineText.trim().isNotEmpty) {
        violations.add('After constructor should be empty line');
      }
    }

    return violations;
  }

  String _getLineText(LineInfo lineInfo, Source source, int lineNumber) {
    final fileContent = source.contents.data;

    final offset = lineInfo.getOffsetOfLine(lineNumber - 1);

    final endOffset = (lineNumber == lineInfo.lineCount)
        ? fileContent.length
        : lineInfo.getOffsetOfLine(lineNumber);
    return fileContent.substring(offset, endOffset);
  }

  void _report(
    AstNode node,
    Source source,
    ErrorReporter reporter,
    String message,
  ) {
    final error = AnalysisError.forValues(
      source: source,
      offset: node.offset,
      length: node.length,
      errorCode: _code,
      message: message,
      correctionMessage: code.correctionMessage,
    );
    reporter.reportError(error);
  }
}
