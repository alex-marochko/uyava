import 'panel_contract.dart';

const String kUyavaPanelPresetStackedId = 'stacked-v3';
const String kUyavaPanelPresetGraphDetailsId = 'graph-details-v3';

enum UyavaPanelLayoutPreset { stacked, graphWithDetails }

/// Declarative content used by the shared layout presets.
class UyavaPanelPresetContent {
  UyavaPanelPresetContent({
    required this.graphPanelId,
    required List<UyavaPanelId> detailPanelIds,
    required List<UyavaPanelId> footerPanelIds,
  }) : detailPanelIds = List.unmodifiable(detailPanelIds),
       footerPanelIds = List.unmodifiable(footerPanelIds) {
    assert(detailPanelIds.isNotEmpty, 'At least one detail panel is required.');
    assert(footerPanelIds.isNotEmpty, 'At least one footer panel is required.');
  }

  final UyavaPanelId graphPanelId;
  final List<UyavaPanelId> detailPanelIds;
  final List<UyavaPanelId> footerPanelIds;

  List<UyavaPanelId> get stackedPanels => <UyavaPanelId>[
    graphPanelId,
    ...detailPanelIds,
    ...footerPanelIds,
  ];
}

String panelPresetId(UyavaPanelLayoutPreset preset) {
  switch (preset) {
    case UyavaPanelLayoutPreset.stacked:
      return kUyavaPanelPresetStackedId;
    case UyavaPanelLayoutPreset.graphWithDetails:
      return kUyavaPanelPresetGraphDetailsId;
  }
}

UyavaPanelLayoutPreset panelPresetForId(String? id) {
  switch (id) {
    case kUyavaPanelPresetGraphDetailsId:
      return UyavaPanelLayoutPreset.graphWithDetails;
    case kUyavaPanelPresetStackedId:
      return UyavaPanelLayoutPreset.stacked;
    default:
      return UyavaPanelLayoutPreset.graphWithDetails;
  }
}

UyavaPanelShellSpec buildPanelPresetSpec({
  required UyavaPanelLayoutPreset preset,
  required UyavaPanelPresetContent content,
}) {
  switch (preset) {
    case UyavaPanelLayoutPreset.stacked:
      return UyavaPanelShellSpec(
        root: UyavaPanelSplit(
          key: 'stacked-content',
          axis: UyavaPanelSplitAxis.vertical,
          children: <UyavaPanelSlot>[
            for (final UyavaPanelId id in content.stackedPanels)
              UyavaPanelLeaf(id),
          ],
        ),
      );
    case UyavaPanelLayoutPreset.graphWithDetails:
      final UyavaPanelSlot detailsStack = _buildVerticalStack(
        'details-stack',
        content.detailPanelIds,
      );
      final UyavaPanelSlot footerStack = _buildVerticalStack(
        'footer-stack',
        content.footerPanelIds,
      );
      return UyavaPanelShellSpec(
        root: UyavaPanelSplit(
          key: 'graph-details-shell',
          axis: UyavaPanelSplitAxis.vertical,
          children: [
            UyavaPanelSplit(
              key: 'graph-details-main',
              axis: UyavaPanelSplitAxis.horizontal,
              children: [UyavaPanelLeaf(content.graphPanelId), detailsStack],
            ),
            footerStack,
          ],
        ),
      );
  }
}

UyavaPanelSlot _buildVerticalStack(String key, List<UyavaPanelId> ids) {
  if (ids.length == 1) {
    return UyavaPanelLeaf(ids.first);
  }
  return UyavaPanelSplit(
    key: key,
    axis: UyavaPanelSplitAxis.vertical,
    children: [for (final UyavaPanelId id in ids) UyavaPanelLeaf(id)],
  );
}
