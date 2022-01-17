import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:worker_bee_builder/src/type_visitor.dart';

enum Target { vm, js }

class Message {
  const Message(this.target, this.impl);

  final Target target;
  final String impl;
}

class MessageGenerator {
  const MessageGenerator(this.el);

  static const _symbolVisitor = SymbolVisitor();
  final ClassElement el;

  Future<List<Message>> generate() async {
    if (!el.isAbstract) {
      throw ArgumentError('Message classes must be abstract');
    }
    final messageTypeName = el.name;
    final messageTypeSourceUri = el.librarySource.uri;
    final messageType =
        Reference(messageTypeName, messageTypeSourceUri.toString());
    final messageTypeImplName = '${messageTypeName}Impl';

    final messageFields = el.fields;
    for (final field in messageFields) {
      // Check that it is an abstract getter.
      if (!field.isSynthetic) {
        throw ArgumentError('Message fields must be getters');
      }
      // TODO: Ensure the type is allowed to be sent using `SendPort.send`.
      // There are only a few types not allowed (as of 2.15):
      // https://api.dart.dev/stable/2.15.0/dart-isolate/SendPort/send.html
    }

    final vmClass = Library(
      (l) => l
        ..body.add(Class(
          (c) => c
            ..name = messageTypeImplName
            ..implements.add(messageType)
            ..constructors.add(_vmConstructor(messageFields))
            ..fields.addAll(_vmFields(messageFields)),
        )),
    );

    final jsClass = Library(
      (l) => l
        ..body.add(Class(
          (c) => c
            ..name = messageTypeImplName
            ..implements.add(messageType)
            ..methods.addAll(_jsFields(messageFields)),
        )),
    );

    final emitter = DartEmitter(
      allocator: Allocator(),
    );
    final formatter = DartFormatter(
      fixes: StyleFix.all,
    );

    return [
      Message(Target.vm, formatter.format('${vmClass.accept(emitter)}')),
      Message(Target.js, formatter.format('${jsClass.accept(emitter)}')),
    ];
  }

  Constructor _vmConstructor(List<FieldElement> fields) => Constructor((c) => c
    ..constant = true
    ..optionalParameters.addAll([
      for (final field in fields)
        Parameter((p) => p
          ..toThis = true
          ..name = field.name
          ..required = field.type.nullabilitySuffix == NullabilitySuffix.none),
    ]));

  Iterable<Field> _vmFields(List<FieldElement> fields) sync* {
    for (final field in fields) {
      yield Field((f) => f
        ..annotations.add(refer('override'))
        ..modifier = FieldModifier.final$
        ..type = field.type.accept(_symbolVisitor)
        ..name = field.name);
    }
  }

  Iterable<Method> _jsFields(List<FieldElement> fields) sync* {
    for (final field in fields) {
      yield Method((m) => m
        ..annotations.add(refer('override'))
        ..external = true
        ..type = MethodType.getter
        ..returns = field.type.accept(_symbolVisitor)
        ..name = field.name);
    }
  }
}
