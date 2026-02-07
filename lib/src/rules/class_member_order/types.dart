enum ClassMemberType {
  constructorField,
  constructor,
  staticConst,
  staticFinal,
  static,
  constant,
  lateFinal,
  finalVar,
  lateVar,
  variable,
  optional,
  setter,
  getter,
  overrideMethod,
  staticMethod,
  method,
  privateMethod,
  widgetOverrideBuildMethod,
  widgetBuildMethod,
  none;

  bool isDifferentGroups(ClassMemberType other) {
    final a = _ClassMemberGroup.fromType(this);
    final b = _ClassMemberGroup.fromType(other);
    return a != b;
  }
}

enum _ClassMemberGroup {
  constructor,
  variable,
  setterGetter,
  method,
  none;

  factory _ClassMemberGroup.fromType(ClassMemberType type) {
    switch (type) {
      case ClassMemberType.constructorField:
      case ClassMemberType.constructor:
        return constructor;
      case ClassMemberType.staticConst:
      case ClassMemberType.staticFinal:
      case ClassMemberType.static:
      case ClassMemberType.constant:
      case ClassMemberType.lateFinal:
      case ClassMemberType.finalVar:
      case ClassMemberType.lateVar:
      case ClassMemberType.variable:
      case ClassMemberType.optional:
        return variable;
      case ClassMemberType.setter:
      case ClassMemberType.getter:
        return setterGetter;
      case ClassMemberType.overrideMethod:
      case ClassMemberType.staticMethod:
      case ClassMemberType.method:
      case ClassMemberType.privateMethod:
      case ClassMemberType.widgetBuildMethod:
      case ClassMemberType.widgetOverrideBuildMethod:
        return method;
      case ClassMemberType.none:
        return none;
    }
  }
}
