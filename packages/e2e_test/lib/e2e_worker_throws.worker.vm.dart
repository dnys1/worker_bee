import 'dart:async';
import 'dart:core';
import 'dart:isolate';

import 'package:e2e_test/e2e_worker_throws.dart';
import 'package:worker_bee/worker_bee.dart';

Future<void> _run(SendPorts ports) async {
  final channel = IsolateChannel<Object?>.connectSend(ports.messagePort);
  final logsChannel = IsolateChannel<LogMessage>.connectSend(ports.logPort);
  final worker = E2EWorkerThrowsImpl();
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

/// The VM implementation of [E2EWorkerThrows].
class E2EWorkerThrowsImpl extends E2EWorkerThrows {
  @override
  String get name => 'E2EWorkerThrows';
  @override
  VmEntrypoint get vmEntrypoint => _run;
}
