@internal
library aws_http.js.readable_stream;

import 'dart:async';

import 'package:async/async.dart';
import 'package:js/js.dart';
import 'package:js/js_util.dart' as js_util;
import 'package:meta/meta.dart';

import 'common.dart';
import 'promise.dart';

/// Whether the current browser supports transferring [ReadableStream].
bool get supportsTransferableStreams {
  final rs = ReadableStream();
  try {
    final MessageChannel channel = MessageChannel();
    channel.port1.postMessage(rs, [rs]);
    return true;
  } on Object {
    return false;
  }
}

/// {@template aws_http.js.readable_stream}
/// An object containing methods and properties that define how the constructed
/// [ReadableStream] will behave.
/// {@endtemplate}
@JS()
@staticInterop
@anonymous
class UnderlyingSource {
  /// {@macro aws_http.js.readable_stream}
  factory UnderlyingSource({
    /// This is a method, called immediately when the object is constructed.
    ///
    /// The contents of this method are defined by the developer, and should aim
    /// to get access to the stream source, and do anything else required to set
    /// up the stream functionality. If this process is to be done
    /// asynchronously, it can return a promise to signal success or failure.
    ///
    /// The `controller` parameter passed to this method is a
    /// [ReadableStreamDefaultController] or a [ReadableByteStreamController],
    /// depending on the value of the `type` property. This can be used by the
    /// developer to control the stream during set up.
    FutureOr<void> Function(ReadableStreamController controller)? start,

    /// This method, also defined by the developer, will be called repeatedly
    /// when the stream's internal queue of chunks is not full, up until it
    /// reaches its high water mark.
    ///
    /// If pull() returns a promise, then it won't be called again until that
    /// promise fulfills; if the promise rejects, the stream will become
    /// errored.
    ///
    /// The `controller` parameter passed to this method is a
    /// [ReadableStreamDefaultController] or a [ReadableByteStreamController],
    /// depending on the value of the type property. This can be used by the
    /// developer to control the stream as more chunks are fetched.
    FutureOr<void> Function(ReadableStreamController controller)? pull,

    /// This method, also defined by the developer, will be called if the app
    /// signals that the stream is to be cancelled
    /// (e.g. if [ReadableStream.cancel] is called).
    ///
    /// The contents should do whatever is necessary to release access to the
    /// stream source. If this process is asynchronous, it can return a promise
    /// to signal success or failure. The reason parameter contains a
    /// `DOMString` describing why the stream was cancelled.
    FutureOr<void> Function([
      String? reason,
      ReadableStreamController? controller,
    ])?
        cancel,

    /// This property controls what type of readable stream is being dealt with.
    ReadableStreamType type = ReadableStreamType.default$,

    /// For byte streams, the developer can set the autoAllocateChunkSize with
    /// a positive integer value to turn on the stream's auto-allocation
    /// feature.
    ///
    /// With this turned on, the stream implementation will automatically
    /// allocate an `ArrayBuffer` with a size of the given integer, and the
    /// consumer can also use a default reader.
    int? autoAllocateChunkSize,
  }) {
    final startFn = start == null
        ? undefined
        : start is Future<void> Function(ReadableStreamController)
            ? allowInterop((ReadableStreamController controller) {
                return Promise.fromFuture(start(controller));
              })
            : allowInterop(start);
    final pullFn = pull == null
        ? undefined
        : pull is Future<void> Function(ReadableStreamController)
            ? allowInterop((ReadableStreamController controller) {
                return Promise.fromFuture(pull(controller));
              })
            : allowInterop(pull);
    final cancelFn = cancel == null
        ? undefined
        : cancel is Future<void> Function([
            String? reason,
            ReadableStreamController? controller,
          ])
            ? allowInterop(
                (String? reason, ReadableStreamController controller) {
                return Promise.fromFuture(cancel(reason, controller));
              })
            : allowInterop(cancel);
    return UnderlyingSource._(
      start: startFn,
      pull: pullFn,
      cancel: cancelFn,
      type: type.jsValue,
      autoAllocateChunkSize: autoAllocateChunkSize ?? undefined,
    );
  }

  external factory UnderlyingSource._({
    Object? start,
    Object? pull,
    Object? cancel,
    String? type,
    int? autoAllocateChunkSize,
  });
}

