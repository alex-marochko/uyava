// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';

import '../base_types.dart';

part 'graph_edge_event_payload.freezed.dart';
part 'graph_edge_event_payload.g.dart';

/// Wire payload for edge events (directed interactions between nodes).
@Freezed(toJson: true)
class UyavaGraphEdgeEventPayload with _$UyavaGraphEdgeEventPayload {
  const UyavaGraphEdgeEventPayload._();

  const factory UyavaGraphEdgeEventPayload({
    @JsonKey(name: 'edge') String? edgeId,
    @JsonKey(name: 'from') required String from,
    @JsonKey(name: 'to') required String to,
    @JsonKey(name: 'message') required String message,
    @JsonKey(fromJson: _severityFromJson, toJson: _severityToJson)
    UyavaSeverity? severity,
    @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
    required DateTime timestamp,
    @JsonKey(name: UyavaPayloadKeys.sourceRef) String? sourceRef,
  }) = _UyavaGraphEdgeEventPayload;

  factory UyavaGraphEdgeEventPayload.fromJson(Map<String, dynamic> json) =>
      _$UyavaGraphEdgeEventPayloadFromJson(json);
}

UyavaSeverity? _severityFromJson(String? value) {
  if (value == null || value.isEmpty) return null;
  for (final candidate in UyavaSeverity.values) {
    if (candidate.name == value) {
      return candidate;
    }
  }
  return null;
}

String? _severityToJson(UyavaSeverity? value) => value?.name;

DateTime _dateTimeFromJson(String value) => DateTime.parse(value).toUtc();

String _dateTimeToJson(DateTime value) => value.toUtc().toIso8601String();
