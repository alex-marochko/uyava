import '../normalization.dart';

/// Shared data handling policies leveraged by the Uyava SDK, core, and hosts.
class UyavaDataPolicies {
  /// Canonical tag catalog recommended for cross-tooling consistency.
  ///
  /// Tags are stored in lowercase for case-insensitive comparisons.
  static const Set<String> tagCatalog = <String>{
    'ui',
    'state',
    'domain',
    'data',
    'network',
    'external',
    'integration',
    'test',
    'critical',
    'legacy',
    'experimental',
    'platform',
    'shared',
    'core',
    'feature',
    'infra',
    'observability',
    'security',
    'auth',
  };

  /// Palette used when hosts request a prioritized set of accent colors.
  ///
  /// Colors are normalized to uppercase hex and free of alpha when possible
  /// to keep equality checks stable across components.
  static const List<String> priorityColorPalette = <String>[
    '#1F6FEB', // blue
    '#58A6FF', // light blue
    '#3FB950', // green
    '#F78166', // orange
    '#FF7B72', // red
    '#D29922', // amber
    '#A371F7', // purple
    '#8B949E', // gray
  ];

  /// Returns a list of catalog tags that appear in [tags].
  ///
  /// The returned values are lowercase catalog identifiers, preserving the
  /// order of first appearance and deduplicated.
  static List<String> catalogMatches(Iterable<String> tags) {
    final List<String> matches = <String>[];
    final Set<String> seen = <String>{};
    for (final String tag in tags) {
      final String normalized = tag.trim().toLowerCase();
      if (normalized.isEmpty) continue;
      if (!tagCatalog.contains(normalized)) continue;
      if (seen.add(normalized)) {
        matches.add(normalized);
      }
    }
    return matches.isEmpty
        ? const <String>[]
        : List<String>.unmodifiable(matches);
  }

  /// Returns the index in [priorityColorPalette] for [color] when available.
  ///
  /// The [color] may be any raw input accepted by [normalizeColor]. When the
  /// value is not part of the palette the method returns `null`.
  static int? priorityColorIndex(Object? color) {
    final UyavaColorNormalizationResult result = normalizeColor(color);
    final String? value = result.value;
    if (value == null) return null;
    final int index = priorityColorPalette.indexOf(value);
    return index >= 0 ? index : null;
  }

  /// Convenience helper to check if [color] belongs to the priority palette.
  static bool isPriorityColor(Object? color) =>
      priorityColorIndex(color) != null;
}
