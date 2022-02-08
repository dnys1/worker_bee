/// Support for doing something awesome.
///
/// More dartdocs go here.
library worker_bee;

import 'package:built_value/serializer.dart';
import 'package:worker_bee/src/common.dart';

import 'src/vm/impl.dart' if (dart.library.html) 'src/js/impl.dart';

export 'package:async/async.dart';
export 'package:stream_transform/stream_transform.dart';
export 'src/exception.dart';
export 'src/preamble.dart';
export 'src/worker_bee_vm.dart' if (dart.library.html) 'src/worker_bee_js.dart';

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

/// Annotation class for native JS call.
class NativeJsCall {
  const NativeJsCall(this.name);

  final String name;
}

/// Annotation class for native FFI call.
class NativeFfiCall {
  const NativeFfiCall(this.name);

  final String name;
}

/// Annotation class for native WASM call.
class NativeWasmCall {
  const NativeWasmCall(this.name);

  final String name;
}

/// The base class for all worker bees.
///
/// Classes annotated with [WorkerBee] must extend this class.
abstract class WorkerBeeBase<Message extends Object, Result>
    extends WorkerBeeCommon<Message, Result>
    with WorkerBeeImpl<Message, Result> {
  WorkerBeeBase([Serializers? serializers]) : super(serializers);
}
