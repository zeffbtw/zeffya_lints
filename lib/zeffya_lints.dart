import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:zeffya_lints/rules/class_member_order/class_member_order_rule.dart';
import 'package:zeffya_lints/rules/constructor_parameter_order/constructor_parameter_order_rule.dart';
import 'package:zeffya_lints/rules/control_flow_spacing/control_flow_spacing_rule.dart';

PluginBase createPlugin() => _CustomLintPlugin();

class _CustomLintPlugin extends PluginBase {
  @override
  List<LintRule> getLintRules(CustomLintConfigs configs) => [
        ClassMemberOrderRule(),
        ConstructorParameterOrderRule(),
        ControlFlowSpacingRule(),
      ];
}
