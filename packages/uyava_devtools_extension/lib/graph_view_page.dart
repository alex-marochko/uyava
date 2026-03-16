import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:uyava_core/uyava_core.dart';
import 'package:uyava_protocol/uyava_protocol.dart';
import 'package:uyava_ui/uyava_ui.dart';
import 'package:vm_service/vm_service.dart' show Event;

import 'graph_toolbar.dart';
import 'vm_event_bridge.dart';
import 'src/context_menu_suppression.dart';
import 'src/devtools_extension_stub.dart'
    if (dart.library.js_interop) 'package:devtools_extensions/devtools_extensions.dart';
import 'src/panel_shell/devtools_panel_shell_adapter.dart';
import 'src/panel_shell/devtools_split_panel_shell.dart';
import 'src/panel_storage_stub.dart'
    if (dart.library.html) 'src/panel_storage_web.dart';
import 'src/viewport_persistence_adapter.dart';
import 'src/version.g.dart';

part 'src/graph_view/devtools_graph_view_coordinator_core.dart';
part 'src/graph_view/filter_and_panel_state_mixin.dart';
part 'src/graph_view/viewport_state_mixin.dart';
part 'src/graph_view/journal_and_diagnostics_mixin.dart';
part 'src/graph_view/devtools_graph_persistence.dart';
part 'src/graph_view/devtools_graph_hover_controller.dart';
part 'src/graph_view/devtools_graph_view_coordinator.dart';
part 'src/graph_view/diagnostics_banner.dart';
part 'src/graph_view/graph_view_scaffold.dart';
part 'src/graph_view/graph_view_viewport_pane.dart';
part 'src/graph_view/graph_view_viewport_logic.dart';
part 'src/graph_view/hover_overlay.dart';

enum _GraphContextMenuAction { addFocus, removeFocus }

class GraphViewPage extends StatefulWidget {
  const GraphViewPage({
    super.key,
    this.viewportStorage,
    this.panelLayoutStorage,
  });

  final ViewportPersistenceAdapter? viewportStorage;
  final UyavaPanelLayoutStorage? panelLayoutStorage;

  @override
  State<GraphViewPage> createState() => _GraphViewPageState();
}

class _GraphViewPageState extends _DevToolsGraphViewCoordinator {}

@visibleForTesting
void setGraphViewAnimationsEnabled(bool enabled) {
  _devtoolsGraphViewAnimationsDisabledForTesting = !enabled;
}

UyavaSeverity? _parseSeverity(Object? raw) {
  if (raw is UyavaSeverity) {
    return raw;
  }
  if (raw is String && raw.isNotEmpty) {
    for (final UyavaSeverity candidate in UyavaSeverity.values) {
      if (candidate.name == raw) {
        return candidate;
      }
    }
  }
  return null;
}

int _severityRank(UyavaSeverity? s) {
  return s?.index ?? UyavaSeverity.info.index;
}
