/// Multi-platform workers for Dart (Web, VM).
library worker_bee;

import 'dart:async';

import 'package:async/async.dart';
import 'package:built_value/serializer.dart';
import 'package:worker_bee/src/common.dart';

import 'src/preamble.dart';
import 'src/vm/impl.dart' if (dart.library.js) 'src/js/impl.dart';

export 'package:async/async.dart';
export 'package:logging/logging.dart';
export 'package:stream_transform/stream_transform.dart';
export 'src/exception/worker_bee_exception.dart' show WorkerBeeException;
export 'src/logger/log_message.dart';
export 'src/pool/assignment_strategy.dart';
export 'src/pool/worker_pool.dart';
export 'src/preamble.dart' hide runTraced;
export 'src/worker_bee_vm.dart' if (dart.library.js) 'src/worker_bee_js.dart';

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
  const WorkerBee([
    this.jsEntrypoint = 'main.dart.js',
    this.fallbackUrls = const [],
  ]);

  /// The URL to load the web worker from.
  final String jsEntrypoint;

  /// The URLs to try if loading [jsEntrypoint] fails.
  final List<String> fallbackUrls;
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
abstract class WorkerBeeBase<Request extends Object, Response>
    extends WorkerBeeCommon<Request, Response>
    with WorkerBeeImpl<Request, Response> {
  /// {@macro worker_bee.worker_bee_base}
  WorkerBeeBase({
    Serializers? serializers,
  }) : super(serializers: serializers);
}

/// Helper for casting [StreamSink]s.
extension CastStreamSink<I> on StreamSink<I> {
  /// Casts the sink to another type.
  StreamSink<O> cast<O>() => transform(StreamSinkTransformer.fromHandlers());
}
