import 'dart:async';

import 'vm/preamble.dart' if (dart.library.html) 'js/preamble.dart';

/// Initializes worker bees by checking if running in a web worker, and awaiting
/// the assigned role if so.
Future<void> runHive<R>(
  Map<String, Future<void> Function()> workers,
  FutureOr<void> Function() runApp,
) async {
  if (isWebWorker) {
    print('(Worker) Getting assignment...');
    final assignment = await getWorkerAssignment();
    final runner = workers[assignment];
    if (runner == null) {
      throw StateError('No worker found for role: $assignment');
    }
    await runner();
  } else {
    print('(Main) Not a web worker. Running app...');
    await runApp();
  }
}

class WorkerBeeConfig {
  const WorkerBeeConfig(this.workerBees);

  final Map<String, Future<void> Function()> workerBees;
}
