import 'dart:async';
import 'dart:isolate';

import 'package:stream_channel/isolate_channel.dart';
import 'package:stream_channel/stream_channel.dart';

Future<StreamChannel<M>> spawn<M>({
  String? url,
  void Function(Object)? fn,
}) async {
  final receivePort = ReceivePort();
  // await Isolate.spawn(fn);
  return IsolateChannel.connectReceive(receivePort);
}
