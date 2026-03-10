// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'graph_edge_event_payload.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

UyavaGraphEdgeEventPayload _$UyavaGraphEdgeEventPayloadFromJson(
  Map<String, dynamic> json,
) {
  return _UyavaGraphEdgeEventPayload.fromJson(json);
}

/// @nodoc
mixin _$UyavaGraphEdgeEventPayload {
  @JsonKey(name: 'edge')
  String? get edgeId => throw _privateConstructorUsedError;
  @JsonKey(name: 'from')
  String get from => throw _privateConstructorUsedError;
  @JsonKey(name: 'to')
  String get to => throw _privateConstructorUsedError;
  @JsonKey(name: 'message')
  String get message => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _severityFromJson, toJson: _severityToJson)
  UyavaSeverity? get severity => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
  DateTime get timestamp => throw _privateConstructorUsedError;
  @JsonKey(name: UyavaPayloadKeys.sourceRef)
  String? get sourceRef => throw _privateConstructorUsedError;

  /// Serializes this UyavaGraphEdgeEventPayload to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of UyavaGraphEdgeEventPayload
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $UyavaGraphEdgeEventPayloadCopyWith<UyavaGraphEdgeEventPayload>
  get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UyavaGraphEdgeEventPayloadCopyWith<$Res> {
  factory $UyavaGraphEdgeEventPayloadCopyWith(
    UyavaGraphEdgeEventPayload value,
    $Res Function(UyavaGraphEdgeEventPayload) then,
  ) =
      _$UyavaGraphEdgeEventPayloadCopyWithImpl<
        $Res,
        UyavaGraphEdgeEventPayload
      >;
  @useResult
  $Res call({
    @JsonKey(name: 'edge') String? edgeId,
    @JsonKey(name: 'from') String from,
    @JsonKey(name: 'to') String to,
    @JsonKey(name: 'message') String message,
    @JsonKey(fromJson: _severityFromJson, toJson: _severityToJson)
    UyavaSeverity? severity,
    @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
    DateTime timestamp,
    @JsonKey(name: UyavaPayloadKeys.sourceRef) String? sourceRef,
  });
}

/// @nodoc
class _$UyavaGraphEdgeEventPayloadCopyWithImpl<
  $Res,
  $Val extends UyavaGraphEdgeEventPayload
