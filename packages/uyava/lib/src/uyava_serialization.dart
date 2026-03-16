part of 'package:uyava/uyava.dart';

Map<String, dynamic> _canonicalMetricSample(UyavaMetricSamplePayload payload) {
  final Map<String, dynamic> json = Map<String, dynamic>.from(payload.toJson());
  json.removeWhere((key, value) => value == null);
  return json;
}

Map<String, dynamic> _canonicalChainDefinition(
  UyavaEventChainDefinitionPayload payload,
) {
  final Map<String, dynamic> json = Map<String, dynamic>.from(payload.toJson());
  json['steps'] = payload.steps
      .map(
        (step) =>
            _deepRemoveNullsFromJson(Map<String, dynamic>.from(step.toJson())),
      )
      .toList(growable: false);
  return _deepRemoveNullsFromJson(json);
}

Map<String, dynamic> _deepRemoveNullsFromJson(Map<String, dynamic> source) {
  final Map<String, dynamic> result = <String, dynamic>{};
  source.forEach((String key, dynamic value) {
    if (value == null) return;
    if (value is Map<String, dynamic>) {
      result[key] = _deepRemoveNullsFromJson(value);
    } else if (value is Map) {
      result[key] = _deepRemoveNullsFromJson(
        Map<String, dynamic>.fromEntries(
          value.entries
              .where((entry) => entry.key is String)
              .map((entry) => MapEntry(entry.key as String, entry.value)),
        ),
      );
    } else if (value is List) {
      final List<dynamic> normalized = <dynamic>[];
      for (final dynamic element in value) {
        if (element == null) {
          continue;
        }
        if (element is Map<String, dynamic>) {
          normalized.add(_deepRemoveNullsFromJson(element));
        } else if (element is Map) {
          normalized.add(
            _deepRemoveNullsFromJson(
              Map<String, dynamic>.fromEntries(
                element.entries
                    .where((entry) => entry.key is String)
                    .map((entry) => MapEntry(entry.key as String, entry.value)),
              ),
            ),
          );
        } else {
          normalized.add(element);
        }
      }
      result[key] = normalized;
    } else {
      result[key] = value;
    }
  });
  return result;
}
