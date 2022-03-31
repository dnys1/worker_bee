import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:worker_bee/worker_bee.dart';

part 'log_message.g.dart';

/// Log levels, mirroring those in `package:logging`.
class LogLevel extends EnumClass {
  /// Log level `ALL`
  @BuiltValueEnumConst(wireName: 'ALL')
  static const LogLevel all = _$all;

  /// Log level `OFF`
  @BuiltValueEnumConst(wireName: 'OFF')
  static const LogLevel off = _$off;

  /// Log level `SHOUT`
  @BuiltValueEnumConst(wireName: 'SHOUT')
  static const LogLevel shout = _$shout;

  /// Log level `SEVERE`
  @BuiltValueEnumConst(wireName: 'SEVERE')
  static const LogLevel severe = _$severe;

  /// Log level `WARNING`
  @BuiltValueEnumConst(wireName: 'WARNING')
  static const LogLevel warning = _$warning;

  /// Log level `INFO`
  @BuiltValueEnumConst(wireName: 'INFO')
  static const LogLevel info = _$info;

  /// Log level `CONFIG`
  @BuiltValueEnumConst(wireName: 'CONFIG')
  static const LogLevel config = _$config;

  /// Log level `FINE`
  @BuiltValueEnumConst(wireName: 'FINE')
  static const LogLevel fine = _$fine;

  /// Log level `FINER`
  @BuiltValueEnumConst(wireName: 'FINER')
  static const LogLevel finer = _$finer;

  /// Log level `FINEST`
  @BuiltValueEnumConst(wireName: 'FINEST')
  static const LogLevel finest = _$finest;

  const LogLevel._(String name) : super(name);

  /// All [LogLevel] values.
  static BuiltSet<LogLevel> get values => _$values;

  /// The [LogLevel] corresponding to [name].
  static LogLevel valueOf(String name) => _$valueOf(name);

  /// The [LogLevel] serializer.
  static Serializer<LogLevel> get serializer => _$logLevelSerializer;
}

/// {@template worker_bee.log_message}
/// A message logged by a worker bee.
/// {@endtemplate}
abstract class LogMessage implements Built<LogMessage, LogMessageBuilder> {
  /// {@macro worker_bee.log_message}
  factory LogMessage([void Function(LogMessageBuilder) updates]) = _$LogMessage;
  LogMessage._();

  /// Creates a [LogMessage] from a `package:logging` record.
  factory LogMessage.fromRecord(
    String workerName,
    LogRecord record, {
    required bool local,
  }) =>
      LogMessage(
        (b) => b
          ..workerName = workerName
          ..message = record.message
          ..local = local
          ..level = LogLevel.valueOf(record.level.name.toLowerCase())
          ..error = record.error?.toString()
          ..stackTrace = record.stackTrace,
      );

  /// The name of the worker that produced the log.
  String get workerName;

  /// The message of the log.
  String get message;

  /// Whether the log was produced locally or not.
  bool get local;

  /// The log level.
  LogLevel get level;

  /// The error associated with this log, if any.
  Object? get error;

  /// The stack trace associated with [error], if any.
  StackTrace? get stackTrace;

  /// The [LogMessage] serializer, for use in built_value.
  static Serializer<LogMessage> get serializer => _$logMessageSerializer;
}
