import 'package:worker_bee/worker_bee.dart';

import 'example.worker.vm.dart' if (dart.library.html) 'example.worker.js.dart';
import 'example.worker.dart' deferred as worker;

abstract class MyMessage {
  factory MyMessage({
    required String message,
  }) = MyMessageImpl;

  String get message;
}

@WorkerBee()
class MyWorker extends WorkerBeeBase<MyMessage, void> {
  @override
  Future<void> run() async {}
}
