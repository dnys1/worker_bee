library worker_bee.worker_pool;

import 'dart:async';

import 'package:aws_common/aws_common.dart';
import 'package:built_value/serializer.dart';
import 'package:meta/meta.dart';
import 'package:worker_bee/worker_bee.dart';

/// {@template worker_bee.worker_pool_base}
/// Base class for a pool of [WorkerBee].
/// {@endtemplate}
abstract class WorkerPoolBase<Request extends Object, Response,
        WorkerBee extends WorkerBeeBase<Request, Response>>
    extends WorkerBeeBase<Request, Response> {
  /// {@macro worker_bee.worker_pool_base}
  WorkerPoolBase(
    this._numWorkers, {
    Serializers? serializers,
    AssignmentStrategy<Request>? strategy,
  })  : _strategy = strategy,
        super(serializers: serializers);

  /// The worker bee factory, typically `WorkerBee.create`.
  WorkerBee Function() get factory;

  final int _numWorkers;
  final AssignmentStrategy<Request>? _strategy;
  WorkerPool<Request, Response, WorkerBee>? _pool;

  @override
  Future<Response?> run(
    Stream<Request> listen,
    StreamSink<Response> respond,
  ) async {
    _pool = WorkerPool(
      _numWorkers,
      strategy: _strategy,
      sink: respond,
      factory: factory,
    );
    _pool!.logs.listen(logSink.sink.add);
    await for (final request in listen) {
      final worker = await _pool!.assign(
        request,
        jsEntrypoint: workerEntrypointOverride,
      );
      worker.add(request);
    }
    return null;
  }

  @override
  Future close() async {
    await super.close();
    await _pool?.close();
  }
}

/// {@macro worker_bee.worker_pool_base}
class WorkerPool<Request extends Object, Response,
    WorkerBee extends WorkerBeeBase<Request, Response>> implements Closeable {
  /// {@macro worker_bee.worker_pool_base}
  WorkerPool(
    this.numWorkers, {
    required this.factory,
    required this.sink,
    AssignmentStrategy<Request>? strategy,
  }) : strategy = strategy ?? AssignmentStrategy.roundRobin();

  /// The pool of lazily-initialized worker bees.
  @visibleForTesting
  late final List<AsyncMemoizer<WorkerBee>> pool = List.generate(
    numWorkers,
    (_) => AsyncMemoizer(),
  );

  /// The worker bee factory, typically `WorkerBee.create`.
  final WorkerBee Function() factory;

  /// The number of workers in the pool.
  final int numWorkers;

  /// The assignment strategy to use for incoming requests.
  final AssignmentStrategy strategy;

  /// Aggregated result sink for worker pool.
  final StreamSink<Response> sink;

  final StreamController<LogMessage> _logsController =
      StreamController.broadcast();

  /// Aggregated log messages of worker bees.
  Stream<LogMessage> get logs => _logsController.stream;

  /// Retrieves the worker for [request] based on [strategy].
  @visibleForTesting
  Future<WorkerBee> assign(
    Request request, {
    String? jsEntrypoint,
  }) {
    final workerIndex = strategy.assign(request);
    return pool[workerIndex % numWorkers].runOnce(() async {
      final worker = factory();
      worker.stream.listen(sink.add);
      worker.logs.listen(_logsController.add);
      await worker.spawn(jsEntrypoint: jsEntrypoint);
      return worker;
    });
  }

  /// Closes the worker pool and all running workers.
  @override
  Future<void> close() async {
    await Future.wait<void>([
      for (final worker in pool)
        if (worker.hasRun) (await worker.future).close(),
    ]);
    await _logsController.close();
    await sink.close();
  }
}
