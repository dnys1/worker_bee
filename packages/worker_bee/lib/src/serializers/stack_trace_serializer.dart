import 'package:built_value/serializer.dart';
import 'package:meta/meta.dart';
import 'package:stack_trace/stack_trace.dart';

/// {@template worker_bee.exception.stack_trace_serializer}
/// Serializer for [StackTrace] objects for sending on the wire.
/// {@endtemplate}
@internal
class StackTraceSerializer implements PrimitiveSerializer<StackTrace> {
  /// {@macro worker_bee.exception.stack_trace_serializer}
  const StackTraceSerializer();

  @override
  String get wireName => 'StackTrace';

  @override
  Iterable<Type> get types => [
        StackTrace,
        StackTrace.empty.runtimeType,
        StackTrace.current.runtimeType,
        Trace,
        Chain,
      ];

  @override
  StackTrace deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    if (serialized is StackTrace) {
      return serialized;
    }
    if (serialized is String) {
      return Trace.parse(serialized);
    }
    if (serialized is List<String>) {
      return Trace(serialized.map(Frame.parseFriendly));
    }
    throw ArgumentError(
      'Unknown StackFrame type (${serialized.runtimeType}): $serialized',
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    StackTrace object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return Trace.format(object);
  }
}
