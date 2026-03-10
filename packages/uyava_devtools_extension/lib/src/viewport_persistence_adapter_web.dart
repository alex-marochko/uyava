// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter

import 'dart:convert';
import 'dart:html' as html;

import 'package:uyava_ui/uyava_ui.dart';

ViewportPersistenceAdapter createViewportPersistenceAdapterImpl() =>
    _WebViewportPersistenceAdapter();

class _WebViewportPersistenceAdapter implements ViewportPersistenceAdapter {
  static const String _storageKey = 'uyava.devtools.viewport';

  @override
  Future<GraphViewportState?> load() async {
    final String? raw = html.window.localStorage[_storageKey];
    if (raw == null || raw.isEmpty) return null;
    try {
      final Map<String, dynamic> data = jsonDecode(raw) as Map<String, dynamic>;
      return GraphViewportState.fromJson(
        data.map<String, Object?>((key, value) => MapEntry(key, value)),
      );
    } catch (err) {
      html.window.localStorage.remove(_storageKey);
      return null;
    }
  }

  @override
  Future<void> save(GraphViewportState state) async {
    final Map<String, Object?> json = state.toJson();
    html.window.localStorage[_storageKey] = jsonEncode(json);
  }

  @override
  Future<void> clear() async {
    html.window.localStorage.remove(_storageKey);
  }
}
