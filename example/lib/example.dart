import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:worker_bee/worker_bee.dart';
import 'example.worker.dart';
import 'serializers.dart';

@WorkerBee()
abstract class MyWorker extends WorkerBeeBase<Uint8List, String> {
  MyWorker() : super(serializers: serializers);
  factory MyWorker.create() = MyWorkerImpl;

  @override
  Future<String?> run(
    Stream<Uint8List> listen,
    StreamSink<String> respond,
  ) async {
    await for (final message in listen) {
      respond.add(base64Encode(message));
    }
    return null;
  }
}
