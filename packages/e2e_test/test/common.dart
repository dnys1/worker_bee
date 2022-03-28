import 'package:e2e_test/e2e_worker.dart';
import 'package:test/test.dart';
import 'package:worker_bee/worker_bee.dart';

Future<void> testWorker({String? jsEntrypoint}) async {
  final _message = message;

  final worker = E2EWorker.create();
  await worker.spawn(jsEntrypoint: jsEntrypoint);
  worker.add(_message);

  final messages = await worker.stream.take(1).toList();
  final result = await worker.result;
  for (final workerMessage
      in [...messages, result.asValue!.value].map((el) => el.message)) {
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
