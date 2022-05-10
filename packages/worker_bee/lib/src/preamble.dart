import 'dart:async';

import 'package:meta/meta.dart';
import 'package:stack_trace/stack_trace.dart';
import 'package:worker_bee/src/exception/worker_bee_exception.dart';
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

/// Runs [action] in an error zone and automatically handles serialization
/// of unhandled errors.
@internal
R runChained<R>(
  R Function() action, {
  required void Function(WorkerBeeException, StackTrace) onError,
}) {
  return Chain.capture(
    action,

    // Since this could be called from within a worker, e.g. in the case
    // of a worker pool, any uncaught errors lose visibility when they're
    // reported back _unless_ we serialize them first.
    onError: (Object error, Chain stackTrace) {
      final workerException = error is WorkerBeeException
          ? error.rebuild((b) => b.stackTrace = stackTrace)
          : WorkerBeeExceptionImpl(error, stackTrace);
      onError(workerException, stackTrace);
    },
  );
}
