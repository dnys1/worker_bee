import 'dart:async';

import 'package:async/async.dart';
import 'package:built_value/serializer.dart';
import 'package:meta/meta.dart';
import 'package:worker_bee/src/js/interop/common.dart';
import 'package:worker_bee/src/js/interop/readable_stream.dart';
import 'package:worker_bee/src/js/message_port_channel.dart';
import 'package:worker_bee/src/serializers/stream_serializer.dart';

/// A method which registers a pending operation with the worker.
typedef AddPendingOperation = void Function(CancelableOperation<void>);

/// {@template worker_bee.serializers.stream_serializer_impl_js}
/// JS implementation of [StreamSerializer].
///
/// Maps each stream to a [MessagePort] and uses `built_value` to
/// serialize/deserialize values across that port.
/// {@endtemplate}
@internal
class StreamSerializerImpl extends StreamSerializer {
  /// {@macro worker_bee.serializers.stream_serializer_impl_js}
  const StreamSerializerImpl() : super.protected();

  @override
  Stream<Object?> deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final addPendingOperation =
        Zone.current[#addPendingOperation] as AddPendingOperation?;

    // When the stream receives a listener, only then track its progress via
    // a `CancelableOperation`. To do this, wrap the stream in a separate
    // controller so that we have full control over the subscription lifecycle
    // events which will be overriden by the user-supplied ones on the
    // subcription returned from this method.
    StreamSubscription<Object?> onListen(
      Stream<Object?> stream,
      // ignore: avoid_positional_boolean_parameters
      bool cancelOnError,
    ) {
      final controller = StreamController<Object?>(sync: true);
      controller.onListen = () {
        late CancelableCompleter<void> completer;
        final subscription = stream.listen(
          controller.add,
          onError: (Object error, StackTrace stackTrace) {
            controller.addError(error, stackTrace);
            completer.completeError(error, stackTrace);
          },
          onDone: () {
            controller.close();
            completer.complete();
          },
          cancelOnError: cancelOnError,
        );
        completer = CancelableCompleter(onCancel: subscription.cancel);
        addPendingOperation?.call(completer.operation);

        controller
          ..onPause = subscription.pause
          ..onResume = subscription.resume
          ..onCancel = subscription.cancel;
      };
      return controller.stream.listen(null);
    }

    if (supportsTransferableStreams) {
      serialized as ReadableStream<Object?>;
      return serialized.stream
          .map(serializers.deserialize)
          .transform(StreamTransformer(onListen));
    }

    serialized as MessagePort;
    return MessagePortChannel<Object?>(
      serialized,
      serializers: serializers,
    ).stream.transform(StreamTransformer(onListen));
  }

  @override
  Object serialize(
    Serializers serializers,
    Stream<Object?> object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final transfer = Zone.current[#transfer] as List<Object>?;
    if (supportsTransferableStreams) {
      final readableStream =
          object.map(serializers.serialize).asReadableStream();
      transfer?.add(readableStream);
      return readableStream;
    }
    final messageChannel = MessageChannel();
    transfer?.add(messageChannel.port2);
    final workerBeeChannel = MessagePortChannel<Object?>(
      messageChannel.port1,
      serializers: serializers,
    );
    object.listen(
      workerBeeChannel.add,
      onError: workerBeeChannel.addError,
      onDone: workerBeeChannel.close,
      cancelOnError: true,
    );
    return messageChannel.port2;
  }
}
