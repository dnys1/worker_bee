import 'dart:async';
import 'dart:html';

import 'package:built_value/serializer.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;
import 'package:worker_bee/src/common.dart';
import 'package:worker_bee/src/exception/worker_bee_exception.dart';
import 'package:worker_bee/src/preamble.dart';
import 'package:worker_bee/worker_bee.dart';

import 'util.dart';

/// The result of serializing a message using the registered `built_value`
/// serializers.
///
/// Objects needing transfer between contexts, e.g. [MessagePort]s, will be
/// included in the [transfer] array.
class _WorkerSerializeResult {
  const _WorkerSerializeResult(this.value, this.transfer);

  /// The serialized value.
  final Object? value;

  /// Objects needing transfer between contexts, e.g. [MessagePort]s.
  final List<Object> transfer;
}

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

  /// Serializes an object using the registered `built_value` serializers.
  _WorkerSerializeResult _serialize(Object? object) {
    final transfer = <Object>[];
    final serialized = runZoned(
      () => serializers.serialize(
        object,
        // Do not specify type so that it is serialized into the array.
        specifiedType: FullType.unspecified,
      ),
      zoneValues: {
        #transfer: transfer,
      },
    );
    return _WorkerSerializeResult(serialized, transfer);
  }

  /// Deserializes an object using the registered `built_value` serializers.
  @optionalTypeArgs
  T _deserialize<T extends Object?>(Object? object) {
    return serializers.deserialize(
      object,
      // Do not specify type so that it pulls from the array.
      specifiedType: FullType.unspecified,
    ) as T;
  }

  @override
  void completeError(Object error, [StackTrace? stackTrace]) {
    error = _serialize(error).value as Object;
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
    return runTraced(
      () async {
        await super.connect(logsChannel: logsChannel);
        logger.info('Connected from worker');
        final channel = StreamChannelController<Object?>(sync: true);
        self.addEventListener(
          'message',
          Zone.current.bindUnaryCallback<void, Event>((Event event) {
            event as MessageEvent;
            logger.fine('Got message: ${event.data}');
            final serialized = event.data as Object?;
            final message = _deserialize<Request>(serialized);
            channel.foreign.sink.add(message);
          }),
        );
        channel.foreign.stream.listen(
          Zone.current.bindUnaryCallback((message) {
            logger.fine('Sending message: $message');
            final serialized = _serialize(message);
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

        final serializedResult = _serialize(result);
        self.postMessage(serializedResult.value, serializedResult.transfer);
      },
      onError: completeError,
    );
  }

  @override
  @nonVirtual
  Future<void> spawn({String? jsEntrypoint}) async {
    return runTraced(
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
          Zone.current.bindUnaryCallback((message) {
            logger.fine('Sending message: $message');
            final serialized = _serialize(message);
            _worker!.postMessage(serialized.value, serialized.transfer);
          }),
        );

        // Listen to worker
        _incomingMessages = StreamController<Response>(sync: true);
        _worker!.onMessage.listen(
          Zone.current.bindUnaryCallback((MessageEvent event) {
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
            var message = _deserialize(serialized);
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
          Zone.current.bindUnaryCallback((event) {
            final data = event.data as Object?;
            final message = _deserialize<LogMessage>(data);
            if (logsController.isClosed) return;
            logsController.add(message);
          }),
        );
        _worker!.postMessage(name, [logsChannel.port2]);

        await ready.future;
      },
      onError: completeError,
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
