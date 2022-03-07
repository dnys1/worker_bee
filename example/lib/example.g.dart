// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'example.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<MyMessage> _$myMessageSerializer = new _$MyMessageSerializer();

class _$MyMessageSerializer implements StructuredSerializer<MyMessage> {
  @override
  final Iterable<Type> types = const [MyMessage, _$MyMessage];
  @override
  final String wireName = 'MyMessage';

  @override
  Iterable<Object?> serialize(Serializers serializers, MyMessage object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object?>[
      'data',
      serializers.serialize(object.data,
          specifiedType: const FullType(Uint8List)),
    ];

    return result;
  }

  @override
  MyMessage deserialize(Serializers serializers, Iterable<Object?> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new MyMessageBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current as String;
      iterator.moveNext();
      final Object? value = iterator.current;
      switch (key) {
        case 'data':
          result.data = serializers.deserialize(value,
              specifiedType: const FullType(Uint8List)) as Uint8List;
          break;
      }
    }

    return result.build();
  }
}

class _$MyMessage extends MyMessage {
  @override
  final Uint8List data;

  factory _$MyMessage([void Function(MyMessageBuilder)? updates]) =>
      (new MyMessageBuilder()..update(updates)).build();

  _$MyMessage._({required this.data}) : super._() {
    BuiltValueNullFieldError.checkNotNull(data, 'MyMessage', 'data');
  }

  @override
  MyMessage rebuild(void Function(MyMessageBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  MyMessageBuilder toBuilder() => new MyMessageBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is MyMessage && data == other.data;
  }

  @override
  int get hashCode {
    return $jf($jc(0, data.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('MyMessage')..add('data', data))
        .toString();
  }
}

class MyMessageBuilder implements Builder<MyMessage, MyMessageBuilder> {
  _$MyMessage? _$v;

  Uint8List? _data;
  Uint8List? get data => _$this._data;
  set data(Uint8List? data) => _$this._data = data;

  MyMessageBuilder();

  MyMessageBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _data = $v.data;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(MyMessage other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$MyMessage;
  }

  @override
  void update(void Function(MyMessageBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  _$MyMessage build() {
    final _$result = _$v ??
        new _$MyMessage._(
            data: BuiltValueNullFieldError.checkNotNull(
                data, 'MyMessage', 'data'));
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,deprecated_member_use_from_same_package,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
