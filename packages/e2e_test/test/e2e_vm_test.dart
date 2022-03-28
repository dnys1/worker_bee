@TestOn('vm')

import 'package:test/test.dart';

import 'common.dart';

void main() {
  group('WorkerBee', () {
    test('VM', () => testWorker());
  });

  group('WorkerPool', () {
    test('VM', () => testWorkerPool());
  });

  group('Remote WorkerPool', () {
    test('VM', () => testRemoteWorkerPool());
  });
}
