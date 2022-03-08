/// {@template worker_bee.web_worker_exception}
/// An exception encountered in a web worker.
/// {@endtemplate}
class WebWorkerException implements Exception {
  /// {@macro worker_bee.web_worker_exception}
  const WebWorkerException(
    this.message, {
    this.filename,
    this.lineNo,
  });

  /// The error's message.
  final String message;

  /// The filename where the error occurred.
  final String? filename;

  /// The line number where the error occurred.
  final int? lineNo;

  @override
  String toString() =>
      'WebWorkerException{$message' +
      (filename != null ? ' ($filename:$lineNo)' : '') +
      '}';
}
