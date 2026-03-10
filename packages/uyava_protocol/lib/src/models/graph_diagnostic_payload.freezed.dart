// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'graph_diagnostic_payload.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

UyavaGraphDiagnosticPayload _$UyavaGraphDiagnosticPayloadFromJson(
  Map<String, dynamic> json,
) {
  return _UyavaGraphDiagnosticPayload.fromJson(json);
}

/// @nodoc
mixin _$UyavaGraphDiagnosticPayload {
  String get code => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _integrityCodeFromJson, toJson: _integrityCodeToJson)
  UyavaGraphIntegrityCode? get codeEnum => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _diagnosticLevelFromJson, toJson: _diagnosticLevelToJson)
  UyavaDiagnosticLevel get level => throw _privateConstructorUsedError;
  String? get nodeId => throw _privateConstructorUsedError;
  String? get edgeId => throw _privateConstructorUsedError;
  Map<String, Object?>? get context => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
  DateTime? get timestamp => throw _privateConstructorUsedError;

  /// Serializes this UyavaGraphDiagnosticPayload to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of UyavaGraphDiagnosticPayload
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $UyavaGraphDiagnosticPayloadCopyWith<UyavaGraphDiagnosticPayload>
  get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UyavaGraphDiagnosticPayloadCopyWith<$Res> {
  factory $UyavaGraphDiagnosticPayloadCopyWith(
    UyavaGraphDiagnosticPayload value,
    $Res Function(UyavaGraphDiagnosticPayload) then,
  ) =
      _$UyavaGraphDiagnosticPayloadCopyWithImpl<
        $Res,
        UyavaGraphDiagnosticPayload
      >;
  @useResult
  $Res call({
    String code,
    @JsonKey(fromJson: _integrityCodeFromJson, toJson: _integrityCodeToJson)
    UyavaGraphIntegrityCode? codeEnum,
    @JsonKey(fromJson: _diagnosticLevelFromJson, toJson: _diagnosticLevelToJson)
    UyavaDiagnosticLevel level,
    String? nodeId,
    String? edgeId,
    Map<String, Object?>? context,
    @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
    DateTime? timestamp,
  });
}

/// @nodoc
class _$UyavaGraphDiagnosticPayloadCopyWithImpl<
  $Res,
  $Val extends UyavaGraphDiagnosticPayload
