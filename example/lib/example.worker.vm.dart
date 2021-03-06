import 'dart:async';
import 'dart:core';
import 'dart:isolate';

import 'package:example/example.dart';
import 'package:worker_bee/worker_bee.dart';

Future<void> _run(SendPorts ports) async {
  final channel = IsolateChannel<Object?>.connectSend(ports.messagePort);
  final logsChannel = IsolateChannel<LogMessage>.connectSend(ports.logPort);
  final worker = MyWorkerImpl();
  await worker.connect(logsChannel: logsChannel);
  final result = await worker.run(
    channel.stream.asBroadcastStream().cast(),
    channel.sink.cast(),
  );
// ignore: invalid_use_of_protected_member
  worker.logger.finest('Finished');
  unawaited(worker.close());
  Isolate.exit(ports.donePort, result);
}

/// The VM implementation of [MyWorker].
class MyWorkerImpl extends MyWorker {
  @override
  String get name => 'MyWorker';
  @override
  VmEntrypoint get vmEntrypoint => _run;
}
