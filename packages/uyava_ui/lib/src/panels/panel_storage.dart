import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'panel_contract.dart';

const int _kPanelStorageVersion = 3;

/// Snapshot of a stored panel layout alongside metadata.
@immutable
class UyavaPanelLayoutSnapshot {
  const UyavaPanelLayoutSnapshot({required this.state, required this.savedAt});

  final UyavaPanelLayoutState state;
  final DateTime savedAt;
}

/// Converts layout snapshots to and from their serialized form.
class UyavaPanelLayoutCodec {
  const UyavaPanelLayoutCodec();

  String encode(UyavaPanelLayoutSnapshot snapshot) {
    final entries = snapshot.state.entries
        .map(
          (entry) => <String, Object?>{
            'id': entry.id.value,
            if (entry.visibility != null) 'visibility': entry.visibility!.name,
            if (entry.order != null) 'order': entry.order,
            if (entry.splitFraction != null)
              'splitFraction': entry.splitFraction,
            if (entry.extraState != null && entry.extraState!.isNotEmpty)
              'extraState': entry.extraState,
          },
        )
        .toList();
    return jsonEncode(<String, Object?>{
      'version': _kPanelStorageVersion,
      'savedAt': snapshot.savedAt.toUtc().toIso8601String(),
      'layoutSchemaId': snapshot.state.layoutSchemaId,
      'filtersSchemaId': snapshot.state.filtersSchemaId,
      if (snapshot.state.focusedPanel != null)
        'focusedPanel': snapshot.state.focusedPanel!.value,
      if (snapshot.state.configurationId != null)
        'configurationId': snapshot.state.configurationId,
      if (snapshot.state.splitFractions.isNotEmpty)
        'splitFractions': snapshot.state.splitFractions,
      'entries': entries,
    });
  }

  UyavaPanelLayoutSnapshot? decode(String data) {
    final decoded = jsonDecode(data);
    if (decoded is! Map<String, Object?>) {
      return null;
    }
    final version = decoded['version'];
    if (version is! num) {
      return null;
    }
    final versionValue = version.toInt();
    if (versionValue < 1 || versionValue > _kPanelStorageVersion) {
      return null;
    }
    final savedAtRaw = decoded['savedAt'];
    if (savedAtRaw is! String) {
      return null;
    }
    final savedAt = DateTime.tryParse(savedAtRaw)?.toUtc();
    if (savedAt == null) {
      return null;
    }

    final entriesRaw = decoded['entries'];
    if (entriesRaw is! List) {
      return null;
    }
    final entries = <UyavaPanelLayoutEntry>[];
    for (final entryRaw in entriesRaw) {
      if (entryRaw is! Map<String, Object?>) {
        continue;
      }
      final idValue = entryRaw['id'];
      if (idValue is! String || idValue.isEmpty) {
        continue;
      }
      UyavaPanelVisibility? visibility;
      final visibilityRaw = entryRaw['visibility'];
      if (visibilityRaw is String) {
        visibility = UyavaPanelVisibility.values.firstWhere(
          (candidate) => candidate.name == visibilityRaw,
          orElse: () => UyavaPanelVisibility.visible,
        );
      }
      final orderRaw = entryRaw['order'];
      final order = orderRaw is num ? orderRaw.toInt() : null;
      final splitRaw = entryRaw['splitFraction'];
      final splitFraction = splitRaw is num ? splitRaw.toDouble() : null;
      final extraStateRaw = entryRaw['extraState'];
      Map<String, Object?>? extraState;
      if (extraStateRaw is Map) {
        extraState = extraStateRaw.map(
          (key, value) => MapEntry(key.toString(), value),
        );
      }
      entries.add(
        UyavaPanelLayoutEntry(
          id: UyavaPanelId(idValue),
          visibility: visibility,
          order: order,
          splitFraction: splitFraction,
          extraState: extraState,
        ),
      );
    }

    final focusedRaw = decoded['focusedPanel'];
    final focusedPanel = focusedRaw is String ? UyavaPanelId(focusedRaw) : null;
    String? configurationId;
    final configurationRaw = decoded['configurationId'];
    if (configurationRaw is String && configurationRaw.isNotEmpty) {
      configurationId = configurationRaw;
    }
    final splitFractions = <String, double>{};
    if (versionValue >= 2) {
      final fractionsRaw = decoded['splitFractions'];
      if (fractionsRaw is Map) {
        for (final entry in fractionsRaw.entries) {
          final key = entry.key.toString();
          final value = entry.value;
          if (key.isEmpty || value is! num) {
            continue;
          }
          splitFractions[key] = value.toDouble();
        }
      }
    }

    String layoutSchemaId = kDefaultPanelLayoutSchemaId;
    final Object? layoutSchemaRaw = decoded['layoutSchemaId'];
    if (layoutSchemaRaw is String && layoutSchemaRaw.isNotEmpty) {
      layoutSchemaId = layoutSchemaRaw;
    }
    String filtersSchemaId = kDefaultFiltersSchemaId;
    final Object? filtersSchemaRaw = decoded['filtersSchemaId'];
    if (filtersSchemaRaw is String && filtersSchemaRaw.isNotEmpty) {
      filtersSchemaId = filtersSchemaRaw;
    }

    final state = UyavaPanelLayoutState(
      entries: entries,
      focusedPanel: focusedPanel,
      splitFractions: splitFractions,
      configurationId: configurationId,
      layoutSchemaId: layoutSchemaId,
      filtersSchemaId: filtersSchemaId,
    );
    return UyavaPanelLayoutSnapshot(state: state, savedAt: savedAt);
  }
}

/// Base class describing how panel layouts are persisted for a host.
abstract class UyavaPanelLayoutStorage {
  UyavaPanelLayoutStorage({
    Duration? maxAge,
    DateTime Function()? now,
    UyavaPanelLayoutCodec? codec,
  }) : maxAge = maxAge ?? const Duration(days: 30),
       _now = now ?? DateTime.now,
       _codec = codec ?? const UyavaPanelLayoutCodec();

  final Duration maxAge;
  final DateTime Function() _now;
  final UyavaPanelLayoutCodec _codec;

  Future<String?> readRaw();
  Future<void> writeRaw(String data);
  Future<void> deleteRaw();

  Future<UyavaPanelLayoutState?> loadState() async {
    final raw = await readRaw();
    if (raw == null || raw.isEmpty) {
      return null;
    }
    final UyavaPanelLayoutSnapshot? snapshot = decodeSnapshot(raw);
    if (snapshot == null) {
      await deleteRaw();
      return null;
    }
    if (isExpired(snapshot)) {
      await deleteRaw();
      return null;
    }
    return snapshot.state;
  }

  Future<void> saveState(UyavaPanelLayoutState state) async {
    final snapshot = UyavaPanelLayoutSnapshot(
      state: state,
      savedAt: _now().toUtc(),
    );
    final encoded = _codec.encode(snapshot);
    await writeRaw(encoded);
  }

  Future<void> clear() => deleteRaw();

  @protected
  UyavaPanelLayoutSnapshot? decodeSnapshot(String raw) {
    try {
      return _codec.decode(raw);
    } catch (_) {
      return null;
    }
  }

  @protected
  bool isExpired(UyavaPanelLayoutSnapshot snapshot) {
    final age = _now().toUtc().difference(snapshot.savedAt);
    return age > maxAge;
  }
}
