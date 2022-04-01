@TestOn('browser')

import 'package:test/test.dart';

import 'common.dart';

void main() {
  group('WorkerBee', () {
    group('', () {
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

    group('| no result', () {
      test(
        'dart2Js',
        () => testWorkerNoResult(
          jsEntrypoint: 'packages/e2e_test/workers.js',
        ),
      );

      test(
        'dart2Js (m, O4)',
        () => testWorkerNoResult(
          jsEntrypoint: 'packages/e2e_test/workers.min.js',
        ),
      );
    });

    group('| void result', () {
      test(
        'dart2Js',
        () => testWorkerVoidResult(
          jsEntrypoint: 'packages/e2e_test/workers.js',
        ),
      );

      test(
        'dart2Js (m, O4)',
        () => testWorkerVoidResult(
          jsEntrypoint: 'packages/e2e_test/workers.min.js',
        ),
      );
    });

    group('| null result', () {
      test(
        'dart2Js',
        () => testWorkerNullResult(
          jsEntrypoint: 'packages/e2e_test/workers.js',
        ),
      );

      test(
        'dart2Js (m, O4)',
        () => testWorkerNullResult(
          jsEntrypoint: 'packages/e2e_test/workers.min.js',
        ),
      );
    });
  });

  group('WorkerPool', () {
    group('', () {
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

    group('| remote', () {
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
  });
}
