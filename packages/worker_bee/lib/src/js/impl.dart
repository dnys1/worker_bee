import 'dart:async';
import 'dart:html';

import 'package:worker_bee/src/common.dart';
import 'package:worker_bee/worker_bee.dart';

import 'util.dart';

/// {@macro worker_bee.worker_bee_impl}
mixin WorkerBeeImpl<Message extends Object, Result>
    on WorkerBeeCommon<Message, Result> {
  @override
  String get jsEntrypoint;

  @override
  Future<void> connect() async {
    print('(Worker) Connecting from worker...');
    final channel = StreamChannelController<Message>();
    self.addEventListener(
      'message',
      (Event event) {
        event as MessageEvent;
        print('(Worker) Got message from main: ${event.data}');
        final serialized = event.data as Object?;
        final message = deserialize<Message>(serialized);
        channel.foreign.sink.add(message);
      },
    );
    channel.foreign.stream.listen((message) {
      print('(Worker) Sending message to main: ${JSON.stringify(message)}');
      self.postMessage(serialize(message));
    });
    print('(Worker) Sending ready event');
    self.postMessage('ready');
    final result = await run(
      channel.local.stream,
      channel.local.sink,
    );
    print('(Worker) Finished with result: $result');
    self.postMessage(serialize(result));
  }

  @override
  Future<void> spawn() async {
    print('(Main) Spawning worker at $jsEntrypoint...');
    // Spawn the worker using the main script.
    final worker = Worker(jsEntrypoint);

    // Create the controller to handle message passing.
    // ignore: close_sinks
    final controller = StreamController<Message>(
      sync: true,
      onCancel: worker.terminate,
    );

    // Listen for error messages on the worker.
    worker.onError.listen((Event event) {
      print('(Main) Error from worker: $event');
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
    controller.stream.listen((message) {
      print('(Main) Sending message to worker: ${JSON.stringify(message)}');
      worker.postMessage(serialize(message)); // TODO: Transferable
    });

    // Listen to worker
    // ignore: close_sinks
    final incomingMessages = StreamController<Message>(sync: true);
    worker.onMessage.listen((MessageEvent event) {
      print('(Main) Got message from worker: ${event.data}');
      if (event.data is String && event.data == 'ready') {
        print('(Main) Received ready event');
        ready.complete();
        return;
      }
      final serialized = event.data as Object?;
      final message = deserialize(serialized);
      if (message is Message) {
        incomingMessages.add(message);
      } else {
        final result = message as Result;
        complete(result);
        worker.terminate();
      }
    });

    channel = StreamChannel<Message>(incomingMessages.stream, controller.sink);

    // Send assignment
    worker.postMessage(name);

    await ready.future;
  }
}