/// The type of [ReadableStream] and its associated [ReadableStreamController].
enum ReadableStreamType with JSEnum {
  /// Creates a [ReadableByteStreamController] capable of handling a BYOB
  /// (bring your own buffer)/byte stream.
  bytes,

  /// Creates a [ReadableStreamDefaultController].
  default$,
}

/// {@template worker_bee.js.interop.readable_stream_controller}
/// A controller allowing control of a [ReadableStream]'s state and internal
/// queue.
/// {@endtemplate}
@JS()
@staticInterop
abstract class ReadableStreamController<T> {}

/// {@macro worker_bee.js.interop.readable_stream_controller}
extension PropsReadableStreamController<T> on ReadableStreamController<T> {
  /// The desired size required to fill the stream's internal queue.
  external int get desiredSize;

  /// Closes the associated stream.
  external void close();

  /// Enqueues a given chunk in the associated stream.
  external void enqueue(T chunk);
}

/// {@macro worker_bee.js.interop.readable_stream_controller}
@JS()
@staticInterop
class ReadableStreamDefaultController<T> extends ReadableStreamController<T> {}

/// {@macro worker_bee.js.interop.readable_stream_controller}
@JS()
@staticInterop
class ReadableByteStreamController<T> extends ReadableStreamController<T> {}

/// {@template worker_bee.js.interop.readable_stream}
/// A readable stream of data.
/// {@endtemplate}
@JS()
@staticInterop
class ReadableStream<T extends Object?> {
  /// {@macro worker_bee.js.interop.readable_stream}
  external factory ReadableStream([UnderlyingSource? underlyingSource]);
}

/// Used to expand [ReadableStream] and treat [ReadableStream.stream] as a
/// `late final` property so that multiple accesses return the same value.
final Expando<ReadableStreamView> _readableStreamViews =
    Expando('ReadableStreamViews');

/// {@macro worker_bee.js.interop.readable_stream}
extension PropsReadableStream<T extends Object?> on ReadableStream<T> {
  /// Whether or not the readable stream is locked to a reader.
  external bool get locked;

  /// Returns a Promise that resolves when the stream is canceled.
  ///
  /// Calling this method signals a loss of interest in the stream by a
  /// consumer. The supplied reason argument will be given to the underlying
  /// source, which may or may not use it.
  Future<void> cancel([String? reason]) =>
      js_util.promiseToFuture(js_util.callMethod(this, 'cancel', [reason]));

  /// Creates a reader and locks the stream to it.
  ///
  /// While the stream is locked, no other reader can be acquired until this one
  /// is released.
  ReadableStreamReader getReader({
    ReadableStreamReaderMode mode = ReadableStreamReaderMode.default$,
  }) =>
      js_util.callMethod(this, 'getReader', [mode.jsValue]);

  /// Creates a Dart [Stream] from `this`.
  Stream<T> get stream =>
      (_readableStreamViews[this] ??= ReadableStreamView<T>(this)) as Stream<T>;

  /// The progress (in bytes) of [stream].
  Stream<int> get progress => (stream as ReadableStreamView).progress;
}

/// {@template worker_bee.js.interop.readable_stream_reader}
/// An object used to read stream data which holds a lock on the stream while
/// it reads.
/// {@endtemplate}
@JS()
@staticInterop
abstract class ReadableStreamReader {}

/// {@macro worker_bee.js.interop.readable_stream_reader}
extension PropsReadableStreamReader on ReadableStreamReader {
  /// Returns a Promise that fulfills when the stream closes, or rejects if the
  /// stream throws an error or the reader's lock is released.
  ///
  /// This property enables you to write code that responds to an end to the
  /// streaming process.
  Future<void> get closed =>
      js_util.promiseToFuture(js_util.getProperty(this, 'closed'));

  /// Returns a Promise that resolves when the stream is canceled.
  ///
  /// Calling this method signals a loss of interest in the stream by a
  /// consumer. The supplied reason argument will be given to the underlying
  /// source, which may or may not use it.
  Future<void> cancel([String? reason]) =>
      js_util.promiseToFuture(js_util.callMethod(this, 'cancel', [reason]));

  /// Releases the reader's lock on the stream.
  external void releaseLock();
}

