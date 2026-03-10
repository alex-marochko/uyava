// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'graph_node_payload.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

UyavaGraphNodePayload _$UyavaGraphNodePayloadFromJson(
  Map<String, dynamic> json,
) {
  return _UyavaGraphNodePayload.fromJson(json);
}

/// @nodoc
mixin _$UyavaGraphNodePayload {
  String get id => throw _privateConstructorUsedError;
  String get type => throw _privateConstructorUsedError;
  String get label => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  String? get parentId => throw _privateConstructorUsedError;
  List<String> get tags => throw _privateConstructorUsedError;
  @JsonKey(name: 'tagsNormalized')
  List<String> get tagsNormalized => throw _privateConstructorUsedError;
  @JsonKey(name: 'tagsCatalog')
  List<String>? get tagsCatalog => throw _privateConstructorUsedError;
  String? get color => throw _privateConstructorUsedError;
  @JsonKey(name: 'colorPriorityIndex')
  int? get colorPriorityIndex => throw _privateConstructorUsedError;
  String? get shape => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _lifecycleFromJson, toJson: _lifecycleToJson)
  UyavaLifecycleState get lifecycle => throw _privateConstructorUsedError;
  @JsonKey(name: UyavaPayloadKeys.initSource)
  String? get initSource => throw _privateConstructorUsedError;

  /// Serializes this UyavaGraphNodePayload to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of UyavaGraphNodePayload
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $UyavaGraphNodePayloadCopyWith<UyavaGraphNodePayload> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UyavaGraphNodePayloadCopyWith<$Res> {
  factory $UyavaGraphNodePayloadCopyWith(
    UyavaGraphNodePayload value,
    $Res Function(UyavaGraphNodePayload) then,
  ) = _$UyavaGraphNodePayloadCopyWithImpl<$Res, UyavaGraphNodePayload>;
  @useResult
  $Res call({
    String id,
    String type,
    String label,
    String? description,
    String? parentId,
    List<String> tags,
    @JsonKey(name: 'tagsNormalized') List<String> tagsNormalized,
    @JsonKey(name: 'tagsCatalog') List<String>? tagsCatalog,
    String? color,
    @JsonKey(name: 'colorPriorityIndex') int? colorPriorityIndex,
    String? shape,
    @JsonKey(fromJson: _lifecycleFromJson, toJson: _lifecycleToJson)
    UyavaLifecycleState lifecycle,
    @JsonKey(name: UyavaPayloadKeys.initSource) String? initSource,
  });
}

/// @nodoc
class _$UyavaGraphNodePayloadCopyWithImpl<
  $Res,
  $Val extends UyavaGraphNodePayload
>
    implements $UyavaGraphNodePayloadCopyWith<$Res> {
  _$UyavaGraphNodePayloadCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of UyavaGraphNodePayload
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? type = null,
    Object? label = null,
    Object? description = freezed,
    Object? parentId = freezed,
    Object? tags = null,
    Object? tagsNormalized = null,
    Object? tagsCatalog = freezed,
    Object? color = freezed,
    Object? colorPriorityIndex = freezed,
    Object? shape = freezed,
    Object? lifecycle = null,
    Object? initSource = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            type: null == type
                ? _value.type
                : type // ignore: cast_nullable_to_non_nullable
                      as String,
            label: null == label
                ? _value.label
                : label // ignore: cast_nullable_to_non_nullable
                      as String,
            description: freezed == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                      as String?,
            parentId: freezed == parentId
                ? _value.parentId
                : parentId // ignore: cast_nullable_to_non_nullable
                      as String?,
            tags: null == tags
                ? _value.tags
                : tags // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            tagsNormalized: null == tagsNormalized
                ? _value.tagsNormalized
                : tagsNormalized // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            tagsCatalog: freezed == tagsCatalog
                ? _value.tagsCatalog
                : tagsCatalog // ignore: cast_nullable_to_non_nullable
                      as List<String>?,
            color: freezed == color
                ? _value.color
                : color // ignore: cast_nullable_to_non_nullable
                      as String?,
            colorPriorityIndex: freezed == colorPriorityIndex
                ? _value.colorPriorityIndex
                : colorPriorityIndex // ignore: cast_nullable_to_non_nullable
                      as int?,
            shape: freezed == shape
                ? _value.shape
                : shape // ignore: cast_nullable_to_non_nullable
                      as String?,
            lifecycle: null == lifecycle
                ? _value.lifecycle
                : lifecycle // ignore: cast_nullable_to_non_nullable
                      as UyavaLifecycleState,
            initSource: freezed == initSource
                ? _value.initSource
                : initSource // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$UyavaGraphNodePayloadImplCopyWith<$Res>
    implements $UyavaGraphNodePayloadCopyWith<$Res> {
  factory _$$UyavaGraphNodePayloadImplCopyWith(
    _$UyavaGraphNodePayloadImpl value,
    $Res Function(_$UyavaGraphNodePayloadImpl) then,
  ) = __$$UyavaGraphNodePayloadImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String type,
    String label,
    String? description,
    String? parentId,
    List<String> tags,
    @JsonKey(name: 'tagsNormalized') List<String> tagsNormalized,
    @JsonKey(name: 'tagsCatalog') List<String>? tagsCatalog,
    String? color,
    @JsonKey(name: 'colorPriorityIndex') int? colorPriorityIndex,
    String? shape,
    @JsonKey(fromJson: _lifecycleFromJson, toJson: _lifecycleToJson)
    UyavaLifecycleState lifecycle,
    @JsonKey(name: UyavaPayloadKeys.initSource) String? initSource,
  });
}

