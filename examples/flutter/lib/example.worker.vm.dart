import 'dart:async';
import 'dart:core';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:flutter_example/example.dart';
import 'package:worker_bee/worker_bee.dart';

class MyMessageImpl implements MyMessage {
  MyMessageImpl({required Uint8List data})
      : _data = TransferableTypedData.fromList([data]),
        result = null;

  const MyMessageImpl._done(this.result) : _data = null;

  final TransferableTypedData? _data;

  @override
  final String? result;

  @override
  Uint8List get data => _data!.materialize().asUint8List();
}

void _run(SendPort sendPort) async {
  final channel = IsolateChannel<Object>.connectSend(sendPort);
  final result = await MyWorkerImpl().run(
    channel.stream.cast(),
    channel.sink.transform(StreamSinkTransformer.fromHandlers(
        handleData: (MyMessage data, EventSink<dynamic> sink) {
      print('(Worker) Sending message to main: $data');
      sink.add(data);
    })),
  );
  print('(Worker) Finished with result: $result');
  Isolate.exit(sendPort, MyMessageImpl._done(result));
}

class MyWorkerImpl extends MyWorker {
  @override
  Future<void> connect() async {}
  @override
  Future<void> spawn() async {
    print('(Main) Starting worker...');
    final receivePort = ReceivePort();
    channel = IsolateChannel<Object>.connectReceive(receivePort);
    await Isolate.spawn(_run, receivePort.sendPort);
  }
}
