import 'dart:async';
import 'dart:html';

import 'package:stream_channel/stream_channel.dart';
import 'package:worker_bee/src/js/util.dart';

import '../exception.dart';

StreamChannel<M> spawn<M>({
  String? url,
  void Function(Object)? fn,
}) {
  if (url == null) {
    throw ArgumentError.notNull('url');
  }

  // Spawn the worker at the URL.
  final Worker worker = Worker(url);

  // Create the controller to handle message passing.
  final StreamController<M> controller = StreamController(
    sync: true,
    onCancel: () => worker.terminate(),
  );

  // Listen for error messages on the worker.
  worker.onError.listen((Event event) {
    if (event is ErrorEvent) {
      controller.addError(WebWorkerException(
        event.message ?? JSON.stringify(event),
        filename: event.filename,
        lineNo: event.lineno,
      ));
    } else {
      controller.addError(WebWorkerException(JSON.stringify(event)));
    }
  });

  // Passes outgoing messages to the worker instance.
  // TODO: transferable
  controller.stream.listen(worker.postMessage);

  // Listen to worker
  final incomingMessages = worker.onMessage.map((MessageEvent event) {
    return event.data;
  }).cast<M>();

  return StreamChannel(incomingMessages, controller.sink);
}
