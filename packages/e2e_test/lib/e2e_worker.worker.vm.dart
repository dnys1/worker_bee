import 'dart:async';
import 'dart:core';
import 'dart:isolate';

import 'package:e2e_test/e2e_worker.dart';
import 'package:worker_bee/worker_bee.dart';

Future<void> _run(SendPorts ports) async {
  final channel = IsolateChannel<Object>.connectSend(ports.messagePort);
  final logsChannel = IsolateChannel<LogMessage>.connectSend(ports.logPort);
  final worker = E2EWorkerImpl();
  await worker.connect(logsChannel: logsChannel);
  final result = await worker.run(
    channel.stream.asBroadcastStream().cast(),
    channel.sink.cast(),
  );
// ignore: invalid_use_of_protected_member
  worker.logger.info('Finished');
  unawaited(worker.close());
  Isolate.exit(ports.exitPort, result);
}

class E2EWorkerImpl extends E2EWorker {
  @override
  String get name => 'E2EWorker';
  @override
  VmEntrypoint get vmEntrypoint => _run;
}
