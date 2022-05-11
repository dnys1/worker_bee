// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'custom_type.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<CustomType> _$customTypeSerializer = new _$CustomTypeSerializer();

class _$CustomTypeSerializer implements StructuredSerializer<CustomType> {
  @override
  final Iterable<Type> types = const [CustomType, _$CustomType];
  @override
  final String wireName = 'CustomType';

  @override
  Iterable<Object?> serialize(Serializers serializers, CustomType object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object?>[
      'customField',
      serializers.serialize(object.customField,
          specifiedType: const FullType(String)),
    ];

    return result;
  }

  @override
  CustomType deserialize(Serializers serializers, Iterable<Object?> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new CustomTypeBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current! as String;
      iterator.moveNext();
      final Object? value = iterator.current;
      switch (key) {
        case 'customField':
          result.customField = serializers.deserialize(value,
              specifiedType: const FullType(String))! as String;
          break;
      }
    }

    return result.build();
  }
}

class _$CustomType extends CustomType {
  @override
  final String customField;

  factory _$CustomType([void Function(CustomTypeBuilder)? updates]) =>
      (new CustomTypeBuilder()..update(updates))._build();

  _$CustomType._({required this.customField}) : super._() {
    BuiltValueNullFieldError.checkNotNull(
        customField, 'CustomType', 'customField');
  }

  @override
  CustomType rebuild(void Function(CustomTypeBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  CustomTypeBuilder toBuilder() => new CustomTypeBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is CustomType && customField == other.customField;
  }

  @override
  int get hashCode {
    return $jf($jc(0, customField.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('CustomType')
          ..add('customField', customField))
        .toString();
  }
}

class CustomTypeBuilder implements Builder<CustomType, CustomTypeBuilder> {
  _$CustomType? _$v;

  String? _customField;
  String? get customField => _$this._customField;
  set customField(String? customField) => _$this._customField = customField;

  CustomTypeBuilder();

  CustomTypeBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _customField = $v.customField;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(CustomType other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$CustomType;
  }

  @override
  void update(void Function(CustomTypeBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  CustomType build() => _build();

  _$CustomType _build() {
    final _$result = _$v ??
        new _$CustomType._(
            customField: BuiltValueNullFieldError.checkNotNull(
                customField, 'CustomType', 'customField'));
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,deprecated_member_use_from_same_package,lines_longer_than_80_chars,no_leading_underscores_for_local_identifiers,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