>
    implements $UyavaGraphDiagnosticPayloadCopyWith<$Res> {
  _$UyavaGraphDiagnosticPayloadCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of UyavaGraphDiagnosticPayload
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? code = null,
    Object? codeEnum = freezed,
    Object? level = null,
    Object? nodeId = freezed,
    Object? edgeId = freezed,
    Object? context = freezed,
    Object? timestamp = freezed,
  }) {
    return _then(
      _value.copyWith(
            code: null == code
                ? _value.code
                : code // ignore: cast_nullable_to_non_nullable
                      as String,
            codeEnum: freezed == codeEnum
                ? _value.codeEnum
                : codeEnum // ignore: cast_nullable_to_non_nullable
                      as UyavaGraphIntegrityCode?,
            level: null == level
                ? _value.level
                : level // ignore: cast_nullable_to_non_nullable
                      as UyavaDiagnosticLevel,
            nodeId: freezed == nodeId
                ? _value.nodeId
                : nodeId // ignore: cast_nullable_to_non_nullable
                      as String?,
            edgeId: freezed == edgeId
                ? _value.edgeId
                : edgeId // ignore: cast_nullable_to_non_nullable
                      as String?,
            context: freezed == context
                ? _value.context
                : context // ignore: cast_nullable_to_non_nullable
                      as Map<String, Object?>?,
            timestamp: freezed == timestamp
                ? _value.timestamp
                : timestamp // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$UyavaGraphDiagnosticPayloadImplCopyWith<$Res>
    implements $UyavaGraphDiagnosticPayloadCopyWith<$Res> {
  factory _$$UyavaGraphDiagnosticPayloadImplCopyWith(
    _$UyavaGraphDiagnosticPayloadImpl value,
    $Res Function(_$UyavaGraphDiagnosticPayloadImpl) then,
  ) = __$$UyavaGraphDiagnosticPayloadImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String code,
    @JsonKey(fromJson: _integrityCodeFromJson, toJson: _integrityCodeToJson)
    UyavaGraphIntegrityCode? codeEnum,
    @JsonKey(fromJson: _diagnosticLevelFromJson, toJson: _diagnosticLevelToJson)
    UyavaDiagnosticLevel level,
    String? nodeId,
    String? edgeId,
    Map<String, Object?>? context,
    @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
    DateTime? timestamp,
  });
}

/// @nodoc
class __$$UyavaGraphDiagnosticPayloadImplCopyWithImpl<$Res>
    extends
        _$UyavaGraphDiagnosticPayloadCopyWithImpl<
          $Res,
          _$UyavaGraphDiagnosticPayloadImpl
        >
    implements _$$UyavaGraphDiagnosticPayloadImplCopyWith<$Res> {
  __$$UyavaGraphDiagnosticPayloadImplCopyWithImpl(
    _$UyavaGraphDiagnosticPayloadImpl _value,
    $Res Function(_$UyavaGraphDiagnosticPayloadImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of UyavaGraphDiagnosticPayload
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? code = null,
    Object? codeEnum = freezed,
    Object? level = null,
    Object? nodeId = freezed,
    Object? edgeId = freezed,
    Object? context = freezed,
    Object? timestamp = freezed,
  }) {
    return _then(
      _$UyavaGraphDiagnosticPayloadImpl(
        code: null == code
            ? _value.code
            : code // ignore: cast_nullable_to_non_nullable
                  as String,
        codeEnum: freezed == codeEnum
            ? _value.codeEnum
            : codeEnum // ignore: cast_nullable_to_non_nullable
                  as UyavaGraphIntegrityCode?,
        level: null == level
            ? _value.level
            : level // ignore: cast_nullable_to_non_nullable
                  as UyavaDiagnosticLevel,
        nodeId: freezed == nodeId
            ? _value.nodeId
            : nodeId // ignore: cast_nullable_to_non_nullable
                  as String?,
        edgeId: freezed == edgeId
            ? _value.edgeId
            : edgeId // ignore: cast_nullable_to_non_nullable
                  as String?,
        context: freezed == context
            ? _value._context
            : context // ignore: cast_nullable_to_non_nullable
                  as Map<String, Object?>?,
        timestamp: freezed == timestamp
            ? _value.timestamp
            : timestamp // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$UyavaGraphDiagnosticPayloadImpl extends _UyavaGraphDiagnosticPayload {
  const _$UyavaGraphDiagnosticPayloadImpl({
    required this.code,
    @JsonKey(fromJson: _integrityCodeFromJson, toJson: _integrityCodeToJson)
    this.codeEnum,
    @JsonKey(fromJson: _diagnosticLevelFromJson, toJson: _diagnosticLevelToJson)
    required this.level,
    this.nodeId,
    this.edgeId,
    final Map<String, Object?>? context,
    @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
    this.timestamp,
  }) : _context = context,
       super._();

  factory _$UyavaGraphDiagnosticPayloadImpl.fromJson(
    Map<String, dynamic> json,
  ) => _$$UyavaGraphDiagnosticPayloadImplFromJson(json);

  @override
  final String code;
  @override
  @JsonKey(fromJson: _integrityCodeFromJson, toJson: _integrityCodeToJson)
  final UyavaGraphIntegrityCode? codeEnum;
  @override
  @JsonKey(fromJson: _diagnosticLevelFromJson, toJson: _diagnosticLevelToJson)
  final UyavaDiagnosticLevel level;
  @override
  final String? nodeId;
  @override
  final String? edgeId;
  final Map<String, Object?>? _context;
  @override
  Map<String, Object?>? get context {
    final value = _context;
    if (value == null) return null;
    if (_context is EqualUnmodifiableMapView) return _context;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  @override
  @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
  final DateTime? timestamp;

  @override
  String toString() {
    return 'UyavaGraphDiagnosticPayload(code: $code, codeEnum: $codeEnum, level: $level, nodeId: $nodeId, edgeId: $edgeId, context: $context, timestamp: $timestamp)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UyavaGraphDiagnosticPayloadImpl &&
            (identical(other.code, code) || other.code == code) &&
            (identical(other.codeEnum, codeEnum) ||
                other.codeEnum == codeEnum) &&
            (identical(other.level, level) || other.level == level) &&
            (identical(other.nodeId, nodeId) || other.nodeId == nodeId) &&
            (identical(other.edgeId, edgeId) || other.edgeId == edgeId) &&
            const DeepCollectionEquality().equals(other._context, _context) &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    code,
    codeEnum,
    level,
    nodeId,
    edgeId,
    const DeepCollectionEquality().hash(_context),
    timestamp,
  );

  /// Create a copy of UyavaGraphDiagnosticPayload
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UyavaGraphDiagnosticPayloadImplCopyWith<_$UyavaGraphDiagnosticPayloadImpl>
  get copyWith =>
      __$$UyavaGraphDiagnosticPayloadImplCopyWithImpl<
        _$UyavaGraphDiagnosticPayloadImpl
      >(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$UyavaGraphDiagnosticPayloadImplToJson(this);
  }
}

abstract class _UyavaGraphDiagnosticPayload
    extends UyavaGraphDiagnosticPayload {
  const factory _UyavaGraphDiagnosticPayload({
    required final String code,
    @JsonKey(fromJson: _integrityCodeFromJson, toJson: _integrityCodeToJson)
    final UyavaGraphIntegrityCode? codeEnum,
    @JsonKey(fromJson: _diagnosticLevelFromJson, toJson: _diagnosticLevelToJson)
    required final UyavaDiagnosticLevel level,
    final String? nodeId,
    final String? edgeId,
    final Map<String, Object?>? context,
    @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
    final DateTime? timestamp,
  }) = _$UyavaGraphDiagnosticPayloadImpl;
  const _UyavaGraphDiagnosticPayload._() : super._();

  factory _UyavaGraphDiagnosticPayload.fromJson(Map<String, dynamic> json) =
      _$UyavaGraphDiagnosticPayloadImpl.fromJson;

  @override
  String get code;
  @override
  @JsonKey(fromJson: _integrityCodeFromJson, toJson: _integrityCodeToJson)
  UyavaGraphIntegrityCode? get codeEnum;
  @override
  @JsonKey(fromJson: _diagnosticLevelFromJson, toJson: _diagnosticLevelToJson)
  UyavaDiagnosticLevel get level;
  @override
  String? get nodeId;
  @override
  String? get edgeId;
  @override
  Map<String, Object?>? get context;
  @override
  @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
  DateTime? get timestamp;

  /// Create a copy of UyavaGraphDiagnosticPayload
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UyavaGraphDiagnosticPayloadImplCopyWith<_$UyavaGraphDiagnosticPayloadImpl>
  get copyWith => throw _privateConstructorUsedError;
}
