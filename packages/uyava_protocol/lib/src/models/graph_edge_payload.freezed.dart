// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'graph_edge_payload.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

UyavaGraphEdgePayload _$UyavaGraphEdgePayloadFromJson(
  Map<String, dynamic> json,
) {
  return _UyavaGraphEdgePayload.fromJson(json);
}

/// @nodoc
mixin _$UyavaGraphEdgePayload {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'source')
  String get source => throw _privateConstructorUsedError;
  @JsonKey(name: 'target')
  String get target => throw _privateConstructorUsedError;
  String? get label => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  bool get remapped => throw _privateConstructorUsedError;
  bool get bidirectional => throw _privateConstructorUsedError;

  /// Serializes this UyavaGraphEdgePayload to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of UyavaGraphEdgePayload
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $UyavaGraphEdgePayloadCopyWith<UyavaGraphEdgePayload> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UyavaGraphEdgePayloadCopyWith<$Res> {
  factory $UyavaGraphEdgePayloadCopyWith(
    UyavaGraphEdgePayload value,
    $Res Function(UyavaGraphEdgePayload) then,
  ) = _$UyavaGraphEdgePayloadCopyWithImpl<$Res, UyavaGraphEdgePayload>;
  @useResult
  $Res call({
    String id,
    @JsonKey(name: 'source') String source,
    @JsonKey(name: 'target') String target,
    String? label,
    String? description,
    bool remapped,
    bool bidirectional,
  });
}

/// @nodoc
class _$UyavaGraphEdgePayloadCopyWithImpl<
  $Res,
  $Val extends UyavaGraphEdgePayload
>
    implements $UyavaGraphEdgePayloadCopyWith<$Res> {
  _$UyavaGraphEdgePayloadCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of UyavaGraphEdgePayload
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? source = null,
    Object? target = null,
    Object? label = freezed,
    Object? description = freezed,
    Object? remapped = null,
    Object? bidirectional = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            source: null == source
                ? _value.source
                : source // ignore: cast_nullable_to_non_nullable
                      as String,
            target: null == target
                ? _value.target
                : target // ignore: cast_nullable_to_non_nullable
                      as String,
            label: freezed == label
                ? _value.label
                : label // ignore: cast_nullable_to_non_nullable
                      as String?,
            description: freezed == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                      as String?,
            remapped: null == remapped
                ? _value.remapped
                : remapped // ignore: cast_nullable_to_non_nullable
                      as bool,
            bidirectional: null == bidirectional
                ? _value.bidirectional
                : bidirectional // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$UyavaGraphEdgePayloadImplCopyWith<$Res>
    implements $UyavaGraphEdgePayloadCopyWith<$Res> {
  factory _$$UyavaGraphEdgePayloadImplCopyWith(
    _$UyavaGraphEdgePayloadImpl value,
    $Res Function(_$UyavaGraphEdgePayloadImpl) then,
  ) = __$$UyavaGraphEdgePayloadImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    @JsonKey(name: 'source') String source,
    @JsonKey(name: 'target') String target,
    String? label,
    String? description,
    bool remapped,
    bool bidirectional,
  });
}

/// @nodoc
class __$$UyavaGraphEdgePayloadImplCopyWithImpl<$Res>
    extends
        _$UyavaGraphEdgePayloadCopyWithImpl<$Res, _$UyavaGraphEdgePayloadImpl>
    implements _$$UyavaGraphEdgePayloadImplCopyWith<$Res> {
  __$$UyavaGraphEdgePayloadImplCopyWithImpl(
    _$UyavaGraphEdgePayloadImpl _value,
    $Res Function(_$UyavaGraphEdgePayloadImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of UyavaGraphEdgePayload
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? source = null,
    Object? target = null,
    Object? label = freezed,
    Object? description = freezed,
    Object? remapped = null,
    Object? bidirectional = null,
  }) {
    return _then(
      _$UyavaGraphEdgePayloadImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        source: null == source
            ? _value.source
            : source // ignore: cast_nullable_to_non_nullable
                  as String,
        target: null == target
            ? _value.target
            : target // ignore: cast_nullable_to_non_nullable
                  as String,
        label: freezed == label
            ? _value.label
            : label // ignore: cast_nullable_to_non_nullable
                  as String?,
        description: freezed == description
            ? _value.description
            : description // ignore: cast_nullable_to_non_nullable
                  as String?,
        remapped: null == remapped
            ? _value.remapped
            : remapped // ignore: cast_nullable_to_non_nullable
                  as bool,
        bidirectional: null == bidirectional
            ? _value.bidirectional
            : bidirectional // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$UyavaGraphEdgePayloadImpl extends _UyavaGraphEdgePayload {
  const _$UyavaGraphEdgePayloadImpl({
    required this.id,
    @JsonKey(name: 'source') required this.source,
    @JsonKey(name: 'target') required this.target,
    this.label,
    this.description,
    this.remapped = false,
    this.bidirectional = false,
  }) : super._();

  factory _$UyavaGraphEdgePayloadImpl.fromJson(Map<String, dynamic> json) =>
      _$$UyavaGraphEdgePayloadImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'source')
  final String source;
  @override
  @JsonKey(name: 'target')
  final String target;
  @override
  final String? label;
  @override
  final String? description;
  @override
  @JsonKey()
  final bool remapped;
  @override
  @JsonKey()
  final bool bidirectional;

  @override
  String toString() {
    return 'UyavaGraphEdgePayload(id: $id, source: $source, target: $target, label: $label, description: $description, remapped: $remapped, bidirectional: $bidirectional)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UyavaGraphEdgePayloadImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.source, source) || other.source == source) &&
            (identical(other.target, target) || other.target == target) &&
            (identical(other.label, label) || other.label == label) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.remapped, remapped) ||
                other.remapped == remapped) &&
            (identical(other.bidirectional, bidirectional) ||
                other.bidirectional == bidirectional));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    source,
    target,
    label,
    description,
    remapped,
    bidirectional,
  );

  /// Create a copy of UyavaGraphEdgePayload
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UyavaGraphEdgePayloadImplCopyWith<_$UyavaGraphEdgePayloadImpl>
  get copyWith =>
      __$$UyavaGraphEdgePayloadImplCopyWithImpl<_$UyavaGraphEdgePayloadImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$UyavaGraphEdgePayloadImplToJson(this);
  }
}

abstract class _UyavaGraphEdgePayload extends UyavaGraphEdgePayload {
  const factory _UyavaGraphEdgePayload({
    required final String id,
    @JsonKey(name: 'source') required final String source,
    @JsonKey(name: 'target') required final String target,
    final String? label,
    final String? description,
    final bool remapped,
    final bool bidirectional,
  }) = _$UyavaGraphEdgePayloadImpl;
  const _UyavaGraphEdgePayload._() : super._();

  factory _UyavaGraphEdgePayload.fromJson(Map<String, dynamic> json) =
      _$UyavaGraphEdgePayloadImpl.fromJson;

  @override
  String get id;
  @override
  @JsonKey(name: 'source')
  String get source;
  @override
  @JsonKey(name: 'target')
  String get target;
  @override
  String? get label;
  @override
  String? get description;
  @override
  bool get remapped;
  @override
  bool get bidirectional;

  /// Create a copy of UyavaGraphEdgePayload
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UyavaGraphEdgePayloadImplCopyWith<_$UyavaGraphEdgePayloadImpl>
  get copyWith => throw _privateConstructorUsedError;
}
