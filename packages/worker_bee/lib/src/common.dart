import 'dart:async';

import 'package:aws_common/aws_common.dart';
import 'package:built_value/serializer.dart';
import 'package:meta/meta.dart';
import 'package:worker_bee/src/serializers/serializers.dart';
import 'package:worker_bee/worker_bee.dart';

Type _typeOf<T>() => T;
final _voidType = _typeOf<void>();

/// {@template worker_bee.worker_bee_common}
/// The common (platform-agnostic) implementations for a worker bee.
///
/// The actual base class mixes in platform-specific code to this class.
/// {@endtemplate}
abstract class WorkerBeeCommon<Request extends Object, Response>
    implements StreamSink<Request>, Closeable {
  /// {@template worker_bee.worker_bee_common}
  WorkerBeeCommon({
    Serializers? serializers,
  }) : _serializers = serializers == null
            ? workerBeeSerializers
            : (serializers.toBuilder()
                  ..addAll(workerBeeSerializers.serializers))
                .build() {
    _checkSerializers();
    _initLogger();
  }

  // Check that a serializer for the request and response types are included.
  void _checkSerializers() {
    final hasRequestSerializer =
        _serializers.serializerForType(Request) != null;
    if (!hasRequestSerializer) {
      throw StateError(
        'Worker did not include serializer for request type ($Request)',
      );
    }

    final hasResponseSerializer =
        _serializers.serializerForType(Response) != null;
    // Cannot check `Response != void`
    if (Response != _voidType &&
        // TODO: No determination can be made when Response is nullable
        _typeOf<Response>() != _typeOf<Response?>() &&
        !hasResponseSerializer) {
      throw StateError(
        'Worker did not include serializer for response type ($Response)',
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
        isRemoteWorker ? name : 'Main',
        record,
        local: !isRemoteWorker,
      ));
    });
  }

  /// The name of the worker.
  String get name;

  bool _isRemoteWorker = false;

  /// Whether the worker is running on a separate thread.
  bool get isRemoteWorker => _isRemoteWorker;

  /// The internal-use logger.
  @protected
  late final Logger logger = Logger.detached(name);

  /// The logs sink, for outgoing messages (when in a worker).
  @protected
  final StreamSinkCompleter<LogMessage> logSink = StreamSinkCompleter();

  /// Configures logging for the worker.
  set _logsChannel(StreamChannel<LogMessage> channel) {
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
  WorkerSerializeResult serialize(Object? object) {
    final transfer = <Object>[];
    final serialized = runZoned(
      () => _serializers.serialize(
        object,
        // Do not specify type so that it is serialized into the array.
        specifiedType: FullType.unspecified,
      ),
      zoneValues: {
        #transfer: transfer,
      },
    );
    return WorkerSerializeResult(serialized, transfer);
  }

  /// Deserializes an object using the registered `built_value` serializers.
  @protected
  @optionalTypeArgs
  T deserialize<T extends Object?>(Object? object) {
    return _serializers.deserialize(
      object,
      // Do not specify type so that it pulls from the array.
      specifiedType: FullType.unspecified,
    ) as T;
  }

  /// Runs the worker in a separate thread/WebWorker.
  ///
  /// Listen to the spawning thread using [listen] and respond using [respond].
  ///
  /// > Should not be called directly! Use [spawn] to spawn a worker, and use [stream]
  /// > and [sink] to communicate with it.
  @protected
  Future<Response?> run(Stream<Request> listen, StreamSink<Response> respond);

  /// Starts a remote worker and waits for it to connect.
  ///
  /// Optionally, you can override the [jsEntrypoint] for this call.
  Future<void> spawn({String? jsEntrypoint});

  /// Connects to a spawning thread.
  ///
  /// Should only be called from a worker bee.
  @mustCallSuper
  Future<void> connect({
    StreamChannel<LogMessage>? logsChannel,
  }) async {
    _isRemoteWorker = true;
    logger.info('Connected from worker');
    if (logsChannel != null) {
      _logsChannel = logsChannel;
    }
  }

  /// The asynchronous ready trigger.
  @protected
  final Completer<void> ready = Completer();

  final StreamSinkCompleter<Request> _sinkCompleter = StreamSinkCompleter();
  final StreamCompleter<Response> _streamCompleter = StreamCompleter();
  final Completer<Result<Response?>> _resultCompleter = Completer.sync();

  /// Whether the worker bee has been completed and/or is closed.
  bool get isCompleted => _resultCompleter.isCompleted;

  /// Internal method for completing successfully with a result.
  @protected
  void complete(Response? result) {
    if (isCompleted) return;
    logger.fine('Finished with result: $result');
    _resultCompleter.complete(Result.value(result));
    close();
  }

  /// Internal method for completing with an error.
  @protected
  void completeError(Object error, [StackTrace? stackTrace]) {
    logger.severe('Error in worker', error, stackTrace);
    if (isCompleted) return;
    _resultCompleter.complete(Result.error(error, stackTrace));
    close();
  }

  late final Stream<Response> _stream =
      _streamCompleter.stream.asBroadcastStream();

  /// The stream of responses.
  Stream<Response> get stream => _stream;

  @protected
  set stream(Stream<Response> stream) {
    _streamCompleter.setSourceStream(stream);
  }

  /// The sink for requests.
  StreamSink<Request> get sink => _sinkCompleter.sink;

  @protected
  set sink(StreamSink<Request> sink) {
    _sinkCompleter.setDestinationSink(sink);
  }

  /// The result of the worker bee's computation.
  Future<Result<Response?>> get result => _resultCompleter.future;

  @override
  void add(Request event) => sink.add(event);

  @override
  void addError(Object error, [StackTrace? stackTrace]) =>
      sink.addError(error, stackTrace);

  @override
  Future<void> addStream(Stream<Request> stream) => sink.addStream(stream);

  @override
  @mustCallSuper
  Future<void> close() async {
    logger.info('Closing worker');
    await sink.close();
    await logsController.close();
  }

  @override
  Future<void> get done => sink.done;
}
