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
    this.donePort,
    this.logPort,
  );

  /// The port used for communicating messages, passed to the [IsolateChannel]
  /// instance upon launch.
  final SendPort messagePort;

  /// The port used for signaling completion from the isolate.
  ///
  /// Passed to [Isolate.exit].
  final SendPort donePort;

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
mixin WorkerBeeImpl<Request extends Object, Response>
    on WorkerBeeCommon<Request, Response> {
  @override
  Function /*VmEntrypoint*/ get vmEntrypoint;

  @override
  String? get workerEntrypointOverride {
    return null;
  }

  Isolate? _isolate;

  @override
  Future<void> spawn({String? jsEntrypoint}) async {
    logger.finest('Starting worker');
    final receivePort = ReceivePort(name);
    final channel = IsolateChannel<Object?>.connectReceive(receivePort);

    stream = channel.stream.cast();
    sink = channel.sink.cast();

    // Listen to stream to activate transformer.
    stream.listen((message) {
      logger.finest('Got message: $message');
    });

    final logPort = ReceivePort('${name}_logs');
    final logChannel = IsolateChannel<LogMessage>.connectReceive(logPort);
    logChannel.stream.listen((log) {
      if (logsController.isClosed) return;
      logsController.add(log);
    });

    final donePort = ReceivePort('${name}_done');
    final exitPort = ReceivePort('${name}_exit');
    final errorPort = ReceivePort('${name}_error');
    final ports = SendPorts(
      receivePort.sendPort,
      donePort.sendPort,
      logPort.sendPort,
    );
    _isolate = await Isolate.spawn(
      vmEntrypoint as VmEntrypoint,
      ports,
      debugName: name,
      onExit: exitPort.sendPort,
      onError: errorPort.sendPort,
    );
    donePort.first.then<void>((dynamic result) {
      if (isCompleted) return;
      if (result is Response?) {
        complete(result);
      } else {
        completeError(Exception('Unexpected result: $result'));
      }
    });
    exitPort.first.then<void>((dynamic _) {
      if (isCompleted) return;
      completeError(Exception('Worker quit unexpectedly'));
    });
    errorPort.first.then<void>((dynamic error) {
      if (isCompleted) return;
      error as List<Object?>;
      final message = error[0] as String;
      final stackTraceString = error[1] as String?;
      final stackTrace = stackTraceString == null
          ? null
          : StackTrace.fromString(stackTraceString);
      completeError(message, stackTrace);
    });
  }

  @override
  Future<void> close({
    bool force = false,
  }) async {
    await super.close(force: force);
    await logsController.close();
    _isolate?.kill();
    _isolate = null;
  }
}
