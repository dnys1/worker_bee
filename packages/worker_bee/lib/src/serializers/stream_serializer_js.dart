import 'dart:async';
import 'dart:html';

import 'package:built_value/serializer.dart';
import 'package:meta/meta.dart';
import 'package:worker_bee/src/js/message_port_channel.dart';
import 'package:worker_bee/src/serializers/stream_serializer.dart';

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
    if (serialized is! MessagePort) {
      throw ArgumentError(
        'Cannot deserialize $serialized to Stream. Must be a MessagePort.',
      );
    }
    return serialized.onMessage.map((event) {
      return serializers.deserialize(event.data);
    });
  }

  @override
  Object serialize(
    Serializers serializers,
    Stream<Object?> object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final transfer = Zone.current[#transfer] as List<Object>?;
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
