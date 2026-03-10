import 'package:uyava_protocol/uyava_protocol.dart';

UyavaSeverity? parseSeverity(Object? value) {
  if (value is UyavaSeverity) {
    return value;
  }
  if (value is String && value.isNotEmpty) {
    for (final UyavaSeverity candidate in UyavaSeverity.values) {
      if (candidate.name == value || candidate.name == value.trim()) {
        return candidate;
      }
    }
  }
  return null;
}

String? trimmedString(Object? value) {
  if (value is! String) return null;
  final String trimmed = value.trim();
  if (trimmed.isEmpty) return null;
  return trimmed;
}
