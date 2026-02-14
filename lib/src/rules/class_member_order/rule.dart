import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import 'functions.dart';

class ClassMemberOrderRule extends AnalysisRule {
  ClassMemberOrderRule()
    : super(
        name: 'class_member_order',
        description: 'Class members should be ordered correctly',
      );

  static const code = LintCode(
    'class_member_order',
    'Class members should be ordered.',
    correctionMessage: 'Reorder class members',
  );

  @override
  DiagnosticCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _ClassMemberOrderVisitor(this, context);
    registry.addClassDeclaration(this, visitor);
  }
}

class _ClassMemberOrderVisitor extends SimpleAstVisitor<void> {
  final ClassMemberOrderRule rule;
  final RuleContext context;

  _ClassMemberOrderVisitor(this.rule, this.context);

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    final content = context.currentUnit!.content;
    final lineInfo = context.currentUnit!.unit.lineInfo;
    final hasConstructor = node.members.any((m) => m is ConstructorDeclaration);

    final Set<String> fieldsInConstructor = {};
    final List<String> violations = [];

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
    violations.addAll(
      ClassMemberOrderFunctions.checkBlankLinesAroundConstructors(
        node,
        content,
        lineInfo,
      ),
    );

    if (violations.isNotEmpty) {
      rule.reportAtNode(node);
    }
  }
}
