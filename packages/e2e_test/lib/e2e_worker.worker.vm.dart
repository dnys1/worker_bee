import 'dart:core';
import 'dart:isolate';

import 'package:e2e_test/e2e_worker.dart';
import 'package:worker_bee/worker_bee.dart';

Future<void> _run(SendPort sendPort) async {
  final channel = IsolateChannel<E2EMessage>.connectSend(sendPort);
  final result = await E2EWorkerImpl().run(
    channel.stream,
    channel.sink,
  );
  safePrint('(Worker) Finished with result: $result');
  Isolate.exit(sendPort, result);
}

class E2EWorkerImpl extends E2EWorker {
  @override
  String get name => 'E2EWorker';
  @override
  VmEntrypoint get vmEntrypoint => _run;
}
