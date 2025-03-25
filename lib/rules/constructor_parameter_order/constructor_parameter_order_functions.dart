import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:zeffya_lints/rules/constructor_parameter_order/constructor_parameter_type.dart';

class ConstructorParameterOrderFunctions {
  static ConstructorParameterType computeConstructorParameterType(FormalParameter param) {
    final bool isRequired = param.isRequiredPositional || param.isRequiredNamed;
    final bool hasThis = param is FieldFormalParameter || param.toSource().contains('this.');
    final bool hasDefaultValue = param is DefaultFormalParameter && param.defaultValue != null;
    final bool isNullable =
        param.declaredElement?.type.nullabilitySuffix == NullabilitySuffix.question;

    if (param.toSource().contains('super.')) {
      return ConstructorParameterType.superField;
    }
    if (isRequired && hasThis) return ConstructorParameterType.requiredThisField;
    if (isRequired) return ConstructorParameterType.requiredVariable;
    if (hasThis && hasDefaultValue) {
      return ConstructorParameterType.thisFieldWithValue;
    }
    if (hasThis && isNullable) return ConstructorParameterType.thisFieldNullable;
    if (hasThis && isNullable && hasDefaultValue) {
      return ConstructorParameterType.thisFieldNullableWithValue;
    }
    if (hasThis) return ConstructorParameterType.thisField;

    if (isNullable) return ConstructorParameterType.variableNullable;
    if (hasDefaultValue) {
      return ConstructorParameterType.variableWithValue;
    }

    return ConstructorParameterType.none;
  }
}
