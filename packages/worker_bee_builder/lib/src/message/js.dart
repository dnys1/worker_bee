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
    return Library(
      (b) => b
        ..body.addAll([
          _messageClass,
          _topLevelDecls,
          _messageFromMap,
          _workerClass,
        ]),
    );
  }

  Class get _messageClass => Class(
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

  Code get _topLevelDecls => Code.scope((allocate) => '''
@${allocate(DartTypes.js.js)}()
external void postMessage(dynamic message);

@${allocate(DartTypes.js.js)}()
class JSON {
  external static String stringify(Object? object);
}
  ''');

  Method get _messageFromMap {
    final body = BlockBuilder();
    body.statements.add(
      Code.scope((allocate) => '''
    final result = map['result'] as ${allocate(resultType)}?;
    if (result != null) {
      return $messageTypeImplName._done(result: result);
    }
    '''),
    );
    final initializers = <String, Expression>{};
    for (final field in messageFields) {
      initializers[field.name] = refer('map')
          .index(literalString(field.name))
          .asA(field.type.accept(symbolVisitor));
    }
    body.addExpression(
      refer(messageTypeImplName).newInstance([], initializers).returned,
    );
    return Method(
      (m) => m
        ..returns = refer(messageTypeImplName)
        ..name = '_messageFromMap'
        ..requiredParameters.add(Parameter((p) => p
          ..name = 'map'
          ..type = refer('Map')))
        ..body = body.build(),
    );
  }

  Code get _connect => Code.scope((allocate) => '''
  print('(Worker) Connecting from worker...');
  final channel = ${allocate(DartTypes.streamChannel.streamChannelController)}<${allocate(messageType)}>();
  ${allocate(DartTypes.html.dedicatedWorkerGlobalScope)}.instance.addEventListener(
    'message', 
    (${allocate(DartTypes.html.event)} event) {
      event as ${allocate(DartTypes.html.messageEvent)};
      print('(Worker) Got message from main: \${event.data}');
      final Map map = event.data;
      final message = _messageFromMap(map);
      channel.foreign.sink.add(message);
    },
  );
  channel.foreign.stream.listen((message) {
    print('(Worker) Sending message to main: \${message.data}');
    postMessage(message);
  });
  print('(Worker) Sending ready event');
  postMessage('ready');
  final result = await run(
    channel.local.stream,
    channel.local.sink,
  );
  print('(Worker) Finished with result: \$result');
  postMessage($messageTypeImplName._done(result: result));
  ''');

  Code get _spawn => Code.scope((allocate) => '''
  print('(Main) Starting worker...');
  // Spawn the worker using the main script.
  final worker = ${allocate(DartTypes.html.worker)}('worker.dart.js');

  // Create the controller to handle message passing.
  final controller = ${allocate(DartTypes.async.streamController())}(
    sync: true,
    onCancel: () => worker.terminate(),
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
    print('(Main) Sending message to worker: \${message.data}');
    worker.postMessage(message, [message.data.buffer]);
  });

  // Listen to worker
  final incomingMessages = ${allocate(DartTypes.async.streamController())}(sync: true);
  worker.onMessage.listen((${allocate(DartTypes.html.messageEvent)} event) {
    print('(Main) Got message from worker: \${event.data}');
    if (event.data is String && event.data == 'ready') {
      print('(Main) Received ready event');
      ready.complete();
      return;
    }
    final data = event.data as Map;
    final message = _messageFromMap(data);
    if (message.result != null) {
      worker.terminate();
    }
    return incomingMessages.add(message);
  });

  channel = ${allocate(DartTypes.streamChannel.streamChannel)}(incomingMessages.stream, controller.sink);

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
          ]),
      );
}
