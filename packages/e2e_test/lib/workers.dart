import 'package:e2e_test/e2e_worker.dart';
import 'package:e2e_test/e2e_worker_pool.dart';
import 'package:worker_bee/worker_bee.dart';

part 'workers.g.dart';

@WorkerHive([
  E2EWorker,
  E2EWorkerPool,
])
void main() {
  runHive(workers);
}
