import 'package:flutter_test/flutter_test.dart';
import 'package:uyava_ui/uyava_ui.dart';

class _RecordingAdapter extends UyavaPanelShellViewAdapter {
  final List<UyavaPanelShellSnapshot> snapshots = [];
  final List<UyavaPanelLayoutState> persistedStates = [];
  bool disposed = false;

  @override
  void didUpdateSnapshot(UyavaPanelShellSnapshot snapshot) {
    snapshots.add(snapshot);
  }

  @override
  void handlePersistedState(UyavaPanelLayoutState state) {
    persistedStates.add(state);
  }

  @override
  void handleControllerDisposed() {
    disposed = true;
  }
}

void main() {
  group('UyavaPanelShellController', () {
    test('setVisibility updates state and notifies adapter', () {
      final panelA = UyavaPanelId('panelA');
      final controller = UyavaPanelShellController(
        registry: [UyavaPanelRegistryEntry(id: panelA, title: 'Panel A')],
        spec: UyavaPanelShellSpec(root: UyavaPanelLeaf(panelA)),
      );
      final adapter = _RecordingAdapter();
      controller.attachAdapter(adapter);
      adapter.snapshots.clear();
      adapter.persistedStates.clear();

      controller.setVisibility(panelA, UyavaPanelVisibility.hidden);

      expect(controller.visibilityFor(panelA), UyavaPanelVisibility.hidden);
      expect(adapter.snapshots, isNotEmpty);
      expect(
        adapter.snapshots.last.state.entries
            .firstWhere((entry) => entry.id == panelA)
            .visibility,
        UyavaPanelVisibility.hidden,
      );
      expect(adapter.persistedStates, isNotEmpty);
      expect(
        adapter.persistedStates.last.entries
            .firstWhere((entry) => entry.id == panelA)
            .visibility,
        UyavaPanelVisibility.hidden,
      );
    });

    test('setSplitFraction stores fractions for panel leaf', () {
      final panelA = UyavaPanelId('panelA');
      final panelB = UyavaPanelId('panelB');
      final controller = UyavaPanelShellController(
        registry: [
          UyavaPanelRegistryEntry(id: panelA, title: 'Panel A'),
          UyavaPanelRegistryEntry(id: panelB, title: 'Panel B'),
        ],
        spec: UyavaPanelShellSpec(
          root: UyavaPanelSplit(
            key: 'root',
            axis: UyavaPanelSplitAxis.horizontal,
            children: [UyavaPanelLeaf(panelA), UyavaPanelLeaf(panelB)],
          ),
        ),
      );
      final adapter = _RecordingAdapter();
      controller.attachAdapter(adapter);
      adapter.snapshots.clear();
      adapter.persistedStates.clear();

      controller.setSplitFraction(panelA, 0.65);

      expect(
        controller.state.splitFractions['panel:${panelA.value}'],
        closeTo(0.65, 1e-6),
      );
      expect(adapter.persistedStates, isNotEmpty);
      expect(
        adapter.persistedStates.last.splitFractions['panel:${panelA.value}'],
        closeTo(0.65, 1e-6),
      );
    });

    test('setConfigurationId persists configuration value', () {
      final panelA = UyavaPanelId('panelA');
      final controller = UyavaPanelShellController(
        registry: [UyavaPanelRegistryEntry(id: panelA, title: 'Panel A')],
        spec: UyavaPanelShellSpec(root: UyavaPanelLeaf(panelA)),
      );
      final adapter = _RecordingAdapter();
      controller.attachAdapter(adapter);
      adapter.persistedStates.clear();

      controller.setConfigurationId('presetA');

      expect(controller.state.configurationId, 'presetA');
      expect(adapter.persistedStates, isNotEmpty);
      expect(adapter.persistedStates.last.configurationId, 'presetA');

      controller.dispose();
      expect(adapter.disposed, isTrue);
    });
  });
}
