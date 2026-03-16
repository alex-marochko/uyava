/// Reserved wrapper for replay/REST ingest payloads.
///
/// Current hosts treat these envelopes as inert; Desktop replay will decode the
/// body once the feature flag is enabled.
class UyavaReplayEnvelopePayload {
  const UyavaReplayEnvelopePayload({
    required this.schemaVersion,
    this.chunkIndex,
    this.totalChunks,
    this.source,
    this.body = const <String, Object?>{},
  });

  /// Schema version for the replay envelope stream.
  final int schemaVersion;

  /// Optional chunk index within a multi-part replay stream.
  final int? chunkIndex;

  /// Optional total chunk count for a multi-part replay stream.
  final int? totalChunks;

  /// Optional ingest source metadata (e.g., file path, endpoint).
  final Map<String, Object?>? source;

  /// Raw payload body to be interpreted by the replay/REST adapters.
  final Map<String, Object?> body;

  factory UyavaReplayEnvelopePayload.fromJson(Map<String, dynamic> json) {
    final Map<String, Object?> parsedBody = <String, Object?>{};
    final Object? rawBody = json['body'];
    if (rawBody is Map) {
      rawBody.forEach((key, value) {
        parsedBody[key.toString()] = value;
      });
    }
    return UyavaReplayEnvelopePayload(
      schemaVersion: _coerceInt(json['schemaVersion']) ?? 1,
      chunkIndex: _coerceInt(json['chunkIndex']),
      totalChunks: _coerceInt(json['totalChunks']),
      source: _coerceMap(json['source']),
      body: parsedBody,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'schemaVersion': schemaVersion,
      if (chunkIndex != null) 'chunkIndex': chunkIndex,
      if (totalChunks != null) 'totalChunks': totalChunks,
      if (source != null) 'source': source,
      if (body.isNotEmpty) 'body': body,
    };
  }
}

int? _coerceInt(Object? raw) {
  if (raw is int) return raw;
  if (raw is num) return raw.toInt();
  return null;
}

Map<String, Object?>? _coerceMap(Object? raw) {
  if (raw is! Map) return null;
  final Map<String, Object?> result = <String, Object?>{};
  raw.forEach((key, value) {
    result[key.toString()] = value;
  });
  return result;
}
