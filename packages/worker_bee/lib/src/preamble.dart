import 'dart:async';

import 'package:worker_bee/worker_bee.dart';

export 'vm/preamble.dart' if (dart.library.html) 'js/preamble.dart';

/// {@template worker_bee.worker_assignment}
/// The worker bee assignment sent from the main thread.
/// {@endtemplate}
class WorkerAssignment {
  /// {@macro worker_bee.worker_assignment}
  const WorkerAssignment(this.role, this.logsChannel);

  /// The name of the worker bee to be spawned.
  final String role;

  /// The log channel to communicate over.
  final StreamChannel<LogMessage> logsChannel;
}

/// Factory for a worker bee.
typedef WorkerBeeBuilder<W extends WorkerBeeBase<Object, dynamic>> = W
    Function();

/// Initializes worker bees by checking if running in a web worker, and awaiting
/// the assigned role if so.
///
/// This only needs to be used when targeting Web. It is a no-op on VM.
Future<void> runHive<R>(
  Map<String, WorkerBeeBuilder> workers, [
  FutureOr<void> Function()? runApp,
]) async {
  if (isWebWorker) {
    final assignment = await getWorkerAssignment();
    final worker = workers[assignment.role];
    if (worker == null) {
      throw StateError('No worker found for role: $assignment');
    }
    await worker().connect(logsChannel: assignment.logsChannel);
  } else {
    await runApp?.call();
  }
}
