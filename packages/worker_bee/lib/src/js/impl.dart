import 'dart:async';
import 'dart:html';

import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;
import 'package:stack_trace/stack_trace.dart';
import 'package:worker_bee/src/common.dart';
import 'package:worker_bee/src/exception/worker_bee_exception.dart';
import 'package:worker_bee/worker_bee.dart';

import 'util.dart';

/// {@macro worker_bee.worker_bee_impl}
mixin WorkerBeeImpl<Message extends Object, Result>
    on WorkerBeeCommon<Message, Result> {
  /// Protects [connect] from only being called once.
  final _connectMemoizer = AsyncMemoizer<void>();

  /// Protects [spawn] from only being called once.
  final _spawnMemoizer = AsyncMemoizer<Worker>();

  /// The spawned worker instance.
  Worker? _worker;

  @override
  String get jsEntrypoint;

  @override
  String? get workerEntrypointOverride {
    if (currentUri.path.isNotEmpty && !currentUri.path.endsWith(jsEntrypoint)) {
      return currentUri.path;
    }
    return null;
  }

  @override
  @nonVirtual
  Future<void> connect() async {
    await _connectMemoizer.runOnce(() {
      return Chain.capture(
        () async {
          safePrint('(Worker) Connecting from worker...');
          final channel = StreamChannelController<Object>(sync: true);
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
            channel.local.stream.asBroadcastStream().cast(),
            channel.local.sink.cast(),
          );
          safePrint('(Worker) Finished with result: $result');
          self.postMessage('done');
          self.postMessage(serialize(result));
        },
        onError: (Object error, Chain stackTrace) {
          safePrint('(Worker) An unexpected error occurred.');
          self.postMessage(serialize(WebWorkerException(
            error.toString(),
            stackTrace: stackTrace,
          )));
        },
      );
    });
  }

  @override
  @nonVirtual
  Future<void> spawn({String? jsEntrypoint}) async {
    _worker ??= await _spawnMemoizer.runOnce(() {
      return Chain.capture(
        () async {
          final entrypoint = jsEntrypoint ?? this.jsEntrypoint;
          safePrint('(Main) Spawning worker at $entrypoint...');

          // Spawn the worker using the specified script.
          Worker worker;
          try {
            worker = Worker(entrypoint);
          } on Object {
            // If `entrypoint` contains a path, try again at the root to
            // account for Dart vs. Flutter semantics when deploying Web apps.
            try {
              worker = Worker(path.basename(entrypoint));
            } on Object {
              throw WebWorkerException(
                'Could not launch web worker at $entrypoint.',
              );
            }
          }

          // Whether `run` has completed on the web worker.
          var done = false;

          // Create the controller to handle message passing.
          // ignore: close_sinks
          final controller = StreamController<Message>(
            sync: true,
            onCancel: () {
              if (!done) {
                completeError(WebWorkerException('Worker quit unexpectedly'));
              }
            },
          );

          // Listen for error messages on the worker.
          worker.addEventListener('messageerror', (Event event) {
            event as MessageEvent;
            final error = serialize(WebWorkerException(
              'Could not serialize message: ${event.data}',
            )) as Object;
            controller.addError(error);
            completeError(error);
          });
          worker.onError.listen((Event event) {
            final eventJson = JSON.stringify(event);
            safePrint('(Main) Error from worker: $eventJson');
            Object error;
            if (event is ErrorEvent) {
              error = WebWorkerException(
                event.message ?? eventJson,
                filename: event.filename,
                lineNo: event.lineno,
              );
            } else {
              error = WebWorkerException(eventJson);
            }
            error = serialize(error) as Object;
            controller.addError(error);
            completeError(error);
          });

          // Passes outgoing messages to the worker instance.
          controller.stream.listen((message) {
            safePrint('(Main) Sending message: $message');
            worker.postMessage(serialize(message));
          });

          // Listen to worker
          // ignore: close_sinks
          final incomingMessages = StreamController<Result>(sync: true);
          worker.onMessage.listen((MessageEvent event) {
            safePrint('(Main) Got message: ${event.data}');
            if (event.data is String) {
              if (event.data == 'ready') {
                safePrint('(Main) Received ready event');
                ready.complete();
                return;
              }
              if (event.data == 'done') {
                safePrint('(Main) Received done event');
                done = true;
                return;
              }
            }
            final serialized = event.data as Object?;
            var message = deserialize(serialized);
            if (message is WebWorkerException) {
              message = serialize(message) as Object;
              controller.addError(message);
              completeError(message);
              return;
            }
            message as Result;
            incomingMessages.add(message);
            if (done) {
              complete(message);
            }
          });

          stream = incomingMessages.stream;
          sink = controller.sink;

          // Send assignment
          worker.postMessage(name);

          await ready.future;

          return worker;
        },

        // Since `spawn` could be spawned from within a worker, e.g. in the case
        // of a worker pool, any uncaught errors lose visibility when they're
        // reported back _unless_ we serialize them first.
        onError: (error, chain) {
          final workerException = error is WorkerBeeException
              ? error.rebuild((b) => b.stackTrace = chain)
              : WorkerBeeExceptionImpl(error, chain);
          if (isWebWorker) {
            // ignore: only_throw_errors
            throw serialize(workerException) as Object;
          }
          throw workerException;
        },
      );
    });
  }

  @override
  Future<void> close() async {
    _worker?.terminate();
    _worker = null;
    await super.close();
  }
}
