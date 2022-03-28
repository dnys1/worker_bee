import 'package:worker_bee/worker_bee.dart';
import 'e2e_worker_pool.worker.dart';

import 'e2e_worker.dart';

const numWorkers = 5;

@WorkerBee()
abstract class E2EWorkerPool
    extends WorkerPoolBase<E2EMessage, E2EResult, E2EWorker> {
  E2EWorkerPool() : super(numWorkers, serializers: serializers);
  factory E2EWorkerPool.create() = E2EWorkerPoolImpl;
}
