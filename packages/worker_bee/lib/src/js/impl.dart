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
    safePrint('(Worker) Connecting from worker...');
    final channel = StreamChannelController<Message>(sync: true);
    self.addEventListener(
      'message',
      (Event event) {
        event as MessageEvent;
        safePrint('(Worker) Got message: ${event.data}');
        final serialized = event.data as Object?;
        final message = deserialize<Message>(serialized);
        channel.foreign.sink.add(message);
      },
    );
    channel.foreign.stream.listen((message) {
      safePrint('(Worker) Sending message: $message');
      self.postMessage(serialize(message));
    });
    safePrint('(Worker) Sending ready event');
    self.postMessage('ready');
    final result = await run(
      channel.local.stream,
      channel.local.sink,
    );
    safePrint('(Worker) Finished with result: $result');
    self.postMessage(serialize(result));
  }

  @override
  Future<void> spawn({String? jsEntrypoint}) async {
    final entrypoint = jsEntrypoint ?? this.jsEntrypoint;
    safePrint('(Main) Spawning worker at $entrypoint...');

    // Spawn the worker using the main script.
    final worker = Worker(entrypoint);

    // Create the controller to handle message passing.
    // ignore: close_sinks
    final controller = StreamController<Message>(
      sync: true,
      onCancel: worker.terminate,
    );

    // Listen for error messages on the worker.
    worker.onError.listen((Event event) {
      final eventJson = JSON.stringify(event);
      safePrint('(Main) Error from worker: $eventJson');
      WebWorkerException error;
      if (event is ErrorEvent) {
        error = WebWorkerException(
          event.message ?? eventJson,
          filename: event.filename,
          lineNo: event.lineno,
        );
      } else {
        error = WebWorkerException(eventJson);
      }
      controller.addError(error);
      completeError(result);
    });

    // Passes outgoing messages to the worker instance.
    controller.stream.listen((message) {
      safePrint('(Main) Sending message: $message');
      worker.postMessage(serialize(message));
    });

    // Listen to worker
    // ignore: close_sinks
    final incomingMessages = StreamController<Message>(sync: true);
    worker.onMessage.listen((MessageEvent event) {
      safePrint('(Main) Got message: ${event.data}');
      if (event.data is String && event.data == 'ready') {
        safePrint('(Main) Received ready event');
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
