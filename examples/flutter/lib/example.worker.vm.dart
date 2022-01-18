import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:flutter_example/example.dart';

import 'package:worker_bee/worker_bee.dart';

class MyMessageImpl implements MyMessage {
  MyMessageImpl({
    required Uint8List data,
  })  : _data = TransferableTypedData.fromList([data]),
        result = null;

  MyMessageImpl.done(this.result) : _data = null;

  final TransferableTypedData? _data;

  @override
  Uint8List get data => _data!.materialize().asUint8List();

  @override
  final String? result;
}

void _run(SendPort sendPort) async {
  final channel = IsolateChannel.connectSend(sendPort);
  final result = await MyWorkerImpl().run(
    channel.stream.cast()
      ..tap((message) {
        print('(Worker) Got message from main: $message');
      }),
    channel.sink.transform(
      StreamSinkTransformer.fromHandlers(
        handleData: (MyMessage data, EventSink<dynamic> sink) {
          print('(Worker) Sending message to main: $data');
          sink.add(data);
        },
      ),
    ),
  );
  print('(Worker) Finished with result: $result');
  Isolate.exit(sendPort, MyMessageImpl.done(result));
}

class MyWorkerImpl extends MyWorker {
  @override
  Future<void> connect() async {}

  @override
  Future<void> start() async {
    print('(Main) Starting worker...');
    final receivePort = ReceivePort();
    channel = IsolateChannel.connectReceive(receivePort);

    stream.tap((message) {
      print('(Main) Got message from worker: $message');
    });

    await Isolate.spawn(_run, receivePort.sendPort);
  }
}
