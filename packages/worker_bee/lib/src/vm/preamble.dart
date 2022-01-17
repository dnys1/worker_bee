/// Whether the current script is running inside a web worker.
///
/// Always returns false on VM.
bool get isWebWorker => false;

/// Awaits assignment from the main process.
///
/// Should not be called on VM.
Future<String> getWorkerAssignment() async {
  throw UnimplementedError('Should not be called on VM');
}
