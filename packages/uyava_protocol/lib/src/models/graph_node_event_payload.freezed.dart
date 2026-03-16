// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'graph_node_event_payload.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

UyavaGraphNodeEventPayload _$UyavaGraphNodeEventPayloadFromJson(
  Map<String, dynamic> json,
) {
  return _UyavaGraphNodeEventPayload.fromJson(json);
}

/// @nodoc
mixin _$UyavaGraphNodeEventPayload {
  @JsonKey(name: 'nodeId')
  String get nodeId => throw _privateConstructorUsedError;
  @JsonKey(name: 'message')
  String get message => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _severityFromJson, toJson: _severityToJson)
  UyavaSeverity? get severity => throw _privateConstructorUsedError;
  List<String>? get tags => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
  DateTime get timestamp => throw _privateConstructorUsedError;
  @JsonKey(name: UyavaPayloadKeys.sourceRef)
  String? get sourceRef => throw _privateConstructorUsedError;
  Map<String, dynamic>? get payload => throw _privateConstructorUsedError;

  /// Serializes this UyavaGraphNodeEventPayload to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of UyavaGraphNodeEventPayload
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $UyavaGraphNodeEventPayloadCopyWith<UyavaGraphNodeEventPayload>
  get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UyavaGraphNodeEventPayloadCopyWith<$Res> {
  factory $UyavaGraphNodeEventPayloadCopyWith(
    UyavaGraphNodeEventPayload value,
    $Res Function(UyavaGraphNodeEventPayload) then,
  ) =
      _$UyavaGraphNodeEventPayloadCopyWithImpl<
        $Res,
        UyavaGraphNodeEventPayload
      >;
  @useResult
  $Res call({
    @JsonKey(name: 'nodeId') String nodeId,
    @JsonKey(name: 'message') String message,
    @JsonKey(fromJson: _severityFromJson, toJson: _severityToJson)
    UyavaSeverity? severity,
    List<String>? tags,
    @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
    DateTime timestamp,
    @JsonKey(name: UyavaPayloadKeys.sourceRef) String? sourceRef,
    Map<String, dynamic>? payload,
  });
}

/// @nodoc
class _$UyavaGraphNodeEventPayloadCopyWithImpl<
  $Res,
  $Val extends UyavaGraphNodeEventPayload
