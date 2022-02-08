import 'package:analyzer/dart/element/element.dart';
import 'package:code_builder/code_builder.dart';
import 'package:worker_bee_builder/src/message/common.dart';
import 'package:worker_bee_builder/src/type_visitor.dart';
import 'package:worker_bee_builder/src/types.dart';

class VmGenerator extends MessageGenerator {
  VmGenerator(
    ClassElement classEl,
    ClassElement messageEl,
    ClassElement? resultTypeEl,
  ) : super(classEl, messageEl, resultTypeEl);

  @override
  Library generate() {
    return Library(
      (b) => b
        ..body.addAll([
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

  /// Isolate entrypoint.
  Method get _runner => Method(
        (m) => m
          ..name = '_run'
          ..returns = DartTypes.async.future(DartTypes.core.void$)
          ..requiredParameters.add(Parameter((p) => p
            ..type = DartTypes.isolate.sendPort
            ..name = 'sendPort'))
          ..modifier = MethodModifier.async
          ..body = Code.scope((allocate) => '''
final channel = ${allocate(DartTypes.streamChannel.isolateChannel)}<${allocate(messageType)}>.connectSend(sendPort);
${trueResultType.isVoid ? '' : 'final result ='} await $workerImplName().run(
  channel.stream, 
  channel.sink,
);
print('(Worker) Finished${trueResultType.isVoid ? '' : r" with result: $result"}');
${allocate(DartTypes.isolate.isolate)}.exit(sendPort, ${trueResultType.isVoid ? "'done'" : 'result'});
            '''),
      );

  Class get _workerClass => Class(
        (c) => c
          ..name = workerImplName
          ..extend = workerType
          ..methods.addAll([
            Method((m) => m
              ..annotations.add(DartTypes.core.override)
              ..returns = DartTypes.workerBee.vmEntrypoint
              ..type = MethodType.getter
              ..name = 'vmEntrypoint'
              ..body = refer('_run').code),
          ]),
      );
}
