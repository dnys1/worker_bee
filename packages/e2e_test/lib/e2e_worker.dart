import 'dart:async';

import 'package:worker_bee/worker_bee.dart';
import 'e2e_message.dart';
import 'e2e_worker.worker.dart';

@WorkerBee()
abstract class E2EWorker extends WorkerBeeBase<E2EMessage, E2EResult> {
  E2EWorker() : super(serializers: serializers);
  factory E2EWorker.create() = E2EWorkerImpl;

  @override
  Future<E2EResult> run(
    Stream<E2EMessage> listen,
    StreamSink<E2EResult> respond,
  ) async {
    final event = await listen.first;
    final result = E2EResult((b) => b.message.replace(event));
    respond.add(result);

    // Complete with a result
    return E2EResult((b) => b.message.replace(message));
  }
}
