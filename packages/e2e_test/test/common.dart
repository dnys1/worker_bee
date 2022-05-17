import 'package:e2e_test/e2e_message.dart';
import 'package:e2e_test/e2e_worker.dart';
import 'package:e2e_test/e2e_worker_no_result.dart';
import 'package:e2e_test/e2e_worker_null_result.dart';
import 'package:e2e_test/e2e_worker_pool.dart';
import 'package:e2e_test/e2e_worker_throws.dart';
import 'package:e2e_test/e2e_worker_void_result.dart';
import 'package:test/test.dart';
import 'package:worker_bee/worker_bee.dart';

E2EMessage createMessage() => message;

void _expectMessage(E2EMessage workerMessage) {
  final message = createMessage();
  expect(workerMessage.bigInt, equals(message.bigInt));
  expect(workerMessage.bool_, equals(message.bool_));
  expect(workerMessage.builtList.toList(),
      orderedEquals(message.builtList.toList()));
  expect(workerMessage.builtListMultimap.toMap(),
      equals(message.builtListMultimap.toMap()));
  expect(workerMessage.builtMap.toMap(), equals(message.builtMap.toMap()));
  expect(workerMessage.builtSet.toSet(), equals(message.builtSet.toSet()));
  expect(workerMessage.dateTime, equals(message.dateTime));
  expect(workerMessage.double_, equals(message.double_));
  expect(workerMessage.duration, equals(message.duration));
  expect(workerMessage.int64, equals(message.int64));
  expect(workerMessage.int_, equals(message.int_));
  expect(workerMessage.jsonObject.value, equals(message.jsonObject.value));
  expect(workerMessage.num_, equals(message.num_));
  expect(workerMessage.regExp.pattern, equals(message.regExp.pattern));
  expect(workerMessage.uri, equals(message.uri));
  expect(
    workerMessage.intStream,
    emitsInOrder([...intStreamElements, emitsDone]),
  );
  expect(
    workerMessage.customTypeStream,
    emitsInOrder([...customTypeStreamElements, emitsDone]),
  );
}

Future<void> testWorker({String? jsEntrypoint}) async {
  final message = createMessage();

  final worker = E2EWorker.create();
  worker.logs.listen(print);
  await worker.spawn(jsEntrypoint: jsEntrypoint);
  worker.add(message);

  final messages = await worker.stream.take(1).toList();
  final result = await Result.release(worker.result);
  expect(result, isNotNull);
  for (final workerMessage in [...messages, result].map((el) => el!.message)) {
    _expectMessage(workerMessage);
  }

  await worker.close();
}

Future<void> testWorkerThrows({String? jsEntrypoint}) async {
  final message = createMessage();

  final worker = E2EWorkerThrows.create();
  worker.logs.listen(print);
  await worker.spawn(jsEntrypoint: jsEntrypoint);
  worker.sink.add(message);

  await expectLater(worker.stream, emitsError(anything));
  await expectLater(worker.result, completion(isA<ErrorResult>()));

  await worker.close();
}

Future<void> testWorkerNoResult({String? jsEntrypoint}) async {
  final message = createMessage();

  final worker = E2EWorkerNoResult.create();
  worker.logs.listen(print);
  await worker.spawn(jsEntrypoint: jsEntrypoint);
  worker.sink.add(message);

  final messages = await worker.stream.take(1).toList();
  await expectLater(Result.release(worker.result), completion(isNull));
  for (final workerMessage in messages.map((el) => el.message)) {
    _expectMessage(workerMessage);
  }

  await worker.close();
}

Future<void> testWorkerNullResult({String? jsEntrypoint}) async {
  final message = createMessage();

  final worker = E2EWorkerNullResult.create();
  worker.logs.listen(print);
  await worker.spawn(jsEntrypoint: jsEntrypoint);
  worker.sink.add(message);

  expect(worker.stream, emitsInOrder([isNull, emitsDone]));
  final result = await Result.release(worker.result);
  expect(result, isNotNull);
  _expectMessage(result!.message);

  await worker.close();
}

Future<void> testWorkerVoidResult({String? jsEntrypoint}) async {
  final message = createMessage();

  final worker = E2EWorkerVoidResult.create();
  worker.logs.listen(print);
  await worker.spawn(jsEntrypoint: jsEntrypoint);
  worker.sink.add(message);

  await expectLater(worker.stream, emitsDone);
  await expectLater(Result.release(worker.result), completes);

  await worker.close();
}

Future<void> testWorkerPool({String? jsEntrypoint}) async {
  final sink = NullStreamSink<E2EResult>();
  final workerPool = WorkerPool<E2EMessage, E2EResult, E2EWorker>(
    numWorkers,
    factory: E2EWorker.create,
    sink: sink,
  );
  workerPool.logs.listen(print);
  int liveWorkers() => workerPool.pool.where((el) => el.hasRun).length;

  expect(liveWorkers(), 0);

  final worker1 = await workerPool.assign(
    createMessage(),
    jsEntrypoint: jsEntrypoint,
  );
  expect(liveWorkers(), 1);

  final worker2 = await workerPool.assign(
    createMessage(),
    jsEntrypoint: jsEntrypoint,
  );
  expect(liveWorkers(), 2);

  final worker3 = await workerPool.assign(
    createMessage(),
    jsEntrypoint: jsEntrypoint,
  );
  expect(liveWorkers(), 3);

  final worker4 = await workerPool.assign(
    createMessage(),
    jsEntrypoint: jsEntrypoint,
  );
  expect(liveWorkers(), 4);

  final worker5 = await workerPool.assign(
    createMessage(),
    jsEntrypoint: jsEntrypoint,
  );
  expect(liveWorkers(), 5);

  final worker6 = await workerPool.assign(
    createMessage(),
    jsEntrypoint: jsEntrypoint,
  );
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
  pool.logs.listen(print);
  await pool.spawn(jsEntrypoint: jsEntrypoint);

  final stream = StreamQueue(pool.stream);

  for (var i = 0; i < numWorkers; i++) {
    pool.add(createMessage());
  }

  await expectLater(
    stream.take(5),
    completes,
  );

  await pool.close();
  expect(() => pool.add(createMessage()), throwsStateError);
}
