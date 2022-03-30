import 'package:e2e_test/e2e_worker.dart';
import 'package:e2e_test/e2e_worker_pool.dart';
import 'package:test/test.dart';
import 'package:worker_bee/worker_bee.dart';

Future<void> testWorker({String? jsEntrypoint}) async {
  final _message = message;

  final worker = E2EWorker.create();
  await worker.spawn(jsEntrypoint: jsEntrypoint);
  worker.add(_message);

  final messages = await worker.stream.take(1).toList();
  final result = await Result.release(worker.result);
  for (final workerMessage in [...messages, result].map((el) => el.message)) {
    expect(workerMessage.bigInt, equals(_message.bigInt));
    expect(workerMessage.bool_, equals(_message.bool_));
    expect(workerMessage.builtList.toList(),
        orderedEquals(_message.builtList.toList()));
    expect(workerMessage.builtListMultimap.toMap(),
        equals(_message.builtListMultimap.toMap()));
    expect(workerMessage.builtMap.toMap(), equals(_message.builtMap.toMap()));
    expect(workerMessage.builtSet.toSet(), equals(_message.builtSet.toSet()));
    expect(workerMessage.dateTime, equals(_message.dateTime));
    expect(workerMessage.double_, equals(_message.double_));
    expect(workerMessage.duration, equals(_message.duration));
    expect(workerMessage.int64, equals(_message.int64));
    expect(workerMessage.int_, equals(_message.int_));
    expect(workerMessage.jsonObject.value, equals(_message.jsonObject.value));
    expect(workerMessage.num_, equals(_message.num_));
    expect(workerMessage.regExp.pattern, equals(_message.regExp.pattern));
    expect(workerMessage.uri, equals(_message.uri));
  }
}

Future<void> testWorkerPool({String? jsEntrypoint}) async {
  final sink = NullStreamSink<E2EResult>();
  final workerPool = WorkerPool<E2EMessage, E2EResult, E2EWorker>(
    numWorkers,
    factory: E2EWorker.create,
    sink: sink,
  );
  int liveWorkers() => workerPool.pool.where((el) => el.hasRun).length;

  expect(liveWorkers(), 0);

  final worker1 = await workerPool.assign(message, jsEntrypoint: jsEntrypoint);
  expect(liveWorkers(), 1);

  final worker2 = await workerPool.assign(message, jsEntrypoint: jsEntrypoint);
  expect(liveWorkers(), 2);

  final worker3 = await workerPool.assign(message, jsEntrypoint: jsEntrypoint);
  expect(liveWorkers(), 3);

  final worker4 = await workerPool.assign(message, jsEntrypoint: jsEntrypoint);
  expect(liveWorkers(), 4);

  final worker5 = await workerPool.assign(message, jsEntrypoint: jsEntrypoint);
  expect(liveWorkers(), 5);

  final worker6 = await workerPool.assign(message, jsEntrypoint: jsEntrypoint);
  expect(liveWorkers(), 5);
  expect(identical(worker1, worker6), isTrue);

  await expectLater(workerPool.close(), completes);
  expect(worker1.result, completion(isA<ErrorResult>()));
  expect(worker2.result, completion(isA<ErrorResult>()));
  expect(worker3.result, completion(isA<ErrorResult>()));
  expect(worker4.result, completion(isA<ErrorResult>()));
  expect(worker5.result, completion(isA<ErrorResult>()));
}

Future<void> testRemoteWorkerPool({String? jsEntrypoint}) async {
  final pool = E2EWorkerPool.create();
  await pool.spawn(jsEntrypoint: jsEntrypoint);

  final stream = StreamQueue(pool.stream);

  const numWorkers = 5;
  for (var i = 0; i < numWorkers; i++) {
    pool.add(message);
  }

  await expectLater(
    stream.take(5),
    completes,
  );

  await pool.close();
  expect(() => pool.add(message), throwsStateError);
}