>
    implements $UyavaGraphEdgeEventPayloadCopyWith<$Res> {
  _$UyavaGraphEdgeEventPayloadCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of UyavaGraphEdgeEventPayload
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? edgeId = freezed,
    Object? from = null,
    Object? to = null,
    Object? message = null,
    Object? severity = freezed,
    Object? timestamp = null,
    Object? sourceRef = freezed,
  }) {
    return _then(
      _value.copyWith(
            edgeId: freezed == edgeId
                ? _value.edgeId
                : edgeId // ignore: cast_nullable_to_non_nullable
                      as String?,
            from: null == from
                ? _value.from
                : from // ignore: cast_nullable_to_non_nullable
                      as String,
            to: null == to
                ? _value.to
                : to // ignore: cast_nullable_to_non_nullable
                      as String,
            message: null == message
                ? _value.message
                : message // ignore: cast_nullable_to_non_nullable
                      as String,
            severity: freezed == severity
                ? _value.severity
                : severity // ignore: cast_nullable_to_non_nullable
                      as UyavaSeverity?,
            timestamp: null == timestamp
                ? _value.timestamp
                : timestamp // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            sourceRef: freezed == sourceRef
                ? _value.sourceRef
                : sourceRef // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$UyavaGraphEdgeEventPayloadImplCopyWith<$Res>
    implements $UyavaGraphEdgeEventPayloadCopyWith<$Res> {
  factory _$$UyavaGraphEdgeEventPayloadImplCopyWith(
    _$UyavaGraphEdgeEventPayloadImpl value,
    $Res Function(_$UyavaGraphEdgeEventPayloadImpl) then,
  ) = __$$UyavaGraphEdgeEventPayloadImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @JsonKey(name: 'edge') String? edgeId,
    @JsonKey(name: 'from') String from,
    @JsonKey(name: 'to') String to,
    @JsonKey(name: 'message') String message,
    @JsonKey(fromJson: _severityFromJson, toJson: _severityToJson)
    UyavaSeverity? severity,
    @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
    DateTime timestamp,
    @JsonKey(name: UyavaPayloadKeys.sourceRef) String? sourceRef,
  });
}

/// @nodoc
class __$$UyavaGraphEdgeEventPayloadImplCopyWithImpl<$Res>
    extends
        _$UyavaGraphEdgeEventPayloadCopyWithImpl<
          $Res,
          _$UyavaGraphEdgeEventPayloadImpl
        >
    implements _$$UyavaGraphEdgeEventPayloadImplCopyWith<$Res> {
  __$$UyavaGraphEdgeEventPayloadImplCopyWithImpl(
    _$UyavaGraphEdgeEventPayloadImpl _value,
    $Res Function(_$UyavaGraphEdgeEventPayloadImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of UyavaGraphEdgeEventPayload
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? edgeId = freezed,
    Object? from = null,
    Object? to = null,
    Object? message = null,
    Object? severity = freezed,
    Object? timestamp = null,
    Object? sourceRef = freezed,
  }) {
    return _then(
      _$UyavaGraphEdgeEventPayloadImpl(
        edgeId: freezed == edgeId
            ? _value.edgeId
            : edgeId // ignore: cast_nullable_to_non_nullable
                  as String?,
        from: null == from
            ? _value.from
            : from // ignore: cast_nullable_to_non_nullable
                  as String,
        to: null == to
            ? _value.to
            : to // ignore: cast_nullable_to_non_nullable
                  as String,
        message: null == message
            ? _value.message
            : message // ignore: cast_nullable_to_non_nullable
                  as String,
        severity: freezed == severity
            ? _value.severity
            : severity // ignore: cast_nullable_to_non_nullable
                  as UyavaSeverity?,
        timestamp: null == timestamp
            ? _value.timestamp
            : timestamp // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        sourceRef: freezed == sourceRef
            ? _value.sourceRef
            : sourceRef // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$UyavaGraphEdgeEventPayloadImpl extends _UyavaGraphEdgeEventPayload {
  const _$UyavaGraphEdgeEventPayloadImpl({
    @JsonKey(name: 'edge') this.edgeId,
    @JsonKey(name: 'from') required this.from,
    @JsonKey(name: 'to') required this.to,
    @JsonKey(name: 'message') required this.message,
    @JsonKey(fromJson: _severityFromJson, toJson: _severityToJson)
    this.severity,
    @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
    required this.timestamp,
    @JsonKey(name: UyavaPayloadKeys.sourceRef) this.sourceRef,
  }) : super._();

  factory _$UyavaGraphEdgeEventPayloadImpl.fromJson(
    Map<String, dynamic> json,
  ) => _$$UyavaGraphEdgeEventPayloadImplFromJson(json);

  @override
  @JsonKey(name: 'edge')
  final String? edgeId;
  @override
  @JsonKey(name: 'from')
  final String from;
  @override
  @JsonKey(name: 'to')
  final String to;
  @override
  @JsonKey(name: 'message')
  final String message;
  @override
  @JsonKey(fromJson: _severityFromJson, toJson: _severityToJson)
  final UyavaSeverity? severity;
  @override
  @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
  final DateTime timestamp;
  @override
  @JsonKey(name: UyavaPayloadKeys.sourceRef)
  final String? sourceRef;

  @override
  String toString() {
    return 'UyavaGraphEdgeEventPayload(edgeId: $edgeId, from: $from, to: $to, message: $message, severity: $severity, timestamp: $timestamp, sourceRef: $sourceRef)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UyavaGraphEdgeEventPayloadImpl &&
            (identical(other.edgeId, edgeId) || other.edgeId == edgeId) &&
            (identical(other.from, from) || other.from == from) &&
            (identical(other.to, to) || other.to == to) &&
            (identical(other.message, message) || other.message == message) &&
            (identical(other.severity, severity) ||
                other.severity == severity) &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp) &&
            (identical(other.sourceRef, sourceRef) ||
                other.sourceRef == sourceRef));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    edgeId,
    from,
    to,
    message,
    severity,
    timestamp,
    sourceRef,
  );

  /// Create a copy of UyavaGraphEdgeEventPayload
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UyavaGraphEdgeEventPayloadImplCopyWith<_$UyavaGraphEdgeEventPayloadImpl>
  get copyWith =>
      __$$UyavaGraphEdgeEventPayloadImplCopyWithImpl<
        _$UyavaGraphEdgeEventPayloadImpl
      >(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$UyavaGraphEdgeEventPayloadImplToJson(this);
  }
}

abstract class _UyavaGraphEdgeEventPayload extends UyavaGraphEdgeEventPayload {
  const factory _UyavaGraphEdgeEventPayload({
    @JsonKey(name: 'edge') final String? edgeId,
    @JsonKey(name: 'from') required final String from,
    @JsonKey(name: 'to') required final String to,
    @JsonKey(name: 'message') required final String message,
    @JsonKey(fromJson: _severityFromJson, toJson: _severityToJson)
    final UyavaSeverity? severity,
    @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
    required final DateTime timestamp,
    @JsonKey(name: UyavaPayloadKeys.sourceRef) final String? sourceRef,
  }) = _$UyavaGraphEdgeEventPayloadImpl;
  const _UyavaGraphEdgeEventPayload._() : super._();

  factory _UyavaGraphEdgeEventPayload.fromJson(Map<String, dynamic> json) =
      _$UyavaGraphEdgeEventPayloadImpl.fromJson;

  @override
  @JsonKey(name: 'edge')
  String? get edgeId;
  @override
  @JsonKey(name: 'from')
  String get from;
  @override
  @JsonKey(name: 'to')
  String get to;
  @override
  @JsonKey(name: 'message')
  String get message;
  @override
  @JsonKey(fromJson: _severityFromJson, toJson: _severityToJson)
  UyavaSeverity? get severity;
  @override
  @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
  DateTime get timestamp;
  @override
  @JsonKey(name: UyavaPayloadKeys.sourceRef)
  String? get sourceRef;

  /// Create a copy of UyavaGraphEdgeEventPayload
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UyavaGraphEdgeEventPayloadImplCopyWith<_$UyavaGraphEdgeEventPayloadImpl>
  get copyWith => throw _privateConstructorUsedError;
}
