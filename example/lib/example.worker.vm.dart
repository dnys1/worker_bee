import 'dart:core';
import 'dart:isolate';

import 'package:example/example.dart';
import 'package:worker_bee/worker_bee.dart';

Future<void> _run(SendPorts ports) async {
  final channel = IsolateChannel<Object>.connectSend(ports.messagePort);
  final result = await MyWorkerImpl().run(
    channel.stream.cast(),
    channel.sink.cast(),
  );
  safePrint('(Worker) Finished with result: $result');
  Isolate.exit(ports.exitPort, result);
}

class MyWorkerImpl extends MyWorker {
  @override
  String get name => 'MyWorker';
  @override
  VmEntrypoint get vmEntrypoint => _run;
}
