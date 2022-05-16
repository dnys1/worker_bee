@TestOn('browser')

import 'dart:async';
import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:worker_bee/src/js/interop/readable_stream.dart';

void main() {
  ReadableStream<List<int>> createReadableStream() {
    return ReadableStream(UnderlyingSource(
      start: (controller) {
        controller.enqueue(Uint8List.fromList([1, 2, 3, 4, 5]));
        controller.enqueue(Uint8List.fromList([6, 7, 8, 9, 0]));
        controller.close();
      },
    ));
  }

  group('ReadableStreamWrapper', () {
    test('new', () {
      final readableStream = createReadableStream();
      expect(
        readableStream.stream,
        emitsInOrder(<Matcher>[
          orderedEquals(<int>[1, 2, 3, 4, 5]),
          orderedEquals(<int>[6, 7, 8, 9, 0]),
          emitsDone,
        ]),
      );
    });

    test('progress', () {
      final readableStream = createReadableStream();
      expect(
        readableStream.progress,
        emitsInOrder(<Object>[
          5,
          10,
          emitsDone,
        ]),
      );
    });

    group('asReadableStream (async)', () {
      test('', () {
        final Stream<List<int>> stream = Stream.fromIterable([
          [1, 2, 3, 4, 5],
          [6, 7, 8, 9, 0]
        ]);
        final ReadableStream readableStream = stream.asReadableStream();
        expect(
          readableStream.stream,
          emitsInOrder(<Matcher>[
            orderedEquals(<int>[1, 2, 3, 4, 5]),
            orderedEquals(<int>[6, 7, 8, 9, 0]),
            emitsDone,
          ]),
        );
        expect(
          readableStream.progress,
          emitsInOrder(<Object>[
            5,
            10,
            emitsDone,
          ]),
        );
      });

      test('onError (caught)', () async {
        final StreamController<List<int>> controller = StreamController();
        addTearDown(controller.close);

        Object? error;
        final ReadableStream readableStream =
            controller.stream.asReadableStream(
          onError: expectAsync2((e, st) {
            error = e;
          }),
        );
        controller.add([1, 2, 3, 4, 5]);
        controller.addError('failure');
        controller.add([6, 7, 8, 9, 0]);
        expect(
          readableStream.progress,
          emitsInOrder(<Object>[
            5,
            emitsDone,
          ]),
        );
        await expectLater(
          readableStream.stream,
          emitsInOrder(<Matcher>[
            orderedEquals(<int>[1, 2, 3, 4, 5]),
            emitsDone,
          ]),
        );
        expect(error, 'failure');
      });

      test('onError (unhandled)', () {
        final StreamController<List<int>> controller = StreamController();
        addTearDown(controller.close);

        final ReadableStream readableStream =
            controller.stream.asReadableStream();
        controller.add([1, 2, 3, 4, 5]);
        controller.addError('failure');
        controller.add([6, 7, 8, 9, 0]);
        expect(
          readableStream.stream,
          emitsInOrder(<Matcher>[
            orderedEquals(<int>[1, 2, 3, 4, 5]),
            emitsError('failure'),
            emitsDone,
          ]),
        );
        expect(
          readableStream.progress,
          emitsInOrder(<Object>[
            5,
            emitsDone,
          ]),
        );
      }, onPlatform: const <String, Object>{
        'safari': Skip('TODO: Investigate WebKit failures')
      });
    });

    group('asReadableStream (sync)', () {
      test('', () {
        final StreamController<List<int>> controller =
            StreamController(sync: true);
        final ReadableStream readableStream =
            controller.stream.asReadableStream();
        controller.add([1, 2, 3, 4, 5]);
        controller.add([6, 7, 8, 9, 0]);
        controller.close();
        expect(
          readableStream.stream,
          emitsInOrder(<Matcher>[
            orderedEquals(<int>[1, 2, 3, 4, 5]),
            orderedEquals(<int>[6, 7, 8, 9, 0]),
            emitsDone,
          ]),
        );
        expect(
          readableStream.progress,
          emitsInOrder(<Object>[
            5,
            10,
            emitsDone,
          ]),
        );
      });

      test('onError (caught)', () async {
        final StreamController<List<int>> controller =
            StreamController(sync: true);
        addTearDown(controller.close);

        Object? error;
        final ReadableStream readableStream =
            controller.stream.asReadableStream(
          onError: expectAsync2((e, st) {
            error = e;
          }),
        );
        controller.add([1, 2, 3, 4, 5]);
        controller.addError('failure');
        controller.add([6, 7, 8, 9, 0]);
        expect(
          readableStream.progress,
          emitsInOrder(<Object>[
            5,
            emitsDone,
          ]),
        );
        await expectLater(
          readableStream.stream,
          emitsInOrder(<Matcher>[
            orderedEquals(<int>[1, 2, 3, 4, 5]),
            emitsDone,
          ]),
        );
        expect(error, 'failure');
      });

      test('onError (unhandled)', () {
        final StreamController<List<int>> controller =
            StreamController(sync: true);
        addTearDown(controller.close);

        final ReadableStream readableStream =
            controller.stream.asReadableStream();
        controller.add([1, 2, 3, 4, 5]);
        controller.addError('failure');
        controller.add([6, 7, 8, 9, 0]);
        expect(
          readableStream.stream,
          emitsInOrder(<Matcher>[
            orderedEquals(<int>[1, 2, 3, 4, 5]),
            emitsError('failure'),
            emitsDone,
          ]),
        );
        expect(
          readableStream.progress,
          emitsInOrder(<Object>[
            5,
            emitsDone,
          ]),
        );
      }, onPlatform: const <String, Object>{
        'safari': Skip('TODO: Investigate WebKit failures')
      });
    });

    test('multiple streams can be expanded', () {
      final stream1 = createReadableStream();
      final stream2 = createReadableStream();

      expect(stream1.stream, isNot(stream2.stream));
    });
  });
}
