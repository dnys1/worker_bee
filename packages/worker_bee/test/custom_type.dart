import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'custom_type.g.dart';

abstract class CustomType implements Built<CustomType, CustomTypeBuilder> {
  CustomType._();
  factory CustomType([void Function(CustomTypeBuilder) updates]) = _$CustomType;

  String get customField;

  static Serializer<CustomType> get serializer => _$customTypeSerializer;
}
