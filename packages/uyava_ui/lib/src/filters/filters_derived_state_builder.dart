import 'package:uyava_core/uyava_core.dart';

import 'filters_form_state.dart';
import 'filters_options_controller.dart';

/// Derived data for rendering the filters UI.
class FiltersDerivedState {
  const FiltersDerivedState({
    required this.form,
    required this.nodeOptions,
    required this.nodeLookup,
    required this.nodeDescendants,
    required this.depthLevels,
    required this.tagOptions,
    required this.tagLookup,
  });

  final FiltersFormState form;
  final List<NodeFilterOption> nodeOptions;
  final Map<String, NodeFilterOption> nodeLookup;
  final Map<String, List<String>> nodeDescendants;
  final List<int> depthLevels;
  final List<TagFilterOption> tagOptions;
  final Map<String, TagFilterOption> tagLookup;
}

/// Helper for rebuilding derived filter options from graph data.
class FiltersDerivedStateBuilder {
  FiltersDerivedStateBuilder({
    NodeFilterOptionsController? nodeController,
    TagFilterOptionsController? tagController,
  }) : _nodeController = nodeController ?? NodeFilterOptionsController(),
       _tagController = tagController ?? TagFilterOptionsController();

  final NodeFilterOptionsController _nodeController;
  final TagFilterOptionsController _tagController;

  FiltersDerivedState build({
    required FiltersFormState form,
    required List<UyavaNode> nodes,
    required List<GraphMetricSnapshot> metrics,
    required List<GraphEventChainSnapshot> eventChains,
  }) {
    _nodeController.update(nodes);
    _tagController.update(
      nodes: nodes,
      metrics: metrics,
      eventChains: eventChains,
    );

    final FiltersFormState pruned = form.pruneSelections(
      validNodeIds: _nodeController.lookup.keys.toSet(),
      validTags: _tagController.lookup.keys.toSet(),
      validGroupingDepths: _nodeController.depthLevels.toSet(),
    );

    return FiltersDerivedState(
      form: pruned,
      nodeOptions: _nodeController.options,
      nodeLookup: _nodeController.lookup,
      nodeDescendants: _nodeController.descendants,
      depthLevels: _nodeController.depthLevels,
      tagOptions: _tagController.options,
      tagLookup: _tagController.lookup,
    );
  }
}
