// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'event_chain_definition_payload.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

UyavaEventChainDefinitionPayload _$UyavaEventChainDefinitionPayloadFromJson(
  Map<String, dynamic> json,
) {
  return _UyavaEventChainDefinitionPayload.fromJson(json);
}

/// @nodoc
mixin _$UyavaEventChainDefinitionPayload {
  String get id => throw _privateConstructorUsedError;
  List<String> get tags => throw _privateConstructorUsedError;
  @JsonKey(name: 'tagsNormalized')
  List<String> get tagsNormalized => throw _privateConstructorUsedError;
  @JsonKey(name: 'tagsCatalog')
  List<String>? get tagsCatalog => throw _privateConstructorUsedError;
  @Deprecated('Use tags instead')
  String? get tag => throw _privateConstructorUsedError;
  String? get label => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  List<UyavaEventChainStepPayload> get steps =>
      throw _privateConstructorUsedError;

  /// Serializes this UyavaEventChainDefinitionPayload to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of UyavaEventChainDefinitionPayload
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $UyavaEventChainDefinitionPayloadCopyWith<UyavaEventChainDefinitionPayload>
  get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UyavaEventChainDefinitionPayloadCopyWith<$Res> {
  factory $UyavaEventChainDefinitionPayloadCopyWith(
    UyavaEventChainDefinitionPayload value,
    $Res Function(UyavaEventChainDefinitionPayload) then,
  ) =
      _$UyavaEventChainDefinitionPayloadCopyWithImpl<
        $Res,
        UyavaEventChainDefinitionPayload
      >;
  @useResult
  $Res call({
    String id,
    List<String> tags,
    @JsonKey(name: 'tagsNormalized') List<String> tagsNormalized,
    @JsonKey(name: 'tagsCatalog') List<String>? tagsCatalog,
    @Deprecated('Use tags instead') String? tag,
    String? label,
    String? description,
    List<UyavaEventChainStepPayload> steps,
  });
}

/// @nodoc
class _$UyavaEventChainDefinitionPayloadCopyWithImpl<
  $Res,
  $Val extends UyavaEventChainDefinitionPayload
>
    implements $UyavaEventChainDefinitionPayloadCopyWith<$Res> {
  _$UyavaEventChainDefinitionPayloadCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of UyavaEventChainDefinitionPayload
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? tags = null,
    Object? tagsNormalized = null,
    Object? tagsCatalog = freezed,
    Object? tag = freezed,
    Object? label = freezed,
    Object? description = freezed,
    Object? steps = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
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
            tag: freezed == tag
                ? _value.tag
                : tag // ignore: cast_nullable_to_non_nullable
                      as String?,
            label: freezed == label
                ? _value.label
                : label // ignore: cast_nullable_to_non_nullable
                      as String?,
            description: freezed == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                      as String?,
            steps: null == steps
                ? _value.steps
                : steps // ignore: cast_nullable_to_non_nullable
                      as List<UyavaEventChainStepPayload>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$UyavaEventChainDefinitionPayloadImplCopyWith<$Res>
    implements $UyavaEventChainDefinitionPayloadCopyWith<$Res> {
  factory _$$UyavaEventChainDefinitionPayloadImplCopyWith(
    _$UyavaEventChainDefinitionPayloadImpl value,
    $Res Function(_$UyavaEventChainDefinitionPayloadImpl) then,
  ) = __$$UyavaEventChainDefinitionPayloadImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    List<String> tags,
    @JsonKey(name: 'tagsNormalized') List<String> tagsNormalized,
    @JsonKey(name: 'tagsCatalog') List<String>? tagsCatalog,
    @Deprecated('Use tags instead') String? tag,
    String? label,
    String? description,
    List<UyavaEventChainStepPayload> steps,
  });
}

