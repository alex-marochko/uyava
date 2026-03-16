// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'metric_definition_payload.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

UyavaMetricDefinitionPayload _$UyavaMetricDefinitionPayloadFromJson(
  Map<String, dynamic> json,
) {
  return _UyavaMetricDefinitionPayload.fromJson(json);
}

/// @nodoc
mixin _$UyavaMetricDefinitionPayload {
  String get id => throw _privateConstructorUsedError;
  String? get label => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  String? get unit => throw _privateConstructorUsedError;
  List<String> get tags => throw _privateConstructorUsedError;
  @JsonKey(name: 'tagsNormalized')
  List<String> get tagsNormalized => throw _privateConstructorUsedError;
  List<UyavaMetricAggregator> get aggregators =>
      throw _privateConstructorUsedError;

  /// Serializes this UyavaMetricDefinitionPayload to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of UyavaMetricDefinitionPayload
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $UyavaMetricDefinitionPayloadCopyWith<UyavaMetricDefinitionPayload>
  get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UyavaMetricDefinitionPayloadCopyWith<$Res> {
  factory $UyavaMetricDefinitionPayloadCopyWith(
    UyavaMetricDefinitionPayload value,
    $Res Function(UyavaMetricDefinitionPayload) then,
  ) =
      _$UyavaMetricDefinitionPayloadCopyWithImpl<
        $Res,
        UyavaMetricDefinitionPayload
      >;
  @useResult
  $Res call({
    String id,
    String? label,
    String? description,
    String? unit,
    List<String> tags,
    @JsonKey(name: 'tagsNormalized') List<String> tagsNormalized,
    List<UyavaMetricAggregator> aggregators,
  });
}

/// @nodoc
class _$UyavaMetricDefinitionPayloadCopyWithImpl<
  $Res,
  $Val extends UyavaMetricDefinitionPayload
>
    implements $UyavaMetricDefinitionPayloadCopyWith<$Res> {
  _$UyavaMetricDefinitionPayloadCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of UyavaMetricDefinitionPayload
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? label = freezed,
    Object? description = freezed,
    Object? unit = freezed,
    Object? tags = null,
    Object? tagsNormalized = null,
    Object? aggregators = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            label: freezed == label
                ? _value.label
                : label // ignore: cast_nullable_to_non_nullable
                      as String?,
            description: freezed == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                      as String?,
            unit: freezed == unit
                ? _value.unit
                : unit // ignore: cast_nullable_to_non_nullable
                      as String?,
            tags: null == tags
                ? _value.tags
                : tags // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            tagsNormalized: null == tagsNormalized
                ? _value.tagsNormalized
                : tagsNormalized // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            aggregators: null == aggregators
                ? _value.aggregators
                : aggregators // ignore: cast_nullable_to_non_nullable
                      as List<UyavaMetricAggregator>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$UyavaMetricDefinitionPayloadImplCopyWith<$Res>
    implements $UyavaMetricDefinitionPayloadCopyWith<$Res> {
  factory _$$UyavaMetricDefinitionPayloadImplCopyWith(
    _$UyavaMetricDefinitionPayloadImpl value,
    $Res Function(_$UyavaMetricDefinitionPayloadImpl) then,
  ) = __$$UyavaMetricDefinitionPayloadImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String? label,
    String? description,
    String? unit,
    List<String> tags,
    @JsonKey(name: 'tagsNormalized') List<String> tagsNormalized,
    List<UyavaMetricAggregator> aggregators,
  });
}

