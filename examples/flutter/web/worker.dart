import 'package:flutter_example/example.dart' deferred as example_worker;
import 'package:worker_bee/worker_bee.dart';

final workers = <String, Future<void> Function()>{
  'example': () async {
    await example_worker.loadLibrary();
    await example_worker.MyWorker.create().connect();
  }
};

void main() {
  runHive(workers, () {});
}
