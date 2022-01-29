import 'dart:async';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html';
import 'dart:typed_data';

import 'package:js/js_util.dart';
import 'package:native_example/example.dart';
import 'package:js/js.dart';
import 'package:meta/meta.dart';

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

@JS('wasm_bindgen')
external Object _wasm_bindgen(String path);
Future<void> wasm_bindgen(String path) => promiseToFuture(_wasm_bindgen(path));

@JS('wasm_bindgen.base64_encode_wasm')
external String base64_encode_wasm(Uint8List data);

class MyWorkerImpl extends MyWorker {
  static final self = DedicatedWorkerGlobalScope.instance;

  @override
  Future<void> spawn() async {
    print('(Main) Starting worker...');
    // Spawn the worker using the main script.
    final Worker worker = Worker('worker.dart.js');

    // Create the controller to handle message passing.
    final StreamController controller = StreamController(
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
  String base64Encode(Uint8List data) {
    return base64_encode_wasm(data);
  }

  @override
  Future<void> connect() async {
    self.importScripts('/wasm/native_lib.js');
    await wasm_bindgen('/wasm/native_lib_bg.wasm');
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
