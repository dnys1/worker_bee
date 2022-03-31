import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:worker_bee/worker_bee.dart';

part 'log_message.g.dart';

class LogLevel extends EnumClass {
  @BuiltValueEnumConst(wireName: 'ALL')
  static const LogLevel all = _$all;

  @BuiltValueEnumConst(wireName: 'OFF')
  static const LogLevel off = _$off;

  @BuiltValueEnumConst(wireName: 'SHOUT')
  static const LogLevel shout = _$shout;

  @BuiltValueEnumConst(wireName: 'SEVERE')
  static const LogLevel severe = _$severe;

  @BuiltValueEnumConst(wireName: 'WARNING')
  static const LogLevel warning = _$warning;

  @BuiltValueEnumConst(wireName: 'INFO')
  static const LogLevel info = _$info;

  @BuiltValueEnumConst(wireName: 'CONFIG')
  static const LogLevel config = _$config;

  @BuiltValueEnumConst(wireName: 'FINE')
  static const LogLevel fine = _$fine;

  @BuiltValueEnumConst(wireName: 'FINER')
  static const LogLevel finer = _$finer;

  @BuiltValueEnumConst(wireName: 'FINEST')
  static const LogLevel finest = _$finest;

  const LogLevel._(String name) : super(name);

  static BuiltSet<LogLevel> get values => _$values;
  static LogLevel valueOf(String name) => _$valueOf(name);
  static Serializer<LogLevel> get serializer => _$logLevelSerializer;
}

abstract class LogMessage implements Built<LogMessage, LogMessageBuilder> {
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
