@TestOn('browser')

import 'dart:html';

import 'package:test/test.dart';

void main() {
  Future<void> badAssignmentTest(String jsEntrypoint) async {
    final worker = Worker(jsEntrypoint);
    worker.postMessage('NoWorker');

    List<Object> errors = [];
    worker.onError.listen(errors.add);

    late List<Object?> data;
    await expectLater(
      worker.onMessage.first,
      completion(isA<MessageEvent>().having(
        (message) => data = message.data,
        'data',
        isA<List>(),
      )),
    );
    worker.terminate();

    expect(errors, isEmpty);
    expect(data.first, 'WorkerBeeExceptionImpl');
  }

  group('preamble', () {
    test('bad assignment', () {
      badAssignmentTest('packages/e2e_test/no_workers.js');
    });

    test('bad assignment (m, O4)', () {
      badAssignmentTest('packages/e2e_test/no_workers.min.js');
    });
  });
}
