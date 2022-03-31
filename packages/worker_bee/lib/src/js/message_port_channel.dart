import 'dart:async';
import 'dart:html';

import 'package:built_value/serializer.dart';
import 'package:worker_bee/src/serializers.dart';
import 'package:worker_bee/worker_bee.dart';

/// {@template worker_bee.message_port_channel}
/// An abstraction over [MessagePort] which conforms to [StreamChannel].
/// {@endtemplate}
class MessagePortChannel<T>
    with StreamChannelMixin<T>
    implements StreamSink<T> {
  /// {@macro worker_bee.message_port_channel}
  MessagePortChannel(this.messagePort, {Serializers? serializers})
      : _serializers = serializers ?? workerBeeSerializers;

  /// The message port to communicate over.
  final MessagePort messagePort;

  final Serializers _serializers;

  @override
  StreamSink<T> get sink => this;

  @override
  Stream<T> get stream => messagePort.onMessage.transform(
        StreamTransformer<MessageEvent, T>.fromHandlers(
          handleData: (event, sink) {
            final data = _serializers.deserialize(event.data);
            if (data is T) {
              sink.add(data);
            } else {
              sink.addError(data as Object);
            }
          },
        ),
      );

  @override
  void add(T event) => messagePort.postMessage(_serializers.serialize(event));

  @override
  void addError(Object error, [StackTrace? stackTrace]) {
    messagePort.postMessage(_serializers.serialize(
      WebWorkerException(error, stackTrace: stackTrace),
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
