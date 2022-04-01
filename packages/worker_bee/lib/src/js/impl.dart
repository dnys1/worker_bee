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

  StreamController<Message>? _controller;

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
  void completeError(Object error, [StackTrace? stackTrace]) {
    error = serialize(error) as Object;
    if (isWebWorker) {
      self.postMessage(error);
    }
    super.completeError(error, stackTrace);
  }

  @override
  @nonVirtual
  Future<void> connect({
    StreamChannel<LogMessage>? logsChannel,
  }) async {
    await super.connect(logsChannel: logsChannel);
    await _connectMemoizer.runOnce(() {
      return Chain.capture(
        () async {
          logger.info('Connected from worker');
          final channel = StreamChannelController<Object>(sync: true);
          self.addEventListener(
            'message',
            (Event event) {
              event as MessageEvent;
              logger.fine('Got message: ${event.data}');
              final serialized = event.data as Object?;
              final message = deserialize<Message>(serialized);
              channel.foreign.sink.add(message);
            },
          );
          channel.foreign.stream.listen((message) {
            logger.fine('Sending message: $message');
            self.postMessage(serialize(message));
          });
          logger.info('Ready');
          self.postMessage('ready');
          final result = await run(
            channel.local.stream.asBroadcastStream().cast(),
            channel.local.sink.cast(),
          );
          logger.info('Finished');
          self.postMessage('done');
          if (result == null) {
            self.postMessage(null);
          } else {
            self.postMessage(serialize(result));
          }
        },
        onError: (Object error, Chain stackTrace) {
          completeError(
            WebWorkerException(
              error.toString(),
              stackTrace: stackTrace,
            ),
            stackTrace,
          );
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
          logger.info('Spawning worker at $entrypoint');

          // Spawn the worker using the specified script.
          Worker worker;
          try {
            worker = Worker(entrypoint);
          } on Object {
            final rootEntrypoint = path.basename(entrypoint);
            logger.severe('Worker not found. Trying at $rootEntrypoint');
            // If `entrypoint` contains a path, try again at the root to
            // account for Dart vs. Flutter semantics when deploying Web apps.
            try {
              worker = Worker(rootEntrypoint);
            } on Object {
              throw WebWorkerException(
                'Could not launch web worker at $entrypoint.',
              );
            }
          }

          // Whether `run` has completed on the web worker.
          var done = false;

          // Create the controller to handle message passing.
          _controller = StreamController<Message>(
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
            completeError(WebWorkerException(
              'Could not serialize message: ${event.data}',
            ));
          });
          worker.onError.listen((Event event) {
            final eventJson = JSON.stringify(event);
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
            completeError(error);
          });

          // Passes outgoing messages to the worker instance.
          _controller!.stream.listen((message) {
            logger.fine('Sending message: $message');
            worker.postMessage(serialize(message));
          });

          // Listen to worker
          // ignore: close_sinks
          final incomingMessages = StreamController<Result>(sync: true);
          worker.onMessage.listen((MessageEvent event) {
            if (event.data is String) {
              if (event.data == 'ready') {
                logger.info('Received ready event');
                ready.complete();
                return;
              }
              if (event.data == 'done') {
                logger.info('Received done event');
                done = true;
                return;
              }
            }
            final serialized = event.data as Object?;
            var message = deserialize(serialized);
            logger.fine('Got message: $message');
            if (message is WebWorkerException) {
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
          sink = _controller!.sink;

          // Send assignment and logs channel
          final logsChannel = MessageChannel();
          logsChannel.port1.onMessage.listen((event) {
            final data = event.data as Object?;
            final message = deserialize<LogMessage>(data);
            if (logsController.isClosed) return;
            logsController.add(message);
          });
          worker.postMessage(name, [logsChannel.port2]);

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
          completeError(workerException, chain);
        },
      );
    });
  }

  @override
  Future<void> close() async {
    _controller?.close();
    _controller = null;
    _worker?.terminate();
    _worker = null;
    await super.close();
  }
}
