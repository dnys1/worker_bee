import 'dart:async';

import 'package:worker_bee/worker_bee.dart';

import 'vm/preamble.dart' if (dart.library.html) 'js/preamble.dart';

/// Factory for a worker bee.

/// Initializes worker bees by checking if running in a web worker, and awaiting
/// the assigned role if so.
///
/// This only needs to be used when targeting Web. It is a no-op on VM.
Future<void> runHive<R>(
  Map<String, WorkerBeeBuilder> workers,
  FutureOr<void> Function() runApp,
) async {
  if (isWebWorker) {
    print('(Worker) Getting assignment...');
    final assignment = await getWorkerAssignment();
    final worker = workers[assignment];
    if (worker == null) {
      throw StateError('No worker found for role: $assignment');
    }
    await worker().connect();
  } else {
    print('(Main) Not a web worker. Running app...');
    await runApp();
  }
}

class WorkerBeeConfig {
  const WorkerBeeConfig(this.workerBees);

  final Map<String, Future<void> Function()> workerBees;
}
