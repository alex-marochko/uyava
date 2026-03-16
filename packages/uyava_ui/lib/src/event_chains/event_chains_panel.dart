import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:uyava_core/uyava_core.dart';
import 'package:uyava_protocol/uyava_protocol.dart';

import 'event_chains_view_model.dart';

part 'event_chain_tile_controller.dart';
part 'event_chain_tile_sections.dart';
part 'event_chain_tile.dart';

/// Lightweight panel that surfaces event-chain summaries alongside
/// a detail view for the currently selected chain.
class UyavaEventChainsPanel extends StatefulWidget {
  const UyavaEventChainsPanel({
    super.key,
    required this.controller,
    this.applyFilters = true,
    this.padding = const EdgeInsets.all(12),
    this.onSelectionChanged,
    this.onAttemptChanged,
    this.initialChainId,
    this.initialAttemptKey,
    this.pinnedChains = const <String>{},
    this.onPinnedChainsChanged,
  });

  /// Graph controller supplying chain definitions and progress snapshots.
  final GraphController controller;

  /// Whether to render filtered chains (respecting the global filter state).
  final bool applyFilters;

  /// Panel padding applied around the composed layout.
  final EdgeInsetsGeometry padding;

  /// Optional callback invoked when the selected chain changes.
  final ValueChanged<String?>? onSelectionChanged;

  /// Optional callback invoked when the selected attempt changes.
  final ValueChanged<String?>? onAttemptChanged;

  /// Preferred chain id to select on first build.
  final String? initialChainId;

  /// Preferred attempt key to select on first build.
  final String? initialAttemptKey;

  /// Chains that should render at the top in pinned state.
  final Set<String> pinnedChains;

  /// Called whenever the pinned chain set changes.
  final ValueChanged<Set<String>>? onPinnedChainsChanged;

  @override
  State<UyavaEventChainsPanel> createState() => _UyavaEventChainsPanelState();
}

class _UyavaEventChainsPanelState extends State<UyavaEventChainsPanel> {
  late EventChainsViewModel _viewModel;
  Set<String> _lastPinned = const <String>{};
  String? _lastSelectedChain;
  String? _lastSelectedAttempt;

  @override
  void initState() {
    super.initState();
    _viewModel = _createViewModel();
    _scheduleInitialCallbacksIfNeeded();
    _snapshotEmissionState();
    _viewModel.addListener(_handleViewModelChanged);
  }

  EventChainsViewModel _createViewModel() {
    return EventChainsViewModel(
      controller: widget.controller,
      applyFilters: widget.applyFilters,
      initialChainId: widget.initialChainId,
      initialAttemptKey: widget.initialAttemptKey,
      pinnedChains: widget.pinnedChains,
    );
  }

  void _scheduleInitialCallbacksIfNeeded() {
    final String? desiredChain = widget.initialChainId;
    final String? desiredAttempt = widget.initialAttemptKey;
    final String? actualChain = _viewModel.selectedChainId;
    final String? actualAttempt = _viewModel.selectedAttemptKey;
    final bool chainChanged =
        desiredChain != null && desiredChain != actualChain;
    final bool attemptChanged =
        desiredAttempt != null && desiredAttempt != actualAttempt;
    if (!chainChanged && !attemptChanged) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (chainChanged) {
        widget.onSelectionChanged?.call(actualChain);
      }
      if (attemptChanged) {
        widget.onAttemptChanged?.call(actualAttempt);
      }
    });
  }

  void _snapshotEmissionState() {
    _lastPinned = _viewModel.pinnedChainIds;
    _lastSelectedChain = _viewModel.selectedChainId;
    _lastSelectedAttempt = _viewModel.selectedAttemptKey;
  }

  @override
  void didUpdateWidget(covariant UyavaEventChainsPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(widget.controller, oldWidget.controller)) {
      _replaceViewModel();
    } else {
      if (widget.applyFilters != oldWidget.applyFilters) {
        _viewModel.setApplyFilters(widget.applyFilters);
      }
      if (widget.initialChainId != oldWidget.initialChainId ||
          widget.initialAttemptKey != oldWidget.initialAttemptKey) {
        _viewModel.setSelectionFromHost(
          widget.initialChainId,
          widget.initialAttemptKey,
        );
      }
      if (!setEquals(widget.pinnedChains, oldWidget.pinnedChains)) {
        _viewModel.setPinnedChains(widget.pinnedChains);
      }
    }
  }

  void _replaceViewModel() {
    _viewModel.removeListener(_handleViewModelChanged);
    _viewModel.dispose();
    _viewModel = _createViewModel();
    _snapshotEmissionState();
    _viewModel.addListener(_handleViewModelChanged);
    setState(() {});
  }

  @override
  void dispose() {
    _viewModel.removeListener(_handleViewModelChanged);
    _viewModel.dispose();
    super.dispose();
  }

  void _handleViewModelChanged() {
    final Set<String> pins = _viewModel.pinnedChainIds;
    if (!setEquals(_lastPinned, pins)) {
      _lastPinned = Set<String>.of(pins);
      widget.onPinnedChainsChanged?.call(_lastPinned);
    }
    if (_viewModel.selectedChainId != _lastSelectedChain) {
      _lastSelectedChain = _viewModel.selectedChainId;
      widget.onSelectionChanged?.call(_lastSelectedChain);
    }
    if (_viewModel.selectedAttemptKey != _lastSelectedAttempt) {
      _lastSelectedAttempt = _viewModel.selectedAttemptKey;
      widget.onAttemptChanged?.call(_lastSelectedAttempt);
    }
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_viewModel.hasChains) {
      return Padding(
        padding: widget.padding,
        child: _EmptyState(theme: Theme.of(context)),
      );
    }

    return Padding(
      padding: widget.padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ChainsHeader(
            canReset: _viewModel.canResetAll,
            onResetAll: _viewModel.resetAllChains,
          ),
          const SizedBox(height: 6),
          Expanded(
            child: _ChainList(
              chains: _viewModel.chainViews,
              onChainTap: _viewModel.toggleChainSelection,
              onAttemptSelected: _viewModel.selectAttempt,
              onReset: _viewModel.resetChain,
              onPinToggle: _viewModel.togglePin,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChainsHeader extends StatelessWidget {
  const _ChainsHeader({required this.canReset, required this.onResetAll});

  final bool canReset;
  final VoidCallback onResetAll;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ButtonStyle actionStyle = TextButton.styleFrom(
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      minimumSize: const Size(0, 28),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      textStyle: theme.textTheme.labelSmall,
    );
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton.icon(
        onPressed: canReset ? onResetAll : null,
        style: actionStyle,
        icon: const Icon(Icons.refresh, size: 16),
        label: const Text('Reset all'),
      ),
    );
  }
}
