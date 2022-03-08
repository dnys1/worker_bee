import 'dart:async';
import 'dart:isolate';

import 'package:meta/meta.dart';
import 'package:worker_bee/src/common.dart';
import 'package:worker_bee/worker_bee.dart';

/// The function signature for the generated VM entrypoint, as required by
/// [Isolate.spawn].
typedef VmEntrypoint = Future<void> Function(SendPort);

/// {@template worker_bee.worker_bee_impl}
/// The platform-specific implementation of [WorkerBeeCommon].
/// {@endtemplate}
@internal
mixin WorkerBeeImpl<Message extends Object, Result>
    on WorkerBeeCommon<Message, Result> {
  @override
  Function /*VmEntrypoint*/ get vmEntrypoint;

  @override
  Future<void> connect() async {}

  @override
  Future<void> spawn({String? jsEntrypoint}) async {
    safePrint('(Main) Starting worker...');
    final receivePort = ReceivePort(name);
    final transformer = StreamTransformer<Object, Message>.fromHandlers(
      handleData: (data, sink) {
        if (data is Message) {
          sink.add(data);
        } else {
          complete(data as Result);
          sink.close();
        }
      },
    );
    channel = IsolateChannel<Object>.connectReceive(receivePort)
        .transformStream(transformer)
        .cast<Message>();

    // Listen to stream to activate transformer
    stream.listen((message) {
      safePrint('(Main) Got message: $message');
    });

    await Isolate.spawn(
      vmEntrypoint as VmEntrypoint,
      receivePort.sendPort,
    );
  }
}
