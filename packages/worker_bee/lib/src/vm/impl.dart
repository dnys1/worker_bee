import 'dart:async';
import 'dart:isolate';

import 'package:meta/meta.dart';
import 'package:worker_bee/src/common.dart';
import 'package:worker_bee/worker_bee.dart';

/// {@template worker_bee.send_ports}
/// Ports passed to a VM worker bee for relaying messages and exits.
/// {@endtemplate}
class SendPorts {
  /// {@macro worker_bee.send_ports}
  const SendPorts(
    this.messagePort,
    this.exitPort,
    this.logPort,
  );

  /// The port used for communicating messages, passed to the [IsolateChannel]
  /// instance upon launch.
  final SendPort messagePort;

  /// The port used for exiting the isolate, passed to [Isolate.exit].
  final SendPort exitPort;

  /// The port used for log messages.
  final SendPort logPort;
}

/// The function signature for the generated VM entrypoint, as required by
/// [Isolate.spawn].
typedef VmEntrypoint = Future<void> Function(SendPorts);

/// {@template worker_bee.worker_bee_impl}
/// The platform-specific implementation of [WorkerBeeCommon].
/// {@endtemplate}
@internal
mixin WorkerBeeImpl<Message extends Object, Result>
    on WorkerBeeCommon<Message, Result> {
  @override
  Function /*VmEntrypoint*/ get vmEntrypoint;

  @override
  String? get workerEntrypointOverride {
    return null;
  }

  final _spawnMemoizer = AsyncMemoizer<Isolate>();
  Isolate? _isolate;

  @override
  Future<void> spawn({String? jsEntrypoint}) async {
    _isolate ??= await _spawnMemoizer.runOnce(() async {
      logger.info('Starting worker');
      final receivePort = ReceivePort(name);
      final channel = IsolateChannel<Object>.connectReceive(receivePort);

      stream = channel.stream.cast();
      sink = channel.sink.cast();

      // Listen to stream to activate transformer.
      stream.listen((message) {
        logger.fine('Got message: $message');
      });

      final logPort = ReceivePort('${name}_logs');
      final logChannel = IsolateChannel<LogMessage>.connectReceive(logPort);
      logChannel.stream.listen((log) {
        if (logsController.isClosed) return;
        logsController.add(log);
      });

      final exitPort = ReceivePort('${name}_exit');
      final errorPort = ReceivePort('${name}_error');
      final ports = SendPorts(
        receivePort.sendPort,
        exitPort.sendPort,
        logPort.sendPort,
      );
      final isolate = await Isolate.spawn(
        vmEntrypoint as VmEntrypoint,
        ports,
        debugName: name,
        onExit: exitPort.sendPort,
        onError: errorPort.sendPort,
      );
      exitPort.first.then<void>((dynamic result) {
        // If `close` is called manually, the isolate will exit without running
        // completely and `result` will be `null`.
        if (result == null || result is! Result) {
          completeError(Exception('Worker quit unexpectedly'));
        } else {
          complete(result);
        }
      });
      errorPort.first.then<void>((dynamic error) {
        error as List<Object?>;
        final message = error[0] as String;
        final stackTraceString = error[1] as String?;
        final stackTrace = stackTraceString == null
            ? null
            : StackTrace.fromString(stackTraceString);
        completeError(message, stackTrace);
      });

      return isolate;
    });
  }

  @override
  Future<void> close() async {
    _isolate?.kill();
    _isolate = null;
    await super.close();
  }
}
