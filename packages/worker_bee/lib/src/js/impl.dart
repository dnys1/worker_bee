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
mixin WorkerBeeImpl<Request extends Object, Response>
    on WorkerBeeCommon<Request, Response> {
  // Controllers used to manage web worker.
  StreamController<Request>? _controller;
  StreamController<Response>? _incomingMessages;

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

  /// Runs [action] in an error zone and automatically handles serialization
  /// of unhandled errors.
  R _runChained<R>(R Function() action) {
    return Chain.capture(
      action,

      // Since this could be called from within a worker, e.g. in the case
      // of a worker pool, any uncaught errors lose visibility when they're
      // reported back _unless_ we serialize them first.
      onError: (Object error, Chain stackTrace) {
        final workerException = error is WorkerBeeException
            ? error.rebuild((b) => b.stackTrace = stackTrace)
            : WorkerBeeExceptionImpl(error, stackTrace);
        completeError(workerException, stackTrace);
      },
    );
  }

  @override
  void completeError(Object error, [StackTrace? stackTrace]) {
    error = serialize(error).value as Object;
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
    return _runChained(
      () async {
        logger.info('Connected from worker');
        final channel = StreamChannelController<Object?>(sync: true);
        self.addEventListener(
          'message',
          (Event event) => _runChained(() {
            event as MessageEvent;
            logger.fine('Got message: ${event.data}');
            final serialized = event.data as Object?;
            final message = deserialize<Request>(serialized);
            channel.foreign.sink.add(message);
          }),
        );
        channel.foreign.stream.listen(
          (message) => _runChained(() {
            logger.fine('Sending message: $message');
            final serialized = serialize(message);
            self.postMessage(serialized.value, serialized.transfer);
          }),
        );
        logger.info('Ready');
        self.postMessage('ready');
        final result = await run(
          channel.local.stream.asBroadcastStream().cast(),
          channel.local.sink.cast(),
        );
        logger.info('Finished');
        self.postMessage('done');

        final serializedResult = serialize(result);
        self.postMessage(serializedResult.value, serializedResult.transfer);
      },
    );
  }

  @override
  @nonVirtual
  Future<void> spawn({String? jsEntrypoint}) async {
    return _runChained(
      () async {
        final entrypoint = jsEntrypoint ?? this.jsEntrypoint;
        logger.info('Spawning worker at $entrypoint');

        // Spawn the worker using the specified script.
        try {
          _worker = Worker(entrypoint);
        } on Object {
          // If `entrypoint` contains a path, try again at the root to
          // account for Dart vs. Flutter semantics when deploying Web apps.
          final rootEntrypoint = path.basename(entrypoint);
          logger.severe('Worker not found. Trying at $rootEntrypoint');
          try {
            _worker = Worker(rootEntrypoint);
          } on Object {
            throw WorkerBeeExceptionImpl(
              'Could not launch web worker at $entrypoint.',
            );
          }
        }

        // Whether `run` has completed on the web worker.
        var done = false;

        // Create the controller to handle message passing.
        _controller = StreamController<Request>(
          sync: true,
          onCancel: () {
            if (!done) {
              completeError(WorkerBeeExceptionImpl('Worker quit unexpectedly'));
            }
          },
        );

        // Listen for error messages on the worker.
        //
        // Some browsers do not currently support the `messageerror` event:
        // https://developer.mozilla.org/en-US/docs/Web/API/Worker/messageerror_event#browser_compatibility
        _worker!.addEventListener('messageerror', (Event event) {
          event as MessageEvent;
          completeError(WorkerBeeExceptionImpl(
            'Could not serialize message: ${event.data}',
          ));
        });
        _worker!.onError.listen((Event event) {
          Object error;
          if (event is ErrorEvent) {
            final eventJson = JSON.stringify(event.error);
            error = WorkerBeeExceptionImpl('${event.message} ($eventJson)');
          } else {
            error = WorkerBeeExceptionImpl('An unknown error occurred');
          }
          completeError(error);
        });

        // Passes outgoing messages to the worker instance.
        _controller!.stream.listen(
          (message) => _runChained(() {
            logger.fine('Sending message: $message');
            final serialized = serialize(message);
            _worker!.postMessage(serialized.value, serialized.transfer);
          }),
        );

        // Listen to worker
        _incomingMessages = StreamController<Response>(sync: true);
        _worker!.onMessage.listen(
          (MessageEvent event) => _runChained(() {
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
            if (message is WorkerBeeException) {
              completeError(message);
              return;
            }
            message as Response?;
            if (message is Response) {
              _incomingMessages!.add(message);
            }
            if (done) {
              complete(message);
            }
          }),
        );

        stream = _incomingMessages!.stream;
        sink = _controller!.sink;

        // Send assignment and logs channel
        final logsChannel = MessageChannel();
        logsChannel.port1.onMessage.listen(
          (event) => _runChained(() {
            final data = event.data as Object?;
            final message = deserialize<LogMessage>(data);
            if (logsController.isClosed) return;
            logsController.add(message);
          }),
        );
        _worker!.postMessage(name, [logsChannel.port2]);

        await ready.future;
      },
    );
  }

  @override
  Future<void> close() async {
    await super.close();
    await _incomingMessages?.close();
    await _controller?.close();
    _worker?.terminate();
    _worker = null;
    _incomingMessages = null;
    _controller = null;
  }
}
