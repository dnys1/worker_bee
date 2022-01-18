import 'dart:async';
import 'dart:html';
import 'dart:typed_data';

import 'package:example/example.dart';
import 'package:js/js.dart';
import 'package:meta/meta.dart';
import 'dart:core';

import 'package:worker_bee/worker_bee.dart';

@JS()
@anonymous
class MyMessageImpl implements MyMessage {
  external factory MyMessageImpl({
    required Uint8List data,
  });

  @internal
  external factory MyMessageImpl.done({
    required String result,
  });

  @override
  external Uint8List get data;

  @override
  external String? get result;
}

MyMessageImpl _myMessageImplFromMap(Map map) {
  final result = map['result'] as String?;
  if (result != null) {
    return MyMessageImpl.done(result: result);
  }
  return MyMessageImpl(data: map['data'] as Uint8List);
}

@JS()
external void postMessage(dynamic message);

@JS()
class JSON {
  external static String stringify(Object? object);
}

class MyWorkerImpl extends MyWorker {
  @override
  Future<void> start() async {
    print('(Main) Starting worker...');
    // Spawn the worker using the main script.
    final Worker worker = Worker('main.js');

    // Create the controller to handle message passing.
    final StreamController<MyMessage> controller = StreamController(
      sync: true,
      onCancel: () => worker.terminate(),
    );

    // Listen for error messages on the worker.
    worker.onError.listen((Event event) {
      print('(Main) Error from worker: ${JSON.stringify(event)}');
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
    // TODO: transferable
    controller.stream.listen((message) {
      print('(Main) Sending message to worker: ${message.data}');
      worker.postMessage(message, [message.data.buffer]);
    });

    // Listen to worker
    final incomingMessages = StreamController<MyMessage>(sync: true);
    worker.onMessage.listen((MessageEvent event) {
      print('(Main) Got message from worker: ${event.data}');
      if (event.data is String && event.data == 'ready') {
        print('(Main) Received ready event');
        ready.complete();
        return;
      }
      final data = event.data as Map;
      final message = _myMessageImplFromMap(data);
      if (message.result != null) {
        worker.terminate();
      }
      return incomingMessages.add(message);
    });

    channel = StreamChannel(incomingMessages.stream, controller.sink);

    // Send assignment
    worker.postMessage('example');

    await ready.future;
  }

  @override
  Future<void> connect() async {
    print('(Worker) Connecting from worker...');
    final channel = StreamChannelController<MyMessage>();
    WorkerGlobalScope.instance.addEventListener('message', (Event event) {
      event as MessageEvent;
      print('(Worker) Got message from main: ${event.data}');
      final Map map = event.data;
      final message = _myMessageImplFromMap(map);
      channel.foreign.sink.add(message);
    });
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
    postMessage(MyMessageImpl.done(result: result));
  }
}
