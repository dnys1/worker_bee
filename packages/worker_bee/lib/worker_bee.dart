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

class Hive {
  const Hive(this.workers);

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

/// A message type for communication between workers.
abstract class WorkerMessage<R> {
  R? get result;
}

abstract class WorkerBeeBase<M extends WorkerMessage<R>, R>
    with StreamChannelMixin {
  /// Runs the worker in a separate thread/WebWorker.
  ///
  /// Listen to the spawning thread using [listen] and respond using [respond].
  ///
  /// > Should not be called directly! Use [spawn] to spawn a worker, and use [stream]
  /// > and [sink] to communicate with it.
  @protected
  Future<R> run(Stream<M> listen, StreamSink<M> respond);

  /// Starts a remote worker and waits for it to connect.
  Future<void> spawn();

  /// Connects to a spawning thread.
  ///
  /// Should only be called from a worker bee.
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

  Future<R> get result async {
    final msg = await stream.cast<M>().firstWhere((el) => el.result is R);
    return msg.result as R;
  }
}
