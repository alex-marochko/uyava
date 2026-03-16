import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:uyava_ui/uyava_ui.dart';

class _FakePanelStorage extends UyavaPanelLayoutStorage {
  _FakePanelStorage({super.maxAge});

  String? stored;

  @override
  Future<String?> readRaw() async => stored;

  @override
  Future<void> writeRaw(String data) async {
    stored = data;
  }

  @override
  Future<void> deleteRaw() async {
    stored = null;
  }
}

void main() {
  test('roundtrips layout state through codec', () async {
    final storage = _FakePanelStorage();
    final state = UyavaPanelLayoutState(
      entries: [
        UyavaPanelLayoutEntry(
          id: const UyavaPanelId('graph'),
          visibility: UyavaPanelVisibility.visible,
          order: 0,
          splitFraction: 0.6,
          extraState: {'foo': 'bar'},
        ),
        UyavaPanelLayoutEntry(
          id: const UyavaPanelId('dashboard'),
          visibility: UyavaPanelVisibility.hidden,
          order: 1,
          splitFraction: 0.4,
        ),
      ],
      focusedPanel: const UyavaPanelId('graph'),
      splitFractions: const {
        'panel:graph': 0.6,
        'panel:dashboard': 0.4,
        'split:root': 0.5,
      },
      configurationId: 'horizontal',
      layoutSchemaId: 'test.schema.layout.v1',
      filtersSchemaId: 'test.schema.filters.v1',
    );

    await storage.saveState(state);
    expect(storage.stored, isNotNull);

    final restored = await storage.loadState();
    expect(restored, equals(state));
    expect(restored!.layoutSchemaId, 'test.schema.layout.v1');
    expect(restored.filtersSchemaId, 'test.schema.filters.v1');
  });

  test('expires layouts older than maxAge', () async {
    final storage = _FakePanelStorage(maxAge: const Duration(days: 7));
    final state = UyavaPanelLayoutState(
      entries: [
        UyavaPanelLayoutEntry(
          id: const UyavaPanelId('graph'),
          visibility: UyavaPanelVisibility.visible,
          order: 0,
        ),
      ],
      splitFractions: const {'panel:graph': 1.0},
    );
    await storage.saveState(state);
    expect(storage.stored, isNotNull);

    final decoded = jsonDecode(storage.stored!) as Map<String, Object?>;
    decoded['savedAt'] = DateTime.now()
        .toUtc()
        .subtract(const Duration(days: 90))
        .toIso8601String();
    storage.stored = jsonEncode(decoded);

    final restored = await storage.loadState();
    expect(restored, isNull);
    expect(storage.stored, isNull);
  });

  test('drops invalid payloads gracefully', () async {
    final storage = _FakePanelStorage();
    storage.stored = '{invalid json';

    final restored = await storage.loadState();
    expect(restored, isNull);
    expect(storage.stored, isNull);
  });

  test('loads legacy version 1 snapshots', () async {
    final storage = _FakePanelStorage();
    storage.stored = jsonEncode(<String, Object?>{
      'version': 1,
      'savedAt': DateTime.now().toUtc().toIso8601String(),
      'entries': [
        {'id': 'graph', 'order': 0, 'splitFraction': 0.7},
      ],
    });

    final restored = await storage.loadState();
    expect(restored, isNotNull);
    expect(restored!.splitFractions, isEmpty);
    expect(restored.entries.single.splitFraction, closeTo(0.7, 1e-6));
    expect(restored.layoutSchemaId, kDefaultPanelLayoutSchemaId);
    expect(restored.filtersSchemaId, kDefaultFiltersSchemaId);
  });
}