/// @nodoc
class __$$UyavaEventChainDefinitionPayloadImplCopyWithImpl<$Res>
    extends
        _$UyavaEventChainDefinitionPayloadCopyWithImpl<
          $Res,
          _$UyavaEventChainDefinitionPayloadImpl
        >
    implements _$$UyavaEventChainDefinitionPayloadImplCopyWith<$Res> {
  __$$UyavaEventChainDefinitionPayloadImplCopyWithImpl(
    _$UyavaEventChainDefinitionPayloadImpl _value,
    $Res Function(_$UyavaEventChainDefinitionPayloadImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of UyavaEventChainDefinitionPayload
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? tags = null,
    Object? tagsNormalized = null,
    Object? tagsCatalog = freezed,
    Object? tag = freezed,
    Object? label = freezed,
    Object? description = freezed,
    Object? steps = null,
  }) {
    return _then(
      _$UyavaEventChainDefinitionPayloadImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
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
        tag: freezed == tag
            ? _value.tag
            : tag // ignore: cast_nullable_to_non_nullable
                  as String?,
        label: freezed == label
            ? _value.label
            : label // ignore: cast_nullable_to_non_nullable
                  as String?,
        description: freezed == description
            ? _value.description
            : description // ignore: cast_nullable_to_non_nullable
                  as String?,
        steps: null == steps
            ? _value._steps
            : steps // ignore: cast_nullable_to_non_nullable
                  as List<UyavaEventChainStepPayload>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$UyavaEventChainDefinitionPayloadImpl
    extends _UyavaEventChainDefinitionPayload {
  const _$UyavaEventChainDefinitionPayloadImpl({
    required this.id,
    final List<String> tags = const <String>[],
    @JsonKey(name: 'tagsNormalized')
    final List<String> tagsNormalized = const <String>[],
    @JsonKey(name: 'tagsCatalog') final List<String>? tagsCatalog,
    @Deprecated('Use tags instead') this.tag,
    this.label,
    this.description,
    final List<UyavaEventChainStepPayload> steps =
        const <UyavaEventChainStepPayload>[],
  }) : _tags = tags,
       _tagsNormalized = tagsNormalized,
       _tagsCatalog = tagsCatalog,
       _steps = steps,
       super._();

  factory _$UyavaEventChainDefinitionPayloadImpl.fromJson(
    Map<String, dynamic> json,
  ) => _$$UyavaEventChainDefinitionPayloadImplFromJson(json);

  @override
  final String id;
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
  @Deprecated('Use tags instead')
  final String? tag;
  @override
  final String? label;
  @override
  final String? description;
  final List<UyavaEventChainStepPayload> _steps;
  @override
  @JsonKey()
  List<UyavaEventChainStepPayload> get steps {
    if (_steps is EqualUnmodifiableListView) return _steps;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_steps);
  }

  @override
  String toString() {
    return 'UyavaEventChainDefinitionPayload(id: $id, tags: $tags, tagsNormalized: $tagsNormalized, tagsCatalog: $tagsCatalog, tag: $tag, label: $label, description: $description, steps: $steps)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UyavaEventChainDefinitionPayloadImpl &&
            (identical(other.id, id) || other.id == id) &&
            const DeepCollectionEquality().equals(other._tags, _tags) &&
            const DeepCollectionEquality().equals(
              other._tagsNormalized,
              _tagsNormalized,
            ) &&
            const DeepCollectionEquality().equals(
              other._tagsCatalog,
              _tagsCatalog,
            ) &&
            (identical(other.tag, tag) || other.tag == tag) &&
            (identical(other.label, label) || other.label == label) &&
            (identical(other.description, description) ||
                other.description == description) &&
            const DeepCollectionEquality().equals(other._steps, _steps));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    const DeepCollectionEquality().hash(_tags),
    const DeepCollectionEquality().hash(_tagsNormalized),
    const DeepCollectionEquality().hash(_tagsCatalog),
    tag,
    label,
    description,
    const DeepCollectionEquality().hash(_steps),
  );

  /// Create a copy of UyavaEventChainDefinitionPayload
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UyavaEventChainDefinitionPayloadImplCopyWith<
    _$UyavaEventChainDefinitionPayloadImpl
  >
  get copyWith =>
      __$$UyavaEventChainDefinitionPayloadImplCopyWithImpl<
        _$UyavaEventChainDefinitionPayloadImpl
      >(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$UyavaEventChainDefinitionPayloadImplToJson(this);
  }
}

abstract class _UyavaEventChainDefinitionPayload
    extends UyavaEventChainDefinitionPayload {
  const factory _UyavaEventChainDefinitionPayload({
    required final String id,
    final List<String> tags,
    @JsonKey(name: 'tagsNormalized') final List<String> tagsNormalized,
    @JsonKey(name: 'tagsCatalog') final List<String>? tagsCatalog,
    @Deprecated('Use tags instead') final String? tag,
    final String? label,
    final String? description,
    final List<UyavaEventChainStepPayload> steps,
  }) = _$UyavaEventChainDefinitionPayloadImpl;
  const _UyavaEventChainDefinitionPayload._() : super._();

  factory _UyavaEventChainDefinitionPayload.fromJson(
    Map<String, dynamic> json,
  ) = _$UyavaEventChainDefinitionPayloadImpl.fromJson;

  @override
  String get id;
  @override
  List<String> get tags;
  @override
  @JsonKey(name: 'tagsNormalized')
  List<String> get tagsNormalized;
  @override
  @JsonKey(name: 'tagsCatalog')
  List<String>? get tagsCatalog;
  @override
  @Deprecated('Use tags instead')
  String? get tag;
  @override
  String? get label;
  @override
  String? get description;
  @override
  List<UyavaEventChainStepPayload> get steps;

  /// Create a copy of UyavaEventChainDefinitionPayload
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UyavaEventChainDefinitionPayloadImplCopyWith<
    _$UyavaEventChainDefinitionPayloadImpl
  >
  get copyWith => throw _privateConstructorUsedError;
}

UyavaEventChainStepPayload _$UyavaEventChainStepPayloadFromJson(
  Map<String, dynamic> json,
) {
  return _UyavaEventChainStepPayload.fromJson(json);
}

/// @nodoc
mixin _$UyavaEventChainStepPayload {
  String get stepId => throw _privateConstructorUsedError;
  String get nodeId => throw _privateConstructorUsedError;
  String? get edgeId => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _severityFromJson, toJson: _severityToJson)
  UyavaSeverity? get expectedSeverity => throw _privateConstructorUsedError;

  /// Serializes this UyavaEventChainStepPayload to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of UyavaEventChainStepPayload
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $UyavaEventChainStepPayloadCopyWith<UyavaEventChainStepPayload>
  get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UyavaEventChainStepPayloadCopyWith<$Res> {
  factory $UyavaEventChainStepPayloadCopyWith(
    UyavaEventChainStepPayload value,
    $Res Function(UyavaEventChainStepPayload) then,
  ) =
      _$UyavaEventChainStepPayloadCopyWithImpl<
        $Res,
        UyavaEventChainStepPayload
      >;
  @useResult
  $Res call({
    String stepId,
    String nodeId,
    String? edgeId,
    @JsonKey(fromJson: _severityFromJson, toJson: _severityToJson)
    UyavaSeverity? expectedSeverity,
  });
}

/// @nodoc
class _$UyavaEventChainStepPayloadCopyWithImpl<
  $Res,
  $Val extends UyavaEventChainStepPayload
>
    implements $UyavaEventChainStepPayloadCopyWith<$Res> {
  _$UyavaEventChainStepPayloadCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of UyavaEventChainStepPayload
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? stepId = null,
    Object? nodeId = null,
    Object? edgeId = freezed,
    Object? expectedSeverity = freezed,
  }) {
    return _then(
      _value.copyWith(
            stepId: null == stepId
                ? _value.stepId
                : stepId // ignore: cast_nullable_to_non_nullable
                      as String,
            nodeId: null == nodeId
                ? _value.nodeId
                : nodeId // ignore: cast_nullable_to_non_nullable
                      as String,
            edgeId: freezed == edgeId
                ? _value.edgeId
                : edgeId // ignore: cast_nullable_to_non_nullable
                      as String?,
            expectedSeverity: freezed == expectedSeverity
                ? _value.expectedSeverity
                : expectedSeverity // ignore: cast_nullable_to_non_nullable
                      as UyavaSeverity?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$UyavaEventChainStepPayloadImplCopyWith<$Res>
    implements $UyavaEventChainStepPayloadCopyWith<$Res> {
  factory _$$UyavaEventChainStepPayloadImplCopyWith(
    _$UyavaEventChainStepPayloadImpl value,
    $Res Function(_$UyavaEventChainStepPayloadImpl) then,
  ) = __$$UyavaEventChainStepPayloadImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String stepId,
    String nodeId,
    String? edgeId,
    @JsonKey(fromJson: _severityFromJson, toJson: _severityToJson)
    UyavaSeverity? expectedSeverity,
  });
}

/// @nodoc
class __$$UyavaEventChainStepPayloadImplCopyWithImpl<$Res>
    extends
        _$UyavaEventChainStepPayloadCopyWithImpl<
          $Res,
          _$UyavaEventChainStepPayloadImpl
        >
    implements _$$UyavaEventChainStepPayloadImplCopyWith<$Res> {
  __$$UyavaEventChainStepPayloadImplCopyWithImpl(
    _$UyavaEventChainStepPayloadImpl _value,
    $Res Function(_$UyavaEventChainStepPayloadImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of UyavaEventChainStepPayload
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? stepId = null,
    Object? nodeId = null,
    Object? edgeId = freezed,
    Object? expectedSeverity = freezed,
  }) {
    return _then(
      _$UyavaEventChainStepPayloadImpl(
        stepId: null == stepId
            ? _value.stepId
            : stepId // ignore: cast_nullable_to_non_nullable
                  as String,
        nodeId: null == nodeId
            ? _value.nodeId
            : nodeId // ignore: cast_nullable_to_non_nullable
                  as String,
        edgeId: freezed == edgeId
            ? _value.edgeId
            : edgeId // ignore: cast_nullable_to_non_nullable
                  as String?,
        expectedSeverity: freezed == expectedSeverity
            ? _value.expectedSeverity
            : expectedSeverity // ignore: cast_nullable_to_non_nullable
                  as UyavaSeverity?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$UyavaEventChainStepPayloadImpl extends _UyavaEventChainStepPayload {
  const _$UyavaEventChainStepPayloadImpl({
    required this.stepId,
    required this.nodeId,
    this.edgeId,
    @JsonKey(fromJson: _severityFromJson, toJson: _severityToJson)
    this.expectedSeverity,
  }) : super._();

  factory _$UyavaEventChainStepPayloadImpl.fromJson(
    Map<String, dynamic> json,
  ) => _$$UyavaEventChainStepPayloadImplFromJson(json);

  @override
  final String stepId;
  @override
  final String nodeId;
  @override
  final String? edgeId;
  @override
  @JsonKey(fromJson: _severityFromJson, toJson: _severityToJson)
  final UyavaSeverity? expectedSeverity;

  @override
  String toString() {
    return 'UyavaEventChainStepPayload(stepId: $stepId, nodeId: $nodeId, edgeId: $edgeId, expectedSeverity: $expectedSeverity)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UyavaEventChainStepPayloadImpl &&
            (identical(other.stepId, stepId) || other.stepId == stepId) &&
            (identical(other.nodeId, nodeId) || other.nodeId == nodeId) &&
            (identical(other.edgeId, edgeId) || other.edgeId == edgeId) &&
            (identical(other.expectedSeverity, expectedSeverity) ||
                other.expectedSeverity == expectedSeverity));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, stepId, nodeId, edgeId, expectedSeverity);

  /// Create a copy of UyavaEventChainStepPayload
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UyavaEventChainStepPayloadImplCopyWith<_$UyavaEventChainStepPayloadImpl>
  get copyWith =>
      __$$UyavaEventChainStepPayloadImplCopyWithImpl<
        _$UyavaEventChainStepPayloadImpl
      >(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$UyavaEventChainStepPayloadImplToJson(this);
  }
}

abstract class _UyavaEventChainStepPayload extends UyavaEventChainStepPayload {
  const factory _UyavaEventChainStepPayload({
    required final String stepId,
    required final String nodeId,
    final String? edgeId,
    @JsonKey(fromJson: _severityFromJson, toJson: _severityToJson)
    final UyavaSeverity? expectedSeverity,
  }) = _$UyavaEventChainStepPayloadImpl;
  const _UyavaEventChainStepPayload._() : super._();

  factory _UyavaEventChainStepPayload.fromJson(Map<String, dynamic> json) =
      _$UyavaEventChainStepPayloadImpl.fromJson;

  @override
  String get stepId;
  @override
  String get nodeId;
  @override
  String? get edgeId;
  @override
  @JsonKey(fromJson: _severityFromJson, toJson: _severityToJson)
  UyavaSeverity? get expectedSeverity;

  /// Create a copy of UyavaEventChainStepPayload
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UyavaEventChainStepPayloadImplCopyWith<_$UyavaEventChainStepPayloadImpl>
  get copyWith => throw _privateConstructorUsedError;
}