/// @nodoc
class __$$UyavaMetricDefinitionPayloadImplCopyWithImpl<$Res>
    extends
        _$UyavaMetricDefinitionPayloadCopyWithImpl<
          $Res,
          _$UyavaMetricDefinitionPayloadImpl
        >
    implements _$$UyavaMetricDefinitionPayloadImplCopyWith<$Res> {
  __$$UyavaMetricDefinitionPayloadImplCopyWithImpl(
    _$UyavaMetricDefinitionPayloadImpl _value,
    $Res Function(_$UyavaMetricDefinitionPayloadImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of UyavaMetricDefinitionPayload
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? label = freezed,
    Object? description = freezed,
    Object? unit = freezed,
    Object? tags = null,
    Object? tagsNormalized = null,
    Object? aggregators = null,
  }) {
    return _then(
      _$UyavaMetricDefinitionPayloadImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        label: freezed == label
            ? _value.label
            : label // ignore: cast_nullable_to_non_nullable
                  as String?,
        description: freezed == description
            ? _value.description
            : description // ignore: cast_nullable_to_non_nullable
                  as String?,
        unit: freezed == unit
            ? _value.unit
            : unit // ignore: cast_nullable_to_non_nullable
                  as String?,
        tags: null == tags
            ? _value._tags
            : tags // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        tagsNormalized: null == tagsNormalized
            ? _value._tagsNormalized
            : tagsNormalized // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        aggregators: null == aggregators
            ? _value._aggregators
            : aggregators // ignore: cast_nullable_to_non_nullable
                  as List<UyavaMetricAggregator>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$UyavaMetricDefinitionPayloadImpl extends _UyavaMetricDefinitionPayload {
  const _$UyavaMetricDefinitionPayloadImpl({
    required this.id,
    this.label,
    this.description,
    this.unit,
    final List<String> tags = const <String>[],
    @JsonKey(name: 'tagsNormalized')
    final List<String> tagsNormalized = const <String>[],
    final List<UyavaMetricAggregator> aggregators =
        const <UyavaMetricAggregator>[UyavaMetricAggregator.last],
  }) : _tags = tags,
       _tagsNormalized = tagsNormalized,
       _aggregators = aggregators,
       super._();

  factory _$UyavaMetricDefinitionPayloadImpl.fromJson(
    Map<String, dynamic> json,
  ) => _$$UyavaMetricDefinitionPayloadImplFromJson(json);

  @override
  final String id;
  @override
  final String? label;
  @override
  final String? description;
  @override
  final String? unit;
  final List<String> _tags;
  @override
  @JsonKey()
  List<String> get tags {
    if (_tags is EqualUnmodifiableListView) return _tags;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_tags);
  }

  final List<String> _tagsNormalized;
  @override
  @JsonKey(name: 'tagsNormalized')
  List<String> get tagsNormalized {
    if (_tagsNormalized is EqualUnmodifiableListView) return _tagsNormalized;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_tagsNormalized);
  }

  final List<UyavaMetricAggregator> _aggregators;
  @override
  @JsonKey()
  List<UyavaMetricAggregator> get aggregators {
    if (_aggregators is EqualUnmodifiableListView) return _aggregators;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_aggregators);
  }

  @override
  String toString() {
    return 'UyavaMetricDefinitionPayload(id: $id, label: $label, description: $description, unit: $unit, tags: $tags, tagsNormalized: $tagsNormalized, aggregators: $aggregators)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UyavaMetricDefinitionPayloadImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.label, label) || other.label == label) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.unit, unit) || other.unit == unit) &&
            const DeepCollectionEquality().equals(other._tags, _tags) &&
            const DeepCollectionEquality().equals(
              other._tagsNormalized,
              _tagsNormalized,
            ) &&
            const DeepCollectionEquality().equals(
              other._aggregators,
              _aggregators,
            ));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    label,
    description,
    unit,
    const DeepCollectionEquality().hash(_tags),
    const DeepCollectionEquality().hash(_tagsNormalized),
    const DeepCollectionEquality().hash(_aggregators),
  );

  /// Create a copy of UyavaMetricDefinitionPayload
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UyavaMetricDefinitionPayloadImplCopyWith<
    _$UyavaMetricDefinitionPayloadImpl
  >
  get copyWith =>
      __$$UyavaMetricDefinitionPayloadImplCopyWithImpl<
        _$UyavaMetricDefinitionPayloadImpl
      >(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$UyavaMetricDefinitionPayloadImplToJson(this);
  }
}

abstract class _UyavaMetricDefinitionPayload
    extends UyavaMetricDefinitionPayload {
  const factory _UyavaMetricDefinitionPayload({
    required final String id,
    final String? label,
    final String? description,
    final String? unit,
    final List<String> tags,
    @JsonKey(name: 'tagsNormalized') final List<String> tagsNormalized,
    final List<UyavaMetricAggregator> aggregators,
  }) = _$UyavaMetricDefinitionPayloadImpl;
  const _UyavaMetricDefinitionPayload._() : super._();

  factory _UyavaMetricDefinitionPayload.fromJson(Map<String, dynamic> json) =
      _$UyavaMetricDefinitionPayloadImpl.fromJson;

  @override
  String get id;
  @override
  String? get label;
  @override
  String? get description;
  @override
  String? get unit;
  @override
  List<String> get tags;
  @override
  @JsonKey(name: 'tagsNormalized')
  List<String> get tagsNormalized;
  @override
  List<UyavaMetricAggregator> get aggregators;

  /// Create a copy of UyavaMetricDefinitionPayload
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UyavaMetricDefinitionPayloadImplCopyWith<
    _$UyavaMetricDefinitionPayloadImpl
  >
  get copyWith => throw _privateConstructorUsedError;
}
