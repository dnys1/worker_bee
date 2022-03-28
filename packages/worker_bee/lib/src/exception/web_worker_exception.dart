import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:worker_bee/src/exception/worker_bee_exception.dart';

part 'web_worker_exception.g.dart';

/// {@template worker_bee.web_worker_exception}
/// An exception encountered in a web worker.
/// {@endtemplate}
abstract class WebWorkerException
    implements
        WorkerBeeException,
        Built<WebWorkerException, WebWorkerExceptionBuilder> {
  /// {@macro worker_bee.web_worker_exception}
  factory WebWorkerException(
    Object error, {
    StackTrace? stackTrace,
    String? filename,
    int? lineNo,
  }) =>
      _$WebWorkerException(
        (b) => b
          ..error = error.toString()
          ..stackTrace = stackTrace
          ..filename = filename
          ..lineNo = lineNo,
      );
  WebWorkerException._();

  /// The filename where the error occurred.
  String? get filename;

  /// The line number where the error occurred.
  int? get lineNo;

  /// The [WebWorkerException] serializer.
  static Serializer<WebWorkerException> get serializer =>
      _$webWorkerExceptionSerializer;

  @override
  String toString() =>
      'WebWorkerException{$error' +
      (filename != null ? ' ($filename:$lineNo)' : '') +
      '}';
}
