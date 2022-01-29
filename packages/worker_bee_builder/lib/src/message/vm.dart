import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:code_builder/code_builder.dart';
import 'package:worker_bee_builder/src/message/common.dart';
import 'package:worker_bee_builder/src/types.dart';

class VmGenerator extends MessageGenerator {
  VmGenerator(ClassElement classEl, ClassElement messageEl)
      : super(classEl, messageEl);

  @override
  Library generate() {
    return Library(
      (b) => b
        ..body.addAll([
          _messageClass,
          _runner,
          _workerClass,
        ]),
    );
  }

  static final _typeMap = <String, Reference>{
    'Uint8List': DartTypes.isolate.transferableTypedData,
  };

  Expression _convert(
    Expression value,
    Reference from, {
    required bool isNullable,
  }) {
    switch (from.symbol) {
      case 'Uint8List':
        return DartTypes.isolate.transferableTypedData
            .newInstanceNamed('fromList', [
          literalList([value]),
        ]);
      case 'TransferableTypedData':
        return value
            .property('materialize')
            .call([])
            .property('asUint8List')
            .call([]);
    }
    throw ArgumentError('Invalid from: $from');
  }

  Class get _messageClass => Class(
        (c) => c
          ..name = messageTypeImplName
          ..implements.add(messageType)
          ..constructors.addAll(_constructors)
          ..fields.addAll(_fields)
          ..methods.addAll(_methods),
      );

  Iterable<Constructor> get _constructors sync* {
    // Primary constructor
    yield Constructor(
      (c) => c
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
        ])
        ..initializers.addAll(_initializers),
    );

    // Internal result constructor
    yield Constructor(
      (c) => c
        ..constant = true
        ..name = '_done'
        ..requiredParameters.add(
          Parameter((p) => p
            ..toThis = true
            ..name = 'result'),
        )
        ..initializers.addAll([
          for (final field in messageFields)
            refer('_${field.name}').assign(literalNull).code,
        ]),
    );
  }

  Iterable<Code> get _initializers sync* {
    for (final field in messageFields) {
      final type = field.type.accept(symbolVisitor);
      final needsConverter = _typeMap.containsKey(type.symbol);
      Expression assignment = refer(field.name);
      if (needsConverter) {
        assignment = _convert(assignment, type, isNullable: true);
      }
      yield refer('_${field.name}').assign(assignment).code;
    }

    yield refer('result').assign(literalNull).code;
  }

  Iterable<Field> get _fields sync* {
    for (final field in messageFields) {
      final ogType = field.type.accept(symbolVisitor);
      final type = _typeMap[ogType.symbol] ?? ogType;
      yield Field(
        (f) => f
          ..modifier = FieldModifier.final$
          ..type = type.nullable
          ..name = '_${field.name}',
      );
    }

    // Result field
    yield Field(
      (f) => f
        ..annotations.add(refer('override'))
        ..modifier = FieldModifier.final$
        ..type = resultType.nullable
        ..name = 'result',
    );
  }

  Iterable<Method> get _methods sync* {
    for (final field in messageFields) {
      final type = field.type.accept(symbolVisitor);
      final needsConversion = _typeMap.containsKey(type.symbol);
      Expression value = refer('_${field.name}').nullChecked;
      if (needsConversion) {
        value = _convert(
          value,
          _typeMap[type.symbol]!,
          isNullable: true,
        );
      }
      yield Method(
        (m) => m
          ..annotations.add(refer('override'))
          ..type = MethodType.getter
          ..name = field.name
          ..lambda = true
          ..returns = field.type.accept(symbolVisitor)
          ..body = value.code,
      );
    }
  }

  /// Isolate entrypoint.
  Method get _runner => Method.returnsVoid(
        (m) => m
          ..name = '_run'
          ..requiredParameters.add(Parameter((p) => p
            ..type = DartTypes.isolate.sendPort
            ..name = 'sendPort'))
          ..modifier = MethodModifier.async
          ..body = Code.scope((allocate) => '''
final channel = ${allocate(DartTypes.streamChannel.isolateChannel)}.connectSend(sendPort);
final result = await ${allocate(workerType)}.run(
  channel.stream, 
  channel.sink.transform(
    ${allocate(DartTypes.pkgAsync.streamSinkTranformer)}.fromHandlers(
      handleData: (${allocate(messageType)} data, ${allocate(DartTypes.async.eventSink)}<dynamic> sink) {
        print('(Worker) Sending message to main: \$data');
        sink.add(data);
      }
    )
  ),
);
print('(Worker) Finished with result: \$result');
${allocate(DartTypes.isolate.isolate)}.exit(sendPort, $messageTypeImplName._done(result));
            '''),
      );

  Class get _workerClass => Class((c) => c
    ..name = '${workerName}Impl'
    ..extend = workerType);
}
