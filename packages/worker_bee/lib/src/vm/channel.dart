import 'dart:async';
import 'dart:isolate';

import 'package:stream_channel/isolate_channel.dart';
import 'package:stream_channel/stream_channel.dart';



void _run() {

}

Future<R> spawn<M, R>(Future<R> Function(Stream<M>, StreamSink<M>) fn) async {
  final port = ReceivePort();
  Isolate.pac
  await Isolate.spawn((message) {
    
  }, message)
}

StreamChannel<M> createChannel<M>() {
  final channel = IsolateChannel(receivePort, sendPort)
}