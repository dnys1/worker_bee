import 'package:built_value/serializer.dart';
import 'package:meta/meta.dart';
import 'package:worker_bee/worker_bee.dart';

import 'exception/stack_trace_serializer.dart';
import 'exception/worker_bee_exception.dart';

part 'serializers.g.dart';

/// Serializers common to all worker bees.
@internal
@SerializersFor([
  WorkerBeeExceptionImpl,
  LogMessage,
])
final Serializers workerBeeSerializers = (_$workerBeeSerializers.toBuilder()
      ..add(const StackTraceSerializer()))
    .build();
