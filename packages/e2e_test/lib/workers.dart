import 'package:e2e_test/e2e_worker.dart';
import 'package:worker_bee/worker_bee.dart';

part 'workers.g.dart';

@WorkerHive([
  E2EWorker,
])
void main() {
  runHive(workers);
}
