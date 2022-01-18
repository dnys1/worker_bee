/// Support for doing something awesome.
///
/// More dartdocs go here.
library worker_bee;

import 'dart:async';

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
  const WorkerBee();
}

/// Annotation class for worker message types which should be transferred.
class Transferable {
  const Transferable();
}

/// Annotation class for native (WASM/FFI) call.
class NativeCall {
  const NativeCall();
}

/// A message type for communication between workers.
abstract class WorkerMessage<R> {
  // List<Object?> get transferable;

  R? get result;
}

abstract class WorkerBeeBase<M extends WorkerMessage<R>, R>
    with StreamChannelMixin {
  /// Should not be called directly! Use [start] to spawn a worker, and use [stream]
  /// and [sink] to communicate with it.
  ///
  /// Runs the worker in a separate thread/WebWorker.
  ///
  /// Listen to the spawning thread using [listen] and respond using [respond].
  @protected
  Future<R> run(Stream<M> listen, StreamSink<M> respond);

  Future<void> start();

  Future<void> connect();

  StreamChannel? _channel;

  @protected
  final Completer<void> ready = Completer();

  @override
  StreamSink get sink {
    if (_channel == null) {
      throw StateError('Must call start first');
    }
    return _channel!.sink;
  }

  @override
  Stream get stream {
    if (_channel == null) {
      throw StateError('Must call start first');
    }
    return _channel!.stream;
  }

  @protected
  set channel(StreamChannel channel) {
    if (_channel != null) {
      throw StateError('Channel has already been set');
    }
    _channel = channel;
  }
}
