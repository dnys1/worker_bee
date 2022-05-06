import 'dart:async';
import 'dart:html';

import 'package:built_value/serializer.dart';
import 'package:worker_bee/src/exception/worker_bee_exception.dart';
import 'package:worker_bee/src/serializers/serializers.dart';
import 'package:worker_bee/worker_bee.dart';

/// {@template worker_bee.message_port_channel}
/// An abstraction over [MessagePort] which conforms to [StreamChannel].
/// {@endtemplate}
class MessagePortChannel<T>
    with StreamChannelMixin<T>
    implements StreamSink<T> {
  /// {@macro worker_bee.message_port_channel}
  MessagePortChannel(
    this.messagePort, {
    Serializers? serializers,
    FullType specifiedType = FullType.unspecified,
  })  : _serializers = serializers ?? workerBeeSerializers,
        _specifiedType = specifiedType;

  /// The message port to communicate over.
  final MessagePort messagePort;

  final Serializers _serializers;
  final FullType _specifiedType;

  @override
  StreamSink<T> get sink => this;

  @override
  Stream<T> get stream => messagePort.onMessage.transform(
        StreamTransformer<MessageEvent, T>.fromHandlers(
          handleData: (event, sink) {
            final data = _serializers.deserialize(
              event.data,
              specifiedType: _specifiedType,
            );
            if (data is T) {
              sink.add(data);
            } else {
              sink.addError(data as Object);
            }
          },
        ),
      );

  @override
  void add(T event) {
    final transfer = <Object>[];
    final serialized = runZoned(
      () => _serializers.serialize(
        event,
        specifiedType: _specifiedType,
      ),
      zoneValues: {
        #transfer: transfer,
      },
    );
    messagePort.postMessage(serialized, transfer);
  }

  @override
  void addError(Object error, [StackTrace? stackTrace]) {
    messagePort.postMessage(_serializers.serialize(
      WorkerBeeExceptionImpl(error, stackTrace),
      specifiedType: FullType.unspecified,
    ));
  }

  @override
  Future<void> addStream(Stream<dynamic> stream) async {
    await for (final event in stream) {
      add(event);
    }
  }

  final Completer<void> _done = Completer<void>.sync();

  @override
  Future<void> close() async {
    messagePort.close();
    _done.complete();
  }

  @override
  Future<void> get done => _done.future;
}
