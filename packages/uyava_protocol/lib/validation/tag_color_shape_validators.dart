/// Shared normalization helpers used across the Uyava SDK, protocol, and core.
///
/// The goal is to keep data sanitization consistent for tags, colors, and
/// shapes regardless of which component receives the raw payload first.

class UyavaTagNormalizationResult {
  const UyavaTagNormalizationResult._({
    required this.values,
    required this.normalized,
    required this.hadInput,
  });

  /// Trimmed, case-preserving tag values suitable for display on the wire.
  final List<String> values;

  /// Lowercase snapshot used for case-insensitive comparisons and filters.
  final List<String> normalized;

  /// Whether the caller supplied any input (useful for diagnostics).
  final bool hadInput;

  /// Returns `true` when at least one usable tag remains.
  bool get hasValues => values.isNotEmpty;

  static const UyavaTagNormalizationResult empty =
      UyavaTagNormalizationResult._(
        values: <String>[],
        normalized: <String>[],
        hadInput: false,
      );
}

/// Normalizes tag payloads by trimming, removing empties/non-strings, and
/// de-duplicating case-insensitively while preserving first-seen ordering.
UyavaTagNormalizationResult normalizeTags(Object? raw) {
  if (raw is! Iterable) {
    return raw == null
        ? UyavaTagNormalizationResult.empty
        : const UyavaTagNormalizationResult._(
            values: <String>[],
            normalized: <String>[],
            hadInput: true,
          );
  }

  final List<String> display = <String>[];
  final List<String> lowered = <String>[];
  final Set<String> seen = <String>{};

  for (final Object? entry in raw) {
    if (entry is! String) continue;
    final String trimmed = entry.trim();
    if (trimmed.isEmpty) continue;
    final String lower = trimmed.toLowerCase();
    if (seen.add(lower)) {
      display.add(trimmed);
      lowered.add(lower);
    }
  }

  if (display.isEmpty) {
    return const UyavaTagNormalizationResult._(
      values: <String>[],
      normalized: <String>[],
      hadInput: true,
    );
  }

  return UyavaTagNormalizationResult._(
    values: List<String>.unmodifiable(display),
    normalized: List<String>.unmodifiable(lowered),
    hadInput: true,
  );
}

class UyavaColorNormalizationResult {
  const UyavaColorNormalizationResult._({
    required this.value,
    required this.hadInput,
    required this.isValid,
    this.original,
  });

  /// Uppercase hex color (`#RRGGBB` or `#AARRGGBB`) when valid, otherwise null.
  final String? value;

  /// Whether a value was provided by the caller (even if invalid).
  final bool hadInput;

  /// Indicates if the provided value passed validation.
  final bool isValid;

  /// The original payload supplied by the caller (trimmed when a string).
  final Object? original;

  /// Convenience flag to help callers decide when to emit diagnostics.
  bool get shouldReportInvalid => hadInput && !isValid;
}

/// Accepts raw color payloads, enforcing `#RRGGBB` or `#AARRGGBB`.
UyavaColorNormalizationResult normalizeColor(Object? raw) {
  if (raw == null) {
    return const UyavaColorNormalizationResult._(
      value: null,
      hadInput: false,
      isValid: true,
    );
  }
  if (raw is! String) {
    return UyavaColorNormalizationResult._(
      value: null,
      hadInput: true,
      isValid: false,
      original: raw,
    );
  }
  final String trimmed = raw.trim();
  if (!trimmed.startsWith('#')) {
    return UyavaColorNormalizationResult._(
      value: null,
      hadInput: true,
      isValid: false,
      original: trimmed,
    );
  }
  final String hex = trimmed.substring(1);
  if (hex.length != 6 && hex.length != 8) {
    return UyavaColorNormalizationResult._(
      value: null,
      hadInput: true,
      isValid: false,
      original: trimmed,
    );
  }
  final RegExp hexPattern = RegExp(r'^[0-9a-fA-F]+$');
  if (!hexPattern.hasMatch(hex)) {
    return UyavaColorNormalizationResult._(
      value: null,
      hadInput: true,
      isValid: false,
      original: trimmed,
    );
  }
  return UyavaColorNormalizationResult._(
    value: '#${hex.toUpperCase()}',
    hadInput: true,
    isValid: true,
    original: trimmed,
  );
}

class UyavaShapeNormalizationResult {
  const UyavaShapeNormalizationResult._({
    required this.value,
    required this.hadInput,
    required this.isValid,
    this.original,
  });

  /// Lowercase identifier when valid, otherwise null.
  final String? value;
  final bool hadInput;
  final bool isValid;
  final Object? original;

  bool get shouldReportInvalid => hadInput && !isValid;
}

/// Accepts lowercase identifiers matching `^[a-z0-9_-]+$`.
UyavaShapeNormalizationResult normalizeShape(Object? raw) {
  if (raw == null) {
    return const UyavaShapeNormalizationResult._(
      value: null,
      hadInput: false,
      isValid: true,
    );
  }
  if (raw is! String) {
    return UyavaShapeNormalizationResult._(
      value: null,
      hadInput: true,
      isValid: false,
      original: raw,
    );
  }
  final String trimmed = raw.trim();
  if (trimmed.isEmpty) {
    return UyavaShapeNormalizationResult._(
      value: null,
      hadInput: true,
      isValid: false,
      original: trimmed,
    );
  }
  final String lower = trimmed.toLowerCase();
  final RegExp allowed = RegExp(r'^[a-z0-9_-]+$');
  if (!allowed.hasMatch(lower)) {
    return UyavaShapeNormalizationResult._(
      value: null,
      hadInput: true,
      isValid: false,
      original: trimmed,
    );
  }
  return UyavaShapeNormalizationResult._(
    value: lower,
    hadInput: true,
    isValid: true,
    original: trimmed,
  );
}