/// @nodoc
class __$$UyavaGraphNodePayloadImplCopyWithImpl<$Res>
    extends
        _$UyavaGraphNodePayloadCopyWithImpl<$Res, _$UyavaGraphNodePayloadImpl>
    implements _$$UyavaGraphNodePayloadImplCopyWith<$Res> {
  __$$UyavaGraphNodePayloadImplCopyWithImpl(
    _$UyavaGraphNodePayloadImpl _value,
    $Res Function(_$UyavaGraphNodePayloadImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of UyavaGraphNodePayload
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? type = null,
    Object? label = null,
    Object? description = freezed,
    Object? parentId = freezed,
    Object? tags = null,
    Object? tagsNormalized = null,
    Object? tagsCatalog = freezed,
    Object? color = freezed,
    Object? colorPriorityIndex = freezed,
    Object? shape = freezed,
    Object? lifecycle = null,
    Object? initSource = freezed,
  }) {
    return _then(
      _$UyavaGraphNodePayloadImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        type: null == type
            ? _value.type
            : type // ignore: cast_nullable_to_non_nullable
                  as String,
        label: null == label
            ? _value.label
            : label // ignore: cast_nullable_to_non_nullable
                  as String,
        description: freezed == description
            ? _value.description
            : description // ignore: cast_nullable_to_non_nullable
                  as String?,
        parentId: freezed == parentId
            ? _value.parentId
            : parentId // ignore: cast_nullable_to_non_nullable
                  as String?,
        tags: null == tags
            ? _value._tags
            : tags // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        tagsNormalized: null == tagsNormalized
            ? _value._tagsNormalized
            : tagsNormalized // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        tagsCatalog: freezed == tagsCatalog
            ? _value._tagsCatalog
            : tagsCatalog // ignore: cast_nullable_to_non_nullable
                  as List<String>?,
        color: freezed == color
            ? _value.color
            : color // ignore: cast_nullable_to_non_nullable
                  as String?,
        colorPriorityIndex: freezed == colorPriorityIndex
            ? _value.colorPriorityIndex
            : colorPriorityIndex // ignore: cast_nullable_to_non_nullable
                  as int?,
        shape: freezed == shape
            ? _value.shape
            : shape // ignore: cast_nullable_to_non_nullable
                  as String?,
        lifecycle: null == lifecycle
            ? _value.lifecycle
            : lifecycle // ignore: cast_nullable_to_non_nullable
                  as UyavaLifecycleState,
        initSource: freezed == initSource
            ? _value.initSource
            : initSource // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$UyavaGraphNodePayloadImpl extends _UyavaGraphNodePayload {
  const _$UyavaGraphNodePayloadImpl({
    required this.id,
    this.type = 'unknown',
    required this.label,
    this.description,
    this.parentId,
    final List<String> tags = const <String>[],
    @JsonKey(name: 'tagsNormalized')
    final List<String> tagsNormalized = const <String>[],
    @JsonKey(name: 'tagsCatalog') final List<String>? tagsCatalog,
    this.color,
    @JsonKey(name: 'colorPriorityIndex') this.colorPriorityIndex,
    this.shape,
    @JsonKey(fromJson: _lifecycleFromJson, toJson: _lifecycleToJson)
    this.lifecycle = UyavaLifecycleState.unknown,
    @JsonKey(name: UyavaPayloadKeys.initSource) this.initSource,
  }) : _tags = tags,
       _tagsNormalized = tagsNormalized,
       _tagsCatalog = tagsCatalog,
       super._();

  factory _$UyavaGraphNodePayloadImpl.fromJson(Map<String, dynamic> json) =>
      _$$UyavaGraphNodePayloadImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey()
  final String type;
  @override
  final String label;
  @override
  final String? description;
  @override
  final String? parentId;
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

  final List<String>? _tagsCatalog;
  @override
  @JsonKey(name: 'tagsCatalog')
  List<String>? get tagsCatalog {
    final value = _tagsCatalog;
    if (value == null) return null;
    if (_tagsCatalog is EqualUnmodifiableListView) return _tagsCatalog;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  final String? color;
  @override
  @JsonKey(name: 'colorPriorityIndex')
  final int? colorPriorityIndex;
  @override
  final String? shape;
  @override
  @JsonKey(fromJson: _lifecycleFromJson, toJson: _lifecycleToJson)
  final UyavaLifecycleState lifecycle;
  @override
  @JsonKey(name: UyavaPayloadKeys.initSource)
  final String? initSource;

  @override
  String toString() {
    return 'UyavaGraphNodePayload(id: $id, type: $type, label: $label, description: $description, parentId: $parentId, tags: $tags, tagsNormalized: $tagsNormalized, tagsCatalog: $tagsCatalog, color: $color, colorPriorityIndex: $colorPriorityIndex, shape: $shape, lifecycle: $lifecycle, initSource: $initSource)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UyavaGraphNodePayloadImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.label, label) || other.label == label) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.parentId, parentId) ||
                other.parentId == parentId) &&
            const DeepCollectionEquality().equals(other._tags, _tags) &&
            const DeepCollectionEquality().equals(
              other._tagsNormalized,
              _tagsNormalized,
            ) &&
            const DeepCollectionEquality().equals(
              other._tagsCatalog,
              _tagsCatalog,
            ) &&
            (identical(other.color, color) || other.color == color) &&
            (identical(other.colorPriorityIndex, colorPriorityIndex) ||
                other.colorPriorityIndex == colorPriorityIndex) &&
            (identical(other.shape, shape) || other.shape == shape) &&
            (identical(other.lifecycle, lifecycle) ||
                other.lifecycle == lifecycle) &&
            (identical(other.initSource, initSource) ||
                other.initSource == initSource));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    type,
    label,
    description,
    parentId,
    const DeepCollectionEquality().hash(_tags),
    const DeepCollectionEquality().hash(_tagsNormalized),
    const DeepCollectionEquality().hash(_tagsCatalog),
    color,
    colorPriorityIndex,
    shape,
    lifecycle,
    initSource,
  );

  /// Create a copy of UyavaGraphNodePayload
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UyavaGraphNodePayloadImplCopyWith<_$UyavaGraphNodePayloadImpl>
  get copyWith =>
      __$$UyavaGraphNodePayloadImplCopyWithImpl<_$UyavaGraphNodePayloadImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$UyavaGraphNodePayloadImplToJson(this);
  }
}