>
    implements $UyavaGraphNodeEventPayloadCopyWith<$Res> {
  _$UyavaGraphNodeEventPayloadCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of UyavaGraphNodeEventPayload
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? nodeId = null,
    Object? message = null,
    Object? severity = freezed,
    Object? tags = freezed,
    Object? timestamp = null,
    Object? sourceRef = freezed,
    Object? payload = freezed,
  }) {
    return _then(
      _value.copyWith(
            nodeId: null == nodeId
                ? _value.nodeId
                : nodeId // ignore: cast_nullable_to_non_nullable
                      as String,
            message: null == message
                ? _value.message
                : message // ignore: cast_nullable_to_non_nullable
                      as String,
            severity: freezed == severity
                ? _value.severity
                : severity // ignore: cast_nullable_to_non_nullable
                      as UyavaSeverity?,
            tags: freezed == tags
                ? _value.tags
                : tags // ignore: cast_nullable_to_non_nullable
                      as List<String>?,
            timestamp: null == timestamp
                ? _value.timestamp
                : timestamp // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            sourceRef: freezed == sourceRef
                ? _value.sourceRef
                : sourceRef // ignore: cast_nullable_to_non_nullable
                      as String?,
            payload: freezed == payload
                ? _value.payload
                : payload // ignore: cast_nullable_to_non_nullable
                      as Map<String, dynamic>?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$UyavaGraphNodeEventPayloadImplCopyWith<$Res>
    implements $UyavaGraphNodeEventPayloadCopyWith<$Res> {
  factory _$$UyavaGraphNodeEventPayloadImplCopyWith(
    _$UyavaGraphNodeEventPayloadImpl value,
    $Res Function(_$UyavaGraphNodeEventPayloadImpl) then,
  ) = __$$UyavaGraphNodeEventPayloadImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @JsonKey(name: 'nodeId') String nodeId,
    @JsonKey(name: 'message') String message,
    @JsonKey(fromJson: _severityFromJson, toJson: _severityToJson)
    UyavaSeverity? severity,
    List<String>? tags,
    @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
    DateTime timestamp,
    @JsonKey(name: UyavaPayloadKeys.sourceRef) String? sourceRef,
    Map<String, dynamic>? payload,
  });
}

/// @nodoc
class __$$UyavaGraphNodeEventPayloadImplCopyWithImpl<$Res>
    extends
        _$UyavaGraphNodeEventPayloadCopyWithImpl<
          $Res,
          _$UyavaGraphNodeEventPayloadImpl
        >
    implements _$$UyavaGraphNodeEventPayloadImplCopyWith<$Res> {
  __$$UyavaGraphNodeEventPayloadImplCopyWithImpl(
    _$UyavaGraphNodeEventPayloadImpl _value,
    $Res Function(_$UyavaGraphNodeEventPayloadImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of UyavaGraphNodeEventPayload
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? nodeId = null,
    Object? message = null,
    Object? severity = freezed,
    Object? tags = freezed,
    Object? timestamp = null,
    Object? sourceRef = freezed,
    Object? payload = freezed,
  }) {
    return _then(
      _$UyavaGraphNodeEventPayloadImpl(
        nodeId: null == nodeId
            ? _value.nodeId
            : nodeId // ignore: cast_nullable_to_non_nullable
                  as String,
        message: null == message
            ? _value.message
            : message // ignore: cast_nullable_to_non_nullable
                  as String,
        severity: freezed == severity
            ? _value.severity
            : severity // ignore: cast_nullable_to_non_nullable
                  as UyavaSeverity?,
        tags: freezed == tags
            ? _value._tags
            : tags // ignore: cast_nullable_to_non_nullable
                  as List<String>?,
        timestamp: null == timestamp
            ? _value.timestamp
            : timestamp // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        sourceRef: freezed == sourceRef
            ? _value.sourceRef
            : sourceRef // ignore: cast_nullable_to_non_nullable
                  as String?,
        payload: freezed == payload
            ? _value._payload
            : payload // ignore: cast_nullable_to_non_nullable
                  as Map<String, dynamic>?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$UyavaGraphNodeEventPayloadImpl extends _UyavaGraphNodeEventPayload {
  const _$UyavaGraphNodeEventPayloadImpl({
    @JsonKey(name: 'nodeId') required this.nodeId,
    @JsonKey(name: 'message') required this.message,
    @JsonKey(fromJson: _severityFromJson, toJson: _severityToJson)
    this.severity,
    final List<String>? tags,
    @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
    required this.timestamp,
    @JsonKey(name: UyavaPayloadKeys.sourceRef) this.sourceRef,
    final Map<String, dynamic>? payload,
  }) : _tags = tags,
       _payload = payload,
       super._();

  factory _$UyavaGraphNodeEventPayloadImpl.fromJson(
    Map<String, dynamic> json,
  ) => _$$UyavaGraphNodeEventPayloadImplFromJson(json);

  @override
  @JsonKey(name: 'nodeId')
  final String nodeId;
  @override
  @JsonKey(name: 'message')
  final String message;
  @override
  @JsonKey(fromJson: _severityFromJson, toJson: _severityToJson)
  final UyavaSeverity? severity;
  final List<String>? _tags;
  @override
  List<String>? get tags {
    final value = _tags;
    if (value == null) return null;
    if (_tags is EqualUnmodifiableListView) return _tags;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
  final DateTime timestamp;
  @override
  @JsonKey(name: UyavaPayloadKeys.sourceRef)
  final String? sourceRef;
  final Map<String, dynamic>? _payload;
  @override
  Map<String, dynamic>? get payload {
    final value = _payload;
    if (value == null) return null;
    if (_payload is EqualUnmodifiableMapView) return _payload;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  @override
  String toString() {
    return 'UyavaGraphNodeEventPayload(nodeId: $nodeId, message: $message, severity: $severity, tags: $tags, timestamp: $timestamp, sourceRef: $sourceRef, payload: $payload)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UyavaGraphNodeEventPayloadImpl &&
            (identical(other.nodeId, nodeId) || other.nodeId == nodeId) &&
            (identical(other.message, message) || other.message == message) &&
            (identical(other.severity, severity) ||
                other.severity == severity) &&
            const DeepCollectionEquality().equals(other._tags, _tags) &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp) &&
            (identical(other.sourceRef, sourceRef) ||
                other.sourceRef == sourceRef) &&
            const DeepCollectionEquality().equals(other._payload, _payload));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    nodeId,
    message,
    severity,
    const DeepCollectionEquality().hash(_tags),
    timestamp,
    sourceRef,
    const DeepCollectionEquality().hash(_payload),
  );

  /// Create a copy of UyavaGraphNodeEventPayload
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UyavaGraphNodeEventPayloadImplCopyWith<_$UyavaGraphNodeEventPayloadImpl>
  get copyWith =>
      __$$UyavaGraphNodeEventPayloadImplCopyWithImpl<
        _$UyavaGraphNodeEventPayloadImpl
      >(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$UyavaGraphNodeEventPayloadImplToJson(this);
  }
}

abstract class _UyavaGraphNodeEventPayload extends UyavaGraphNodeEventPayload {
  const factory _UyavaGraphNodeEventPayload({
    @JsonKey(name: 'nodeId') required final String nodeId,
    @JsonKey(name: 'message') required final String message,
    @JsonKey(fromJson: _severityFromJson, toJson: _severityToJson)
    final UyavaSeverity? severity,
    final List<String>? tags,
    @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
    required final DateTime timestamp,
    @JsonKey(name: UyavaPayloadKeys.sourceRef) final String? sourceRef,
    final Map<String, dynamic>? payload,
  }) = _$UyavaGraphNodeEventPayloadImpl;
  const _UyavaGraphNodeEventPayload._() : super._();

  factory _UyavaGraphNodeEventPayload.fromJson(Map<String, dynamic> json) =
      _$UyavaGraphNodeEventPayloadImpl.fromJson;

  @override
  @JsonKey(name: 'nodeId')
  String get nodeId;
  @override
  @JsonKey(name: 'message')
  String get message;
  @override
  @JsonKey(fromJson: _severityFromJson, toJson: _severityToJson)
  UyavaSeverity? get severity;
  @override
  List<String>? get tags;
  @override
  @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
  DateTime get timestamp;
  @override
  @JsonKey(name: UyavaPayloadKeys.sourceRef)
  String? get sourceRef;
  @override
  Map<String, dynamic>? get payload;

  /// Create a copy of UyavaGraphNodeEventPayload
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UyavaGraphNodeEventPayloadImplCopyWith<_$UyavaGraphNodeEventPayloadImpl>
  get copyWith => throw _privateConstructorUsedError;
}
