import 'dart:async';
import 'dart:core';
import 'dart:html';
import 'dart:typed_data';

import 'package:example/example.dart';
import 'package:js/js.dart';
import 'package:worker_bee/worker_bee.dart';

@JS()
@anonymous
class MyMessageImpl implements MyMessage {
  external factory MyMessageImpl({required Uint8List data});

  external factory MyMessageImpl._done({required String result});

  @override
  external Uint8List get data;
  @override
  external String? get result;
}

@JS()
external void postMessage(dynamic message);

@JS()
class JSON {
  external static String stringify(Object? object);
}

MyMessageImpl _messageFromMap(Map map) {
  final result = map['result'] as String?;
  if (result != null) {
    return MyMessageImpl._done(result: result);
  }

  return MyMessageImpl(data: (map['data'] as Uint8List));
}

class MyWorkerImpl extends MyWorker {
  @override
  Future<void> connect() async {
    print('(Worker) Connecting from worker...');
    final channel = StreamChannelController<MyMessage>();
    DedicatedWorkerGlobalScope.instance.addEventListener(
      'message',
      (Event event) {
        event as MessageEvent;
        print('(Worker) Got message from main: ${event.data}');
        final Map map = event.data;
        final message = _messageFromMap(map);
        channel.foreign.sink.add(message);
      },
    );
    channel.foreign.stream.listen((message) {
      print('(Worker) Sending message to main: ${message.data}');
      postMessage(message);
    });
    print('(Worker) Sending ready event');
    postMessage('ready');
    final result = await run(
      channel.local.stream,
      channel.local.sink,
    );
    print('(Worker) Finished with result: $result');
    postMessage(MyMessageImpl._done(result: result));
  }

  @override
  Future<void> spawn() async {
    print('(Main) Starting worker...');
    // Spawn the worker using the main script.
    final worker = Worker('worker.dart.js');

    // Create the controller to handle message passing.
    final controller = StreamController(
      sync: true,
      onCancel: () => worker.terminate(),
    );

    // Listen for error messages on the worker.
    worker.onError.listen((Event event) {
      print('(Main) Error from worker: $event');
      if (event is ErrorEvent) {
        controller.addError(WebWorkerException(
          event.message ?? JSON.stringify(event),
          filename: event.filename,
          lineNo: event.lineno,
        ));
      } else {
        controller.addError(WebWorkerException(JSON.stringify(event)));
      }
    });

    // Passes outgoing messages to the worker instance.
    controller.stream.listen((message) {
      print('(Main) Sending message to worker: ${message.data}');
      worker.postMessage(message, [message.data.buffer]);
    });

    // Listen to worker
    final incomingMessages = StreamController(sync: true);
    worker.onMessage.listen((MessageEvent event) {
      print('(Main) Got message from worker: ${event.data}');
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

    channel = StreamChannel(incomingMessages.stream, controller.sink);

    // Send assignment
    worker.postMessage('MyWorker');

    await ready.future;
  }
}
