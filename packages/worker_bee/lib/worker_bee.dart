/// Support for doing something awesome.
///
/// More dartdocs go here.
library worker_bee;

import 'dart:async';

import 'package:meta/meta.dart';
import 'package:stream_channel/stream_channel.dart';

import 'src/vm/channel.dart' if (dart.library.html) 'src/js/channel.dart';

class WorkerBee {
  const WorkerBee();
}

abstract class WorkerBeeBase<M, R> {
  /// Runs the worker in a separate thread/WebWorker.
  ///
  /// Listen to the spawning thread using [listen] and respond using [respond].
  Future<R> run(Stream<M> listen, StreamSink<M> respond);

  @nonVirtual
  Future<R> start() async {
    awai 
    final StreamChannel<M> streamChannel = createChannel();
    return run(streamChannel.stream, streamChannel.sink);
  }
}
