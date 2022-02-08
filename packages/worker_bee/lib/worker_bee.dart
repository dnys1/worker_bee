/// Support for doing something awesome.
///
/// More dartdocs go here.
library worker_bee;

import 'dart:async';

import 'package:async/async.dart';
import 'package:aws_common/aws_common.dart';
import 'package:built_value/serializer.dart';
import 'package:meta/meta.dart';
import 'package:stream_channel/stream_channel.dart';

export 'package:async/async.dart';
export 'package:stream_transform/stream_transform.dart';
export 'src/worker_bee_vm.dart' if (dart.library.html) 'src/worker_bee_js.dart';
export 'src/exception.dart';
export 'src/preamble.dart';

/// Annotation class for marking worker bees.
///
/// ```dart
/// @WorkerBee()
/// class MyWorker extends WorkerBeeBase<MyMessage, void> {
///   @override
///   Future<void> run(Stream<MyMessage> listen, StreamSink<MyMessage> respond) async {
///     // TODO
///   }
/// }
/// ```
class WorkerBee {
  const WorkerBee([this.jsEntrypoint = 'main.dart.js']);

  /// The URL to load the web worker from.
  final String jsEntrypoint;
}

class WorkerHive {
  const WorkerHive(this.workers);

  final List<Type> workers;
}

/// Annotation class for worker message types which should be transferred.
class Transferable {
  const Transferable();
}

/// Annotation class for native (WASM/FFI) call.
class NativeCall {
  const NativeCall({
    required this.wasmPath,
    required this.ffiLibrary,
  });

  final String wasmPath;
  final String ffiLibrary;
}

abstract class WorkerBeeBase<Message, Result> with StreamChannelMixin<Message> {
  WorkerBeeBase(this._serializers);

  /// Serializers for message and result types.
  final Serializers _serializers;

  @protected
  Object? serialize(Object? object) {
    return _serializers.serialize(object);
  }

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
  Future<void> spawn();

  /// Connects to a spawning thread.
  ///
  /// Should only be called from a worker bee.
  Future<void> connect();

  StreamChannel<Message>? _channel;

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

  @protected
  set channel(StreamChannel<Message> channel) {
    if (_channel != null) {
      throw StateError('Channel has already been set');
    }
    _channel = channel;
  }

  Future<Result> get result => _resultCompleter.future;
}
