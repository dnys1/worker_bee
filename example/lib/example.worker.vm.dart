import 'dart:core';
import 'dart:isolate';

import 'package:example/example.dart';
import 'package:worker_bee/worker_bee.dart';

Future<void> _run(SendPort sendPort) async {
  final channel = IsolateChannel<MyMessage>.connectSend(sendPort);
  final result = await MyWorkerImpl().run(
    channel.stream,
    channel.sink,
  );
  safePrint('(Worker) Finished with result: $result');
  Isolate.exit(sendPort, result);
}

class MyWorkerImpl extends MyWorker {
  @override
  String get name => 'MyWorker';
  @override
  VmEntrypoint get vmEntrypoint => _run;
}
