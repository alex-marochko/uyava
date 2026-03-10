import 'package:flutter_test/flutter_test.dart';
import 'package:uyava_core/uyava_core.dart';
import 'package:uyava_ui/uyava_ui.dart';

GraphController _buildController() {
  final GraphController controller = GraphController(engine: GridLayout());
  controller.replaceGraph(<String, dynamic>{
    'nodes': <Map<String, dynamic>>[
      <String, dynamic>{'id': 'root', 'label': 'Root'},
      <String, dynamic>{
        'id': 'child',
        'label': 'Child',
        'parentId': 'root',
        'tags': <String>['alpha'],
      },
      <String, dynamic>{'id': 'other', 'label': 'Other'},
    ],
    'edges': const <Map<String, dynamic>>[],
  }, const Size2D(400, 400));
  return controller;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FiltersViewModel', () {
    test('applies debounced search updates to controller filters', () async {
      final GraphController controller = _buildController();
      addTearDown(controller.dispose);

      final FiltersViewModel viewModel = FiltersViewModel(
        controller: controller,
        autoApplyDebounce: const Duration(milliseconds: 10),
      );
      addTearDown(viewModel.dispose);

      expect(controller.filters.search, isNull);

      viewModel.setPattern('child');
      await Future<void>.delayed(const Duration(milliseconds: 20));
      await pumpEventQueue();

      final GraphFilterSearch? applied = controller.filters.search;
      expect(applied, isNotNull);
      expect(applied!.pattern, 'child');
      expect(viewModel.state.form.pattern, 'child');
    });

    test(
      'replaceController rebuilds derived options and search text',
      () async {
        final GraphController first = _buildController();
        addTearDown(first.dispose);

        final FiltersViewModel viewModel = FiltersViewModel(
          controller: first,
          autoApplyDebounce: const Duration(milliseconds: 5),
        );
        addTearDown(viewModel.dispose);

        expect(viewModel.state.nodeLookup.keys, containsAll(<String>['root']));

        final GraphController second = GraphController(engine: GridLayout());
        second.replaceGraph(<String, dynamic>{
          'nodes': <Map<String, dynamic>>[
            <String, dynamic>{'id': 'serviceX', 'label': 'Service X'},
          ],
          'edges': const <Map<String, dynamic>>[],
        }, const Size2D(400, 400));
        addTearDown(second.dispose);

        viewModel.replaceController(second);
        await pumpEventQueue();

        expect(viewModel.state.nodeLookup.keys, contains('serviceX'));
        expect(viewModel.state.form.pattern, isEmpty);
        expect(viewModel.searchController.text, isEmpty);
      },
    );

    test(
      'debounce toggle and panel toggles update state + apply flow',
      () async {
        final GraphController controller = _buildController();
        addTearDown(controller.dispose);

        final FiltersViewModel viewModel = FiltersViewModel(
          controller: controller,
          autoApplyDebounce: const Duration(milliseconds: 50),
        );
        addTearDown(viewModel.dispose);

        viewModel.toggleDebounce();
        expect(viewModel.state.debounceEnabled, isFalse);

        viewModel.setPattern('root');
        await Future<void>.delayed(const Duration(milliseconds: 60));
        expect(controller.filters.search, isNull);

        viewModel.applyNow();
        expect(controller.filters.search!.pattern, 'root');

        viewModel.syncPanelToggles(
          filterAllPanels: false,
          autoCompactEnabled: false,
        );
        expect(viewModel.state.filterAllPanels, isFalse);
        expect(viewModel.state.autoCompactEnabled, isFalse);

        viewModel.toggleDebounce();
        await pumpEventQueue();
        expect(viewModel.state.debounceEnabled, isTrue);
      },
    );
  });
}
