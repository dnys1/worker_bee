class WebWorkerException implements Exception {
  const WebWorkerException(
    this.message, {
    this.filename,
    this.lineNo,
  });

  final String message;
  final String? filename;
  final int? lineNo;

  @override
  String toString() =>
      'WebWorkerException{$message' +
      (filename != null ? ' ($filename:$lineNo)' : '') +
      '}';
}
