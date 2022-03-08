import 'dart:async';

import 'package:built_value/serializer.dart';
import 'package:meta/meta.dart';
import 'package:stream_channel/stream_channel.dart';

/// {@template worker_bee.worker_bee_common}
/// The common (platform-agnostic) implementations for a worker bee.
///
/// The actual base class mixes in platform-specific code to this class.
/// {@endtemplate}
abstract class WorkerBeeCommon<Message extends Object, Result>
    with StreamChannelMixin<Message> {
  /// {@template worker_bee.worker_bee_common}
  WorkerBeeCommon([Serializers? serializers])
      : _serializers = serializers ?? Serializers() {
    _checkSerializers();
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

  /// The name of the worker.
  String get name;

  /// Serializers for message and result types.
  final Serializers _serializers;

  /// The top-level entrypoint for the VM.
  Function get vmEntrypoint => throw UnimplementedError();

  /// The script URL for the compiled workers.
  String get jsEntrypoint => throw UnimplementedError();

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
  Future<Result> run(Stream<Message> listen, StreamSink<Message> respond);

  /// Starts a remote worker and waits for it to connect.
  ///
  /// Optionally, you can override the [jsEntrypoint] for this call.

  /// Connects to a spawning thread.
  ///
  /// Should only be called from a worker bee.
  Future<void> connect();

  StreamChannel<Message>? _channel;

  /// The asynchronous ready trigger.
  @protected
  final Completer<void> ready = Completer();

  final Completer<Result> _resultCompleter = Completer();

  @protected
  void complete(Result result) => _resultCompleter.complete(result);

  @override
  StreamSink<Message> get sink {
    if (_channel == null) {
      throw StateError('Must call start first');
    }
    return _channel!.sink;
  }

  @override
  Stream<Message> get stream {
    if (_channel == null) {
      throw StateError('Must call start first');
    }
    return _channel!.stream;
  }

  /// Sets the stream channel for communication.
  @protected
  set channel(StreamChannel<Message> channel) {
    if (_channel != null) {
      throw StateError('Channel has already been set');
    }
    _channel = channel;
  }

  /// The result of the worker bee's computation.
  Future<Result> get result => _resultCompleter.future;
}
