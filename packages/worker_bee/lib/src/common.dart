import 'dart:async';

import 'package:async/async.dart' as async;
import 'package:built_value/serializer.dart';
import 'package:meta/meta.dart';
import 'package:worker_bee/src/exception/stack_trace_serializer.dart';
import 'package:worker_bee/src/exception/worker_bee_exception.dart';
import 'package:worker_bee/worker_bee.dart';

/// {@template worker_bee.worker_bee_common}
/// The common (platform-agnostic) implementations for a worker bee.
///
/// The actual base class mixes in platform-specific code to this class.
/// {@endtemplate}
abstract class WorkerBeeCommon<Message extends Object, Result>
    implements StreamSink<Message> {
  /// {@template worker_bee.worker_bee_common}
  WorkerBeeCommon({
    Serializers? serializers,
  }) : _serializers = ((serializers ?? Serializers()).toBuilder()
              ..add(WebWorkerException.serializer)
              ..add(WorkerBeeExceptionImpl.serializer)
              ..add(const StackTraceSerializer())
              ..add(LogMessage.serializer))
            .build() {
    _checkSerializers();
    _initLogger();
  }

  // Check that a serializer for the message type is included.
  void _checkSerializers() {
    final hasMessageSeralizer = _serializers.serializerForType(Message) != null;
    if (!hasMessageSeralizer) {
      throw StateError(
        'Worker did not include serializer for message type ($Message)',
      );
    }
  }

  /// Listens for local messages.
  void _initLogger() {
    logger.level = Level.ALL;
    logger.onRecord.listen((record) {
      logSink.sink.add(LogMessage.fromRecord(
        name,
        record,
        local: false,
      ));
      if (logsController.isClosed) return;
      logsController.add(LogMessage.fromRecord(
        isWebWorker ? name : 'Main',
        record,
        local: !isWebWorker,
      ));
    });
  }

  /// The name of the worker.
  String get name;

  /// The internal-use logger.
  @protected
  late final Logger logger = Logger.detached(name);

  /// The logs sink, for outgoing messages (when in a worker).
  @protected
  final StreamSinkCompleter<LogMessage> logSink = StreamSinkCompleter();

  /// Configures logging for the worker.
  void setLogsChannel(StreamChannel<LogMessage> channel) {
    logSink.setDestinationSink(channel.sink);

    // Incoming messages (from the worker) should be logged locally
    channel.stream.listen((log) {
      if (logsController.isClosed) return;
      logsController.add(log);
    });
  }

  /// The log stream for external listening.
  @protected
  final StreamController<LogMessage> logsController =
      StreamController.broadcast(sync: true);

  /// The logger to use for all messages.
  Stream<LogMessage> get logs => logsController.stream;

  /// Serializers for message and result types.
  final Serializers _serializers;

  /// The top-level entrypoint for the VM.
  Function get vmEntrypoint => throw UnimplementedError();

  /// The script URL for the compiled workers.
  String get jsEntrypoint => throw UnimplementedError();

  /// {@template worker_bee.worker_entrypoint_override}
  /// The alternative entrypoint used to spawn workers in the pool.
  ///
  /// If this pool manager was spawned in a web worker with a different
  /// entrypoint than [jsEntrypoint], use that to also spawn workers since
  /// it's not possible to relay that information otherwise.
  /// {@endtemplate}
  String? get workerEntrypointOverride;

  /// Serializes an object using the registered `built_value` serializers.
  @protected
  Object? serialize(Object? object) {
    return _serializers.serialize(object);
  }

  /// Deserializes an object using the registered `built_value` serializers.
  @protected
  T deserialize<T extends Object?>(Object? object) {
    return _serializers.deserialize(object) as T;
  }

  /// Runs the worker in a separate thread/WebWorker.
  ///
  /// Listen to the spawning thread using [listen] and respond using [respond].
  ///
  /// > Should not be called directly! Use [spawn] to spawn a worker, and use [stream]
  /// > and [sink] to communicate with it.
  @protected
  Future<Result> run(Stream<Message> listen, StreamSink<Result> respond);

  /// Starts a remote worker and waits for it to connect.
  ///
  /// Optionally, you can override the [jsEntrypoint] for this call.
  Future<void> spawn({String? jsEntrypoint});

  /// Connects to a spawning thread.
  ///
  /// Should only be called from a worker bee.
  Future<void> connect();

  /// The asynchronous ready trigger.
  @protected
  final Completer<void> ready = Completer();

  final StreamSinkCompleter<Message> _sinkCompleter = StreamSinkCompleter();
  final StreamCompleter<Result> _streamCompleter = StreamCompleter();
  final Completer<async.Result<Result>> _resultCompleter = Completer.sync();

  /// Whether the worker bee has been completed and/or is closed.
  bool get isCompleted => _resultCompleter.isCompleted;

  /// Internal method for completing successfully with a result.
  @protected
  void complete(Result result) {
    if (!isCompleted) {
      _resultCompleter.complete(async.Result.value(result));
    }
    close();
  }

  /// Internal method for completing with an error.
  @protected
  void completeError(Object error, [StackTrace? stackTrace]) {
    if (!isCompleted) {
      _resultCompleter.complete(async.Result.error(error, stackTrace));
    }
    close();
  }

  late final Stream<Result> _stream =
      _streamCompleter.stream.asBroadcastStream();

  /// The stream of responses.
  Stream<Result> get stream => _stream;

  @protected
  set stream(Stream<Result> stream) {
    _streamCompleter.setSourceStream(stream);
  }

  /// The sink for requests.
  StreamSink<Message> get sink => _sinkCompleter.sink;

  @protected
  set sink(StreamSink<Message> sink) {
    _sinkCompleter.setDestinationSink(sink);
  }

  /// The result of the worker bee's computation.
  Future<async.Result<Result>> get result => _resultCompleter.future;

  @override
  void add(Message event) => sink.add(event);

  @override
  void addError(Object error, [StackTrace? stackTrace]) =>
      sink.addError(error, stackTrace);

  @override
  Future<void> addStream(Stream<Message> stream) => sink.addStream(stream);

  final _closeMemoizer = AsyncMemoizer<void>();

  @override
  @mustCallSuper
  Future<void> close() {
    // Multiple calls to the memoizer in the same event loop causes this to
    // throw a StateError.
    //
    // Call in the next event loop to avoid.
    return Future(() => _closeMemoizer.runOnce(() async {
          logger.info('Closing worker');
          await sink.close();
          await logsController.close();
        }));
  }

  @override
  Future<void> get done => sink.done;
}
