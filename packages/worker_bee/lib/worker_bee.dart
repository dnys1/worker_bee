///
library worker_bee;

import 'dart:async';

import 'package:async/async.dart';
import 'package:built_value/serializer.dart';
import 'package:worker_bee/src/common.dart';

import 'src/preamble.dart';
import 'src/vm/impl.dart' if (dart.library.html) 'src/js/impl.dart';

export 'package:async/async.dart';
export 'package:stream_transform/stream_transform.dart';
export 'src/exception/web_worker_exception.dart';
export 'src/exception/worker_bee_exception.dart' show WorkerBeeException;
export 'src/preamble.dart';
export 'src/util.dart';
export 'src/worker_bee_vm.dart' if (dart.library.html) 'src/worker_bee_js.dart';

/// {@template worker_bee.worker_bee}
/// Annotation class for marking worker bees.
///
/// ```dart
/// @WorkerBee()
/// class MyWorker extends WorkerBeeBase<MyMessage, void> {
///   @override
///   Future<void> run(Stream<MyMessage> listen, StreamSink<MyMessage> respond) async {
///     // ...
///   }
/// }
/// ```
/// {@endtemplate}
class WorkerBee {
  /// {@macro worker_bee.worker_bee}
  const WorkerBee([this.jsEntrypoint = 'main.dart.js']);

  /// The URL to load the web worker from.
  final String jsEntrypoint;
}

/// {@template worker_bee.worker_hive}
/// Annotation class for the `main` method which marks your workers' entrypoint,
/// i.e. the method you call [runHive] from.
///
/// ```dart
/// @WorkerHive([
///   MyWorker,
/// ])
/// void main() {
///   runHive(workers, () {});
/// }
/// ```
/// {@endtemplate}
class WorkerHive {
  /// {@macro worker_bee.worker_hive}
  const WorkerHive(this.workers);

  /// The list of worker bee types.
  final List<Type> workers;
}

/// {@template worker_bee.worker_bee_base}
/// The base class for all worker bees.
///
/// Classes annotated with [WorkerBee] must extend this class.
/// {@endtemplate}
abstract class WorkerBeeBase<Message extends Object, Result>
    extends WorkerBeeCommon<Message, Result>
    with WorkerBeeImpl<Message, Result> {
  /// {@macro worker_bee.worker_bee_base}

/// Helper for casting [StreamSink]s.
extension CastStreamSink<I> on StreamSink<I> {
  /// Casts the sink to another type.
  StreamSink<O> cast<O>() => transform(StreamSinkTransformer.fromHandlers());
}
