@TestOn('browser')

import 'package:test/test.dart';

import 'common.dart';

void main() {
  group('WorkerBee', () {
    test(
      'dart2Js',
      () => testWorker(
        jsEntrypoint: 'packages/e2e_test/workers.js',
      ),
    );

    test(
      'dart2Js (m, O4)',
      () => testWorker(
        jsEntrypoint: 'packages/e2e_test/workers.min.js',
      ),
    );
  });

  group('WorkerPool', () {
    test(
      'dart2Js',
      () => testWorkerPool(
        jsEntrypoint: 'packages/e2e_test/workers.js',
      ),
    );

    test(
      'dart2Js (m, O4)',
      () => testWorkerPool(
        jsEntrypoint: 'packages/e2e_test/workers.min.js',
      ),
    );
  });

  group('Remote WorkerPool', () {
    test(
      'dart2Js',
      () => testRemoteWorkerPool(
        jsEntrypoint: 'packages/e2e_test/workers.js',
      ),
    );

    test(
      'dart2Js (m, O4)',
      () => testRemoteWorkerPool(
        jsEntrypoint: 'packages/e2e_test/workers.min.js',
      ),
    );
  });
}
