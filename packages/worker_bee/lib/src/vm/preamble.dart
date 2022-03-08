/// {@template worker_bee.is_web_worker}
/// Whether the current script is running inside a web worker.
///
/// Always returns `false` on VM.
/// {@endtemplate}
bool get isWebWorker => false;

/// {@template worker_bee.get_worker_assignment}
/// Awaits assignment from the main process.
///
/// Should not be called on VM.
/// {@endtemplate}
Future<String> getWorkerAssignment() async {
  throw UnimplementedError('Should not be called on VM');
}
