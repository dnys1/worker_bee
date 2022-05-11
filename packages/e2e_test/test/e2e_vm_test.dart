@TestOn('vm')

import 'package:test/test.dart';

import 'common.dart';

void main() {
  group('WorkerBee', () {
    group('', () {
      test('VM', () => testWorker());
    });

    group('| no result', () {
      test('VM', () => testWorkerNoResult());
    });

    group('| void result', () {
      test('VM', () => testWorkerVoidResult());
    });

    group('| null result', () {
      test('VM', () => testWorkerNullResult());
    });

    group('| throws', () {
      test('VM', () => testWorkerThrows());
    });
  });

  group('WorkerPool', () {
    group('', () {
      test('VM', () => testWorkerPool());
    });

    group('| remote', () {
      test('VM', () => testRemoteWorkerPool());
    });
  });
}
