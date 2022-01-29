import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:code_builder/code_builder.dart';
import 'package:worker_bee_builder/src/message/common.dart';
import 'package:worker_bee_builder/src/types.dart';

class JsGenerator extends MessageGenerator {
  JsGenerator(ClassElement classEl, ClassElement messageEl)
      : super(classEl, messageEl);

  @override
  Library generate() {
    return Library((b) => b..body.add(_class));
  }

  Class get _class => Class(
        (c) => c
          ..annotations.addAll([
            DartTypes.js.js.newInstance([]),
            DartTypes.js.anonymous,
          ])
          ..name = messageTypeImplName
          ..constructors.addAll(_constructors)
          ..implements.add(messageType)
          ..methods.addAll(_fields),
      );

  Iterable<Constructor> get _constructors sync* {
    // Primary constructor
    yield Constructor(
      (c) => c
        ..external = true
        ..factory = true
        ..optionalParameters.addAll([
          for (final field in messageFields)
            Parameter(
              (p) => p
                ..toThis = false
                ..name = field.name
                ..type = field.type.accept(symbolVisitor)
                ..named = true
                ..required =
                    field.type.nullabilitySuffix == NullabilitySuffix.none,
            ),
        ]),
    );

    // Private done constructor
    yield Constructor(
      (c) => c
        ..external = true
        ..factory = true
        ..name = '_done'
        ..optionalParameters.add(
          Parameter(
            (p) => p
              ..toThis = false
              ..name = 'result'
              ..type = resultType.nonNull
              ..named = true
              ..required = true,
          ),
        ),
    );
  }

  Iterable<Method> get _fields sync* {
    for (final field in messageFields) {
      yield Method(
        (m) => m
          ..annotations.add(refer('override'))
          ..external = true
          ..type = MethodType.getter
          ..returns = field.type.accept(symbolVisitor)
          ..name = field.name,
      );
    }

    // Result getter
    yield Method(
      (m) => m
        ..annotations.add(refer('override'))
        ..external = true
        ..type = MethodType.getter
        ..returns = resultType.nullable
        ..name = 'result',
    );
  }
}
