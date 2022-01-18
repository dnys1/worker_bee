import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:native_example/example.dart';
import 'package:native_lib/native_lib.dart';

import 'package:worker_bee/worker_bee.dart';

class MyMessageImpl implements MyMessage {
  MyMessageImpl({
    required Uint8List data,
  })  : _data = TransferableTypedData.fromList([data]),
        result = null;

  MyMessageImpl.done(this.result) : _data = null;

  final TransferableTypedData? _data;

  @override
  Uint8List get data => _data!.materialize().asUint8List();

  @override
  final String? result;
}

void _run(SendPort sendPort) async {
  final channel = IsolateChannel.connectSend(sendPort);
  final result = await MyWorkerImpl().run(
    channel.stream.cast()
      ..tap((message) {
        print('(Worker) Got message from main: $message');
      }),
    channel.sink.transform(
      StreamSinkTransformer.fromHandlers(
        handleData: (MyMessage data, EventSink<dynamic> sink) {
          print('(Worker) Sending message to main: $data');
          sink.add(data);
        },
      ),
    ),
  );
  print('(Worker) Finished with result: $result');
  await Future.delayed(Duration.zero);
  Isolate.exit(sendPort, MyMessageImpl.done(result));
}

class MyWorkerImpl extends MyWorker {
  @override
  Future<void> connect() async {}

  @override
  Future<void> start() async {
    print('(Main) Starting worker...');
    final receivePort = ReceivePort();
    channel = IsolateChannel.connectReceive(receivePort);

    stream.tap((message) {
      print('(Main) Got message from worker: $message');
    });

    await Isolate.spawn(_run, receivePort.sendPort);
  }

  @override
  String base64Encode(Uint8List data) {
    final DynamicLibrary dylib;
    if (Platform.isAndroid || Platform.isLinux) {
      dylib = DynamicLibrary.open('libnative.so');
    } else {
      dylib = DynamicLibrary.process();
    }
    final native = NativeLibrary(dylib);
    //Copy data into C-memory
    final needsNul = data.last != 0;
    final ptr = malloc.allocate<Int8>(needsNul ? data.length + 1 : data.length);
    for (var i = 0; i < data.length; i++) {
      ptr.elementAt(i).value = data[i];
    }
    if (needsNul) {
      ptr.elementAt(data.length).value = 0;
    }
    final out = native.base64_encode_ffi(ptr.cast());
    final result = out.cast<Utf8>().toDartString();
    malloc.free(ptr);
    return result;
  }
}
