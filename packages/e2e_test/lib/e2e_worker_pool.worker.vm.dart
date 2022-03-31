import 'dart:core';
import 'dart:isolate';

import 'package:e2e_test/e2e_worker.dart';
import 'package:e2e_test/e2e_worker_pool.dart';
import 'package:worker_bee/worker_bee.dart';

Future<void> _run(SendPorts ports) async {
  final channel = IsolateChannel<Object>.connectSend(ports.messagePort);
  final logsChannel = IsolateChannel<LogMessage>.connectSend(ports.logPort);
  final worker = E2EWorkerPoolImpl()..setLogsChannel(logsChannel);
// ignore: invalid_use_of_protected_member
  worker.logger.info('Connected from worker');
  final result = await worker.run(
    channel.stream.asBroadcastStream().cast(),
    channel.sink.cast(),
  );
// ignore: invalid_use_of_protected_member
  worker.logger.info('Finished');
  Isolate.exit(ports.exitPort, result);
}

class E2EWorkerPoolImpl extends E2EWorkerPool {
  @override
  String get name => 'E2EWorkerPool';
  @override
  VmEntrypoint get vmEntrypoint => _run;
  @override
  E2EWorker Function() get factory => E2EWorker.create;
}