abstract class _UyavaGraphNodePayload extends UyavaGraphNodePayload {
  const factory _UyavaGraphNodePayload({
    required final String id,
    final String type,
    required final String label,
    final String? description,
    final String? parentId,
    final List<String> tags,
    @JsonKey(name: 'tagsNormalized') final List<String> tagsNormalized,
    @JsonKey(name: 'tagsCatalog') final List<String>? tagsCatalog,
    final String? color,
    @JsonKey(name: 'colorPriorityIndex') final int? colorPriorityIndex,
    final String? shape,
    @JsonKey(fromJson: _lifecycleFromJson, toJson: _lifecycleToJson)
    final UyavaLifecycleState lifecycle,
    @JsonKey(name: UyavaPayloadKeys.initSource) final String? initSource,
  }) = _$UyavaGraphNodePayloadImpl;
  const _UyavaGraphNodePayload._() : super._();

  factory _UyavaGraphNodePayload.fromJson(Map<String, dynamic> json) =
      _$UyavaGraphNodePayloadImpl.fromJson;

  @override
  String get id;
  @override
  String get type;
  @override
  String get label;
  @override
  String? get description;
  @override
  String? get parentId;
  @override
  List<String> get tags;
  @override
  @JsonKey(name: 'tagsNormalized')
  List<String> get tagsNormalized;
  @override
  @JsonKey(name: 'tagsCatalog')
  List<String>? get tagsCatalog;
  @override
  String? get color;
  @override
  @JsonKey(name: 'colorPriorityIndex')
  int? get colorPriorityIndex;
  @override
  String? get shape;
  @override
  @JsonKey(fromJson: _lifecycleFromJson, toJson: _lifecycleToJson)
  UyavaLifecycleState get lifecycle;
  @override
  @JsonKey(name: UyavaPayloadKeys.initSource)
  String? get initSource;

  /// Create a copy of UyavaGraphNodePayload
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UyavaGraphNodePayloadImplCopyWith<_$UyavaGraphNodePayloadImpl>
  get copyWith => throw _privateConstructorUsedError;
}
