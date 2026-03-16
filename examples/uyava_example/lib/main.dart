import 'dart:async';
import 'dart:collection';
import 'dart:isolate';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uyava/uyava.dart';

import 'src/file_logging.dart';
import 'src/logging_widgets.dart';
import 'src/simulation_controller.dart';

part 'src/app/example_app.dart';
part 'src/app/features_graph.dart';
part 'src/app/features_tab.dart';
part 'src/app/metrics_logic.dart';
part 'src/app/metrics_tab.dart';
part 'src/app/event_chains_definitions.dart';
part 'src/app/event_chains_logic.dart';
part 'src/app/event_chains_tab.dart';
part 'src/app/courier_burst_tab.dart';
part 'src/app/targeted_events_tab.dart';
part 'src/app/wrong_data_logic.dart';
part 'src/app/wrong_data_tab.dart';
part 'src/app/data/tags.dart';
part 'src/app/data/nodes.dart';
part 'src/app/data/nodes_authentication.dart';
part 'src/app/data/nodes_restaurant_feed.dart';
part 'src/app/data/nodes_order_checkout.dart';
part 'src/app/data/nodes_profile_settings.dart';
part 'src/app/data/nodes_real_time_tracking.dart';
part 'src/app/data/nodes_customer_support.dart';
part 'src/app/data/edges.dart';

// --- Clean-architecture-friendly port + adapter (example) ---
/// App-side port for graph emission. Domain code depends on this interface,
/// not on the Uyava SDK directly.
abstract class GraphPort {
  void addNode(UyavaNode node);
}

/// Infrastructure adapter that delegates to the Uyava SDK.
class UyavaGraphAdapter implements GraphPort {
  @override
  void addNode(UyavaNode node) {
    // Pass a caller reference that skips this adapter frame, so navigation
    // points to the real call-site (e.g., use-case/UI handler).
    final ref = Uyava.caller(skip: 1);
    Uyava.addNode(node, sourceRef: ref);
  }
}

class _AdhocEdge {
  const _AdhocEdge({required this.id, required this.from, required this.to});

  final String id;
  final String from;
  final String to;
}

class _RegisteredMetric {
  _RegisteredMetric({
    required this.id,
    this.label,
    this.description,
    this.unit,
    required this.aggregators,
    required this.tags,
  });

  final String id;
  final String? label;
  final String? description;
  final String? unit;
  final List<UyavaMetricAggregator> aggregators;
  final List<String> tags;
}

class _MetricTemplate {
  const _MetricTemplate({
    required this.id,
    required this.label,
    this.description,
    this.unit,
    required this.aggregators,
    required this.tags,
    required this.sample,
  });

  final String id;
  final String label;
  final String? description;
  final String? unit;
  final List<UyavaMetricAggregator> aggregators;
  final List<String> tags;
  final double Function(math.Random rng) sample;
}

class _ChainStepTemplate {
  const _ChainStepTemplate({
    required this.stepId,
    required this.nodeId,
    this.edgeId,
    this.message,
    this.severity = UyavaSeverity.info,
  });

  final String stepId;
  final String nodeId;
  final String? edgeId;
  final String? message;
  final UyavaSeverity severity;
}

class _PredefinedChain {
  const _PredefinedChain({
    required this.id,
    required this.tags,
    required this.steps,
    required this.label,
    this.description,
    this.successSimulation,
    this.failureSimulation,
  });

  final String id;
  final List<String> tags;
  final List<UyavaEventChainStep> steps;
  final String label;
  final String? description;
  final List<_ChainStepTemplate>? successSimulation;
  final List<_ChainStepTemplate>? failureSimulation;
}

enum _TargetType { node, edge }

enum _Lifecycle { unknown, initialized, disposed }

Future<void> main() async {
  Uyava.initialize();
  Uyava.enableConsoleLogging(
    config: UyavaConsoleLoggerConfig(
      minLevel: UyavaSeverity.info,
      colorMode: UyavaConsoleColorMode.always,
    ),
  );

  final UyavaFileTransport? transport = await configureFileLogging();
  if (transport != null) {
    final UyavaGlobalErrorHandle handle =
        UyavaBootstrap.installGlobalErrorHandlers(
          transport: transport,
          options: const UyavaGlobalErrorOptions(
            delegateOriginalHandlers: false,
            propagateToZone: false,
          ),
        );
    registerGlobalErrorHandle(handle);

    await UyavaBootstrap.runZoned<void>(
      () async {
        WidgetsFlutterBinding.ensureInitialized();
        initializeFileLoggingLifecycle(transport);
        _seedInitialGraph();
        runApp(const ExampleApp());
      },
      transport: transport,
      options: const UyavaGlobalErrorOptions(
        delegateOriginalHandlers: false,
        propagateToZone: false,
      ),
    );
    return;
  }

  WidgetsFlutterBinding.ensureInitialized();
  _seedInitialGraph();
  runApp(const ExampleApp());
}

void _seedInitialGraph() {
  // Pre-populate the graph state immediately after initialization. This keeps
  // DevTools/desktop hosts in sync on cold start before they request the
  // initial graph payload.
  final List<UyavaNode> initialNodes = <UyavaNode>[];
  final Map<String, List<UyavaNode>> featureNodes = generateFeatureNodes();
  featureNodes.forEach((_, List<UyavaNode> nodes) {
    initialNodes.addAll(nodes);
  });
  Uyava.replaceGraph(nodes: initialNodes, edges: generateAllEdges());
}
