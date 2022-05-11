import 'dart:async';

import 'package:worker_bee/worker_bee.dart';
import 'e2e_message.dart';
import 'e2e_worker_throws.worker.dart';

@WorkerBee()
abstract class E2EWorkerThrows extends WorkerBeeBase<E2EMessage, E2EResult> {
  E2EWorkerThrows() : super(serializers: serializers);
  factory E2EWorkerThrows.create() = E2EWorkerThrowsImpl;

  @override
  Future<E2EResult> run(
    Stream<E2EMessage> listen,
    StreamSink<E2EResult> respond,
  ) async {
    await listen.first;
    throw ':(';
  }
}