/// {@macro worker_bee.js.interop.readable_stream_reader}
@JS()
@staticInterop
class ReadableStreamBYOBReader extends ReadableStreamReader {}

/// {@macro worker_bee.js.interop.readable_stream_reader}
@JS()
@staticInterop
class ReadableStreamDefaultReader extends ReadableStreamReader {}

/// {@macro worker_bee.js.interop.readable_stream_reader}
extension PropsReadableStreamDefaultReader on ReadableStreamDefaultReader {
  /// Returns a promise providing access to the next chunk in the stream's
  /// internal queue.
  Future<ReadableStreamChunk<T>> read<T extends Object?>() =>
      js_util.promiseToFuture(js_util.callMethod(this, 'read', []));
}

/// Specifies the type of [ReadableStreamReader] to create.
enum ReadableStreamReaderMode with JSEnum {
  /// Results in a [ReadableStreamBYOBReader] being created that can read
  /// readable byte streams (i.e. can handle "bring your own buffer" reading).
  byob,

  /// Results in a [ReadableStreamDefaultReader] being created that can read
  /// individual chunks from a stream.
  default$
}

/// {@template worker_bee.js.interop.readable_stream_chunk}
/// A chunk delivered to a [ReadableStream].
/// {@endtemplate}
@JS()
@staticInterop
@anonymous
abstract class ReadableStreamChunk<T extends Object?> {}

/// {@macro worker_bee.js.interop.readable_stream_chunk}
extension PropsReadableStreamChunk<T extends Object?>
    on ReadableStreamChunk<T> {
  /// The chunk of data.
  ///
  /// Always `null` when [done] is `true`.
  external T? get value;

  /// Whether the stream is done producing values.
  external bool get done;
}

/// {@template aws_http.js.readable_stream_view}
/// Wraps a [ReadableStream] as a Dart [Stream].
/// {@endtemplate}
class ReadableStreamView<T extends Object?> extends StreamView<T> {
  /// {@macro aws_http.js.readable_stream_view}
  factory ReadableStreamView(ReadableStream<T> stream) {
    // Closed in `_pipe`.
    // ignore: close_sinks
    final controller = StreamController<T>(sync: true);
    // ignore: close_sinks
    final progressController = StreamController<int>.broadcast(sync: true);
    _pipeFrom(stream, controller.sink, progressController.sink);
    return ReadableStreamView._(
      controller.stream,
      progressController.stream,
    );
  }

  const ReadableStreamView._(super.stream, this.progress);

  /// The number of bytes read so far.
  ///
  /// Closes when `this` closes.
  final Stream<int> progress;

  static Future<void> _pipeFrom<T extends Object?>(
    ReadableStream stream,
    StreamSink<T> sink,
    StreamSink<int> progressSink,
  ) async {
    try {
      final reader = stream.getReader() as ReadableStreamDefaultReader;
      var bytesRead = 0;
      while (true) {
        final chunk = await reader.read<T>();
        final value = chunk.value;
        if (chunk.done || value is! T) {
          break;
        }
        if (value is List<int>) {
          bytesRead += value.length;
          progressSink.add(bytesRead);
        }
        sink.add(value);
      }
    } on Object catch (e, st) {
      sink.addError(e, st);
    } finally {
      sink.close();
      progressSink.close();
    }
  }
}

/// {@template aws_http.js.stream_to_readable_stream}
/// Creates a [ReadableStream] from `this`.
/// {@endtemplate}
extension StreamToReadableStream<T> on Stream<T> {
  /// {@macro aws_http.js.stream_to_readable_stream}
  ReadableStream asReadableStream({
    void Function(Object, StackTrace)? onError,
  }) {
    final queue = StreamQueue(this);
    return ReadableStream(
      UnderlyingSource(
        pull: (controller) async {
          try {
            if (!await queue.hasNext) {
              await queue.cancel();
              controller.close();
              return;
            }
            final chunk = await queue.next;
            controller.enqueue(chunk);
          } on Object catch (e, st) {
            await queue.cancel();
            // Allow error to propogate before closing.
            scheduleMicrotask(controller.close);
            if (onError == null) {
              rethrow;
            }
            onError.call(e, st);
          }
        },
      ),
    );
  }
}
