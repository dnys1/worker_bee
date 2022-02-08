import 'package:analyzer/dart/element/element.dart';
import 'package:code_builder/code_builder.dart';
import 'package:worker_bee_builder/src/message/common.dart';
import 'package:worker_bee_builder/src/type_visitor.dart';
import 'package:worker_bee_builder/src/types.dart';

class JsGenerator extends MessageGenerator {
  JsGenerator(ClassElement classEl, ClassElement messageEl,
      ClassElement? resultTypeEl, this.entrypoint)
      : super(classEl, messageEl, resultTypeEl);

  final String entrypoint;

  @override
  Library generate() {
    return Library(
      (b) => b
        ..body.addAll([
          _topLevelDecls,
          _workerClass,
        ]),
    );
  }

  Code get _topLevelDecls => Code.scope((allocate) => '''
@${allocate(DartTypes.js.js)}()
class JSON {
  external static String stringify(Object? object);
}
  ''');

  Code get _connect => Code.scope((allocate) => '''
  print('(Worker) Connecting from worker...');
  final channel = ${allocate(DartTypes.streamChannel.streamChannelController)}<${allocate(messageType)}>();
  self.addEventListener(
    'message', 
    (${allocate(DartTypes.html.event)} event) {
      event as ${allocate(DartTypes.html.messageEvent)};
      print('(Worker) Got message from main: \${event.data}');
      final serialized = event.data as Object?;
      final message = deserialize<${allocate(messageType)}>(serialized);
      channel.foreign.sink.add(message);
    },
  );
  channel.foreign.stream.listen((message) {
    print('(Worker) Sending message to main: \${JSON.stringify(message)}');
    self.postMessage(serialize(message));
  });
  print('(Worker) Sending ready event');
  self.postMessage('ready');
  ${trueResultType.isVoid ? '' : 'final result ='} await run(
    channel.local.stream,
    channel.local.sink,
  );
  print('(Worker) Finished${trueResultType.isVoid ? '' : r" with result: $result"}');
  self.postMessage(${trueResultType.isVoid ? "'done'" : 'serialize(result)'});
  ''');

  Code get _spawn => Code.scope((allocate) => '''
  print('(Main) Starting worker...');
  // Spawn the worker using the main script.
  final worker = ${allocate(DartTypes.html.worker)}('$entrypoint');

  // Create the controller to handle message passing.
  // ignore: close_sinks
  final controller = ${allocate(DartTypes.async.streamController())}<${allocate(messageType)}>(
    sync: true,
    onCancel: worker.terminate,
  );

  // Listen for error messages on the worker.
  worker.onError.listen((${allocate(DartTypes.html.event)} event) {
    print('(Main) Error from worker: \$event');
    if (event is ${allocate(DartTypes.html.errorEvent)}) {
      controller.addError(${allocate(DartTypes.workerBee.webWorkerException)}(
        event.message ?? JSON.stringify(event),
        filename: event.filename,
        lineNo: event.lineno,
      ));
    } else {
      controller.addError(${allocate(DartTypes.workerBee.webWorkerException)}(JSON.stringify(event)));
    }
  });

  // Passes outgoing messages to the worker instance.
  controller.stream.listen((message) {
    print('(Main) Sending message to worker: \${JSON.stringify(message)}');
    worker.postMessage(serialize(message)); // TODO: Transferable
  });

  // Listen to worker
  // ignore: close_sinks
  final incomingMessages = ${allocate(DartTypes.async.streamController())}<${allocate(messageType)}>(sync: true);
  worker.onMessage.listen((${allocate(DartTypes.html.messageEvent)} event) {
    print('(Main) Got message from worker: \${event.data}');
    if (event.data is String && event.data == 'ready') {
      print('(Main) Received ready event');
      ready.complete();
      return;
    }
    final serialized = event.data as Object?;
    final message = deserialize(serialized);
    if (message is ${allocate(messageType)}) {
      incomingMessages.add(message);
    } else {
      final result = message as ${allocate(resultType)};
      complete(result);
      worker.terminate();
    }
  });

  channel = ${allocate(DartTypes.streamChannel.streamChannel)}<${allocate(messageType)}>(incomingMessages.stream, controller.sink);

  // Send assignment
  worker.postMessage('$workerName');

  await ready.future;
  ''');

  Class get _workerClass => Class(
        (c) => c
          ..name = workerImplName
          ..extend = workerType
          ..methods.addAll([
            Method((m) => m
              ..annotations.add(DartTypes.core.override)
              ..returns = DartTypes.async.future(DartTypes.core.void$)
              ..name = 'connect'
              ..modifier = MethodModifier.async
              ..body = _connect),
            Method((m) => m
              ..annotations.add(DartTypes.core.override)
              ..returns = DartTypes.async.future(DartTypes.core.void$)
              ..name = 'spawn'
              ..modifier = MethodModifier.async
              ..body = _spawn),
          ])
          ..fields.addAll([
            Field(
              (f) => f
                ..static = true
                ..modifier = FieldModifier.final$
                ..name = 'self'
                ..assignment = DartTypes.html.dedicatedWorkerGlobalScope
                    .property('instance')
                    .code,
            ),
          ]),
      );
}
