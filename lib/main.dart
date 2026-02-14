import 'package:analysis_server_plugin/plugin.dart';
import 'package:analysis_server_plugin/registry.dart';

import 'src/rules/class_member_order/rule.dart';
import 'src/rules/class_member_order/fix.dart';
import 'src/rules/constructor_parameter_order/rule.dart';
import 'src/rules/constructor_parameter_order/fix.dart';
import 'src/rules/control_flow_spacing/rule.dart';
import 'src/rules/control_flow_spacing/fix.dart';

final plugin = ZeffyaLintsPlugin();

class ZeffyaLintsPlugin extends Plugin {
  @override
  String get name => 'zeffya_lints';

  @override
  void register(PluginRegistry registry) {
    registry.registerWarningRule(ClassMemberOrderRule());
    registry.registerFixForRule(
      ClassMemberOrderRule.code,
      ClassMemberOrderFix.new,
    );

    registry.registerWarningRule(ConstructorParameterOrderRule());
    registry.registerFixForRule(
      ConstructorParameterOrderRule.code,
      ConstructorParameterOrderFix.new,
    );

    registry.registerWarningRule(ControlFlowSpacingRule());
    registry.registerFixForRule(
      ControlFlowSpacingRule.code,
      ControlFlowSpacingFix.new,
    );
  }
}
