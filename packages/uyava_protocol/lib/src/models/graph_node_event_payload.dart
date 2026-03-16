// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';

import '../base_types.dart';

part 'graph_node_event_payload.freezed.dart';
part 'graph_node_event_payload.g.dart';

/// Wire payload for node-scoped events.
@Freezed(toJson: true)
class UyavaGraphNodeEventPayload with _$UyavaGraphNodeEventPayload {
  const UyavaGraphNodeEventPayload._();

  const factory UyavaGraphNodeEventPayload({
    @JsonKey(name: 'nodeId') required String nodeId,
    @JsonKey(name: 'message') required String message,
    @JsonKey(fromJson: _severityFromJson, toJson: _severityToJson)
    UyavaSeverity? severity,
    List<String>? tags,
    @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
    required DateTime timestamp,
    @JsonKey(name: UyavaPayloadKeys.sourceRef) String? sourceRef,
    Map<String, dynamic>? payload,
  }) = _UyavaGraphNodeEventPayload;

  factory UyavaGraphNodeEventPayload.fromJson(Map<String, dynamic> json) =>
      _$UyavaGraphNodeEventPayloadFromJson(json);
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
