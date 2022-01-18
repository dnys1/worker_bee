import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:worker_bee/worker_bee.dart';
import 'example.worker.dart';

abstract class MyMessage implements WorkerMessage<String> {
  factory MyMessage({
    required Uint8List data,
  }) = MyMessageImpl;

  @Transferable()
  Uint8List get data;
}

@WorkerBee()
abstract class MyWorker extends WorkerBeeBase<MyMessage, String> {
  MyWorker();
  factory MyWorker.create() = MyWorkerImpl;

  @NativeCall()
  String base64Encode(Uint8List data);

  @override
  Future<String> run(
    Stream<MyMessage> listen,
    StreamSink<MyMessage> respond,
  ) async {
    final messageToEncode = await listen.first;
    return base64Encode(messageToEncode.data);
  }
}
