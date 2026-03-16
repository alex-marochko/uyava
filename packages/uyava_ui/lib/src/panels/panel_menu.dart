import 'package:flutter/material.dart';

import 'panel_contract.dart';

class UyavaPanelMenuToggle {
  const UyavaPanelMenuToggle({
    required this.label,
    required this.isChecked,
    required this.onToggle,
    this.id,
  });

  final UyavaPanelId? id;
  final String label;
  final ValueGetter<bool> isChecked;
  final VoidCallback onToggle;
}

class UyavaPanelMenuAction {
  const UyavaPanelMenuAction({
    required this.label,
    required this.onSelected,
    this.isChecked,
  });

  final String label;
  final VoidCallback onSelected;
  final ValueGetter<bool>? isChecked;
}

class UyavaPanelMenuController {
  UyavaPanelMenuController({
    required ValueGetter<bool> isStackedLayout,
    required VoidCallback onSelectStacked,
    required VoidCallback onSelectGraphWithDetails,
    required ValueGetter<bool> filtersVisible,
    required ValueSetter<bool> onFiltersVisibilityChanged,
    List<UyavaPanelMenuToggle> panelToggles = const [],
    List<UyavaPanelMenuAction> extraActions = const [],
    this.filtersLabel = 'Filters bar',
    this.graphWithDetailsLabel = 'Layout · Graph with details',
    this.stackedLayoutLabel = 'Layout · Vertical stack',
  }) : _isStackedLayout = isStackedLayout,
       _onSelectStacked = onSelectStacked,
       _onSelectGraphWithDetails = onSelectGraphWithDetails,
       _filtersVisible = filtersVisible,
       _onFiltersVisibilityChanged = onFiltersVisibilityChanged,
       _panelToggles = panelToggles,
       _extraActions = extraActions;

  final ValueGetter<bool> _isStackedLayout;
  final VoidCallback _onSelectStacked;
  final VoidCallback _onSelectGraphWithDetails;
  final ValueGetter<bool> _filtersVisible;
  final ValueSetter<bool> _onFiltersVisibilityChanged;
  final List<UyavaPanelMenuToggle> _panelToggles;
  final List<UyavaPanelMenuAction> _extraActions;

  final String filtersLabel;
  final String graphWithDetailsLabel;
  final String stackedLayoutLabel;

  Widget buildMenu() {
    final List<UyavaPanelMenuToggle> toggles = <UyavaPanelMenuToggle>[
      UyavaPanelMenuToggle(
        label: filtersLabel,
        isChecked: _filtersVisible,
        onToggle: () => _onFiltersVisibilityChanged(!_filtersVisible()),
      ),
      ..._panelToggles,
    ];
    return UyavaPanelMenu(
      isStackedLayout: _isStackedLayout(),
      onLayoutStacked: _onSelectStacked,
      onLayoutGraphWithDetails: _onSelectGraphWithDetails,
      toggles: toggles,
      extraActions: _extraActions,
      graphWithDetailsLabel: graphWithDetailsLabel,
      stackedLayoutLabel: stackedLayoutLabel,
    );
  }
}

class UyavaPanelMenu extends StatelessWidget {
  const UyavaPanelMenu({
    super.key,
    required this.isStackedLayout,
    required this.onLayoutStacked,
    required this.onLayoutGraphWithDetails,
    required this.toggles,
    this.extraActions = const [],
    this.icon = const Icon(Icons.view_sidebar_outlined),
    this.graphWithDetailsLabel = 'Layout · Graph with details',
    this.stackedLayoutLabel = 'Layout · Vertical stack',
  });

  final bool isStackedLayout;
  final VoidCallback onLayoutStacked;
  final VoidCallback onLayoutGraphWithDetails;
  final List<UyavaPanelMenuToggle> toggles;
  final List<UyavaPanelMenuAction> extraActions;
  final Widget icon;
  final String graphWithDetailsLabel;
  final String stackedLayoutLabel;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_PanelMenuAction>(
      tooltip: 'Configure panels',
      icon: icon,
      onSelected: (action) {
        if (action is _PanelMenuLayoutAction) {
          if (action.target == _PanelMenuLayoutTarget.stacked) {
            onLayoutStacked();
          } else {
            onLayoutGraphWithDetails();
          }
        } else if (action is _PanelMenuToggleAction) {
          action.toggle.onToggle();
        } else if (action is _PanelMenuCustomAction) {
          action.action.onSelected();
        }
      },
      itemBuilder: (context) => <PopupMenuEntry<_PanelMenuAction>>[
        CheckedPopupMenuItem<_PanelMenuAction>(
          value: const _PanelMenuLayoutAction(
            _PanelMenuLayoutTarget.graphWithDetails,
          ),
          checked: !isStackedLayout,
          child: Text(graphWithDetailsLabel),
        ),
        CheckedPopupMenuItem<_PanelMenuAction>(
          value: const _PanelMenuLayoutAction(_PanelMenuLayoutTarget.stacked),
          checked: isStackedLayout,
          child: Text(stackedLayoutLabel),
        ),
        if (toggles.isNotEmpty) const PopupMenuDivider(),
        for (final UyavaPanelMenuToggle toggle in toggles)
          CheckedPopupMenuItem<_PanelMenuAction>(
            value: _PanelMenuToggleAction(toggle),
            checked: toggle.isChecked(),
            child: Text(toggle.label),
          ),
        if (extraActions.isNotEmpty) const PopupMenuDivider(),
        for (final UyavaPanelMenuAction action in extraActions)
          action.isChecked != null
              ? CheckedPopupMenuItem<_PanelMenuAction>(
                  value: _PanelMenuCustomAction(action),
                  checked: action.isChecked!(),
                  child: Text(action.label),
                )
              : PopupMenuItem<_PanelMenuAction>(
                  value: _PanelMenuCustomAction(action),
                  child: Text(action.label),
                ),
      ],
    );
  }
}

sealed class _PanelMenuAction {
  const _PanelMenuAction();
}

enum _PanelMenuLayoutTarget { stacked, graphWithDetails }

class _PanelMenuLayoutAction extends _PanelMenuAction {
  const _PanelMenuLayoutAction(this.target);

  final _PanelMenuLayoutTarget target;
}

class _PanelMenuToggleAction extends _PanelMenuAction {
  const _PanelMenuToggleAction(this.toggle);

  final UyavaPanelMenuToggle toggle;
}

class _PanelMenuCustomAction extends _PanelMenuAction {
  const _PanelMenuCustomAction(this.action);

  final UyavaPanelMenuAction action;
}
