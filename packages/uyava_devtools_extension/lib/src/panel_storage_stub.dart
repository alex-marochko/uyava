import 'package:uyava_ui/uyava_ui.dart';

class DevToolsPanelLayoutStorage extends UyavaPanelLayoutStorage {
  DevToolsPanelLayoutStorage({
    required String storageKey,
    List<String> legacyStorageKeys = const [],
    super.maxAge,
    super.now,
  }) : assert(storageKey.isNotEmpty, 'storageKey must not be empty.'),
       _storageKey = storageKey,
       _legacyStorageKeys = List.unmodifiable(legacyStorageKeys);

  final String _storageKey;
  final List<String> _legacyStorageKeys;
  final Map<String, String> _stored = <String, String>{};

  @override
  Future<String?> readRaw() async => _stored[_storageKey];

  @override
  Future<void> writeRaw(String data) async {
    _stored[_storageKey] = data;
  }

  @override
  Future<void> deleteRaw() async {
    _stored.remove(_storageKey);
    for (final key in _legacyStorageKeys) {
      _stored.remove(key);
    }
  }

  @override
  Future<UyavaPanelLayoutState?> loadState() async {
    final UyavaPanelLayoutState? current = await _loadFromKey(_storageKey);
    if (current != null) {
      return current;
    }
    for (final String key in _legacyStorageKeys) {
      final UyavaPanelLayoutState? legacy = await _loadFromKey(key);
      if (legacy != null) {
        return legacy;
      }
    }
    return null;
  }

  Future<UyavaPanelLayoutState?> _loadFromKey(String key) async {
    final String? raw = _stored[key];
    if (raw == null || raw.isEmpty) {
      return null;
    }
    final UyavaPanelLayoutSnapshot? snapshot = decodeSnapshot(raw);
    if (snapshot == null || isExpired(snapshot)) {
      _stored.remove(key);
      return null;
    }
    return snapshot.state;
  }
}
