import 'dart:async';
import 'dart:isolate';

import 'package:worker_bee/src/common.dart';
import 'package:worker_bee/worker_bee.dart';

typedef VmEntrypoint = Future<void> Function(SendPort);

mixin WorkerBeeImpl<Message extends Object, Result>
    on WorkerBeeCommon<Message, Result> {
  @override
  Function /*VmEntrypoint*/ get vmEntrypoint;

  @override
  Future<void> connect() async {}

  @override
  Future<void> spawn() async {
    print('(Main) Starting worker...');
    final receivePort = ReceivePort('$runtimeType');
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
      print('(Main) Got message: $message');
    });

    await Isolate.spawn(
      vmEntrypoint as VmEntrypoint,
      receivePort.sendPort,
    );
  }
}
