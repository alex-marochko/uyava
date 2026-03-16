// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;

import 'package:uyava_ui/uyava_ui.dart';

class DevToolsPanelLayoutStorage extends UyavaPanelLayoutStorage {
  DevToolsPanelLayoutStorage({
    required String storageKey,
    List<String> legacyStorageKeys = const [],
    super.maxAge,
    super.now,
  }) : _storageKey = storageKey,
       _legacyStorageKeys = List.unmodifiable(legacyStorageKeys);

  final String _storageKey;
  final List<String> _legacyStorageKeys;

  @override
  Future<String?> readRaw() async {
    return html.window.localStorage[_storageKey];
  }

  @override
  Future<void> writeRaw(String data) async {
    html.window.localStorage[_storageKey] = data;
  }

  @override
  Future<void> deleteRaw() async {
    html.window.localStorage.remove(_storageKey);
    for (final key in _legacyStorageKeys) {
      html.window.localStorage.remove(key);
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
    final String? raw = html.window.localStorage[key];
    if (raw == null || raw.isEmpty) {
      return null;
    }
    final UyavaPanelLayoutSnapshot? snapshot = decodeSnapshot(raw);
    if (snapshot == null) {
      html.window.localStorage.remove(key);
      return null;
    }
    if (isExpired(snapshot)) {
      html.window.localStorage.remove(key);
      return null;
    }
    return snapshot.state;
  }
}
