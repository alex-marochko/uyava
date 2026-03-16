import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:uyava_core/uyava_core.dart';

import 'adapters.dart';

UyavaSeverity? _normalizeSeverity(String? value) {
  if (value == null) return null;
  try {
    return UyavaSeverity.values.byName(value);
  } on ArgumentError {
    return null;
  }
}

UyavaSeverity? _decodeSeverity(Object? raw) {
  if (raw is UyavaSeverity) return raw;
  if (raw is String) {
    return _normalizeSeverity(raw);
  }
  return null;
}

DateTime? _decodeTimestamp(Object? raw) {
  if (raw is DateTime) {
    return raw.isUtc ? raw : raw.toUtc();
  }
  if (raw is String && raw.isNotEmpty) {
    try {
      return DateTime.parse(raw).toUtc();
    } catch (_) {
      return null;
    }
  }
  return null;
}

String? _decodeMessage(Object? raw) {
  if (raw is String && raw.trim().isNotEmpty) {
    return raw;
  }
  return null;
}

String? _decodeSourceMeta(Object? raw) {
  if (raw is! String) return null;
  final String trimmed = raw.trim();
  if (trimmed.isEmpty) return null;
  return trimmed;
}

int? _parseIsolateNumber(Object? raw) {
  if (raw is int) return raw;
  if (raw is num) return raw.toInt();
  if (raw is String && raw.isNotEmpty) {
    return int.tryParse(raw);
  }
  return null;
}

/// Parses an edge event payload (type 'edgeEvent' or legacy 'animation')
/// and resolves it to a concrete UyavaEvent with from/to node ids. Supports either
/// explicit {from,to} or {edge} with lookup in the controller's edges.
UyavaEvent? parseAnimationEvent(
  Map<dynamic, dynamic> payload,
  GraphController controller,
) {
  String? from;
  String? to;
  final String? message = _decodeMessage(payload['message']);
  if (message == null) {
    debugPrint('[Uyava UI] Ignoring edge event without message.');
    return null;
  }
  final UyavaSeverity? severity = _normalizeSeverity(
    payload['severity'] as String?,
  );
  final String? sourceRef = payload['sourceRef'] as String?;
  final String? sourceId = _decodeSourceMeta(payload['sourceId']);
  final String? sourceType = _decodeSourceMeta(payload['sourceType']);
  final DateTime timestamp =
      _decodeTimestamp(payload['timestamp'])?.toLocal() ?? DateTime.now();
  final String? isolateId = payload['isolateId'] as String?;
  final String? isolateName = payload['isolateName'] as String?;
  final int? isolateNumber = _parseIsolateNumber(payload['isolateNumber']);

  if (payload.containsKey('from') && payload.containsKey('to')) {
    from = payload['from'] as String?;
    to = payload['to'] as String?;
  } else if (payload.containsKey('edge')) {
    final edgeId = payload['edge'] as String?;
    final edge = controller.edges.firstWhereOrNull((e) => e.id == edgeId);
    if (edge != null) {
      from = edge.source;
      to = edge.target;
    }
  }

  if (from != null && to != null) {
    return UyavaEvent(
      from: from,
      to: to,
      message: message,
      timestamp: timestamp,
      severity: severity,
      sourceRef: sourceRef,
      sourceId: sourceId,
      sourceType: sourceType,
      isolateId: isolateId,
      isolateName: isolateName,
      isolateNumber: isolateNumber,
    );
  }
  return null;
}

/// Parses a node event payload to a UyavaNodeEvent.
/// Expected minimal payload: { nodeId, severity?, tags? }
UyavaNodeEvent? parseNodeEvent(Map<dynamic, dynamic> payload) {
  final nodeId = payload['nodeId'] as String?;
  if (nodeId == null) return null;
  final String message = _decodeMessage(payload['message']) ?? 'node event';
  final UyavaSeverity? severity = _normalizeSeverity(
    payload['severity'] as String?,
  );
  final tags = (payload['tags'] as List?)?.whereType<String>().toList();
  final sourceRef = payload['sourceRef'] as String?;
  final String? sourceId = _decodeSourceMeta(payload['sourceId']);
  final String? sourceType = _decodeSourceMeta(payload['sourceType']);
  final DateTime timestamp =
      _decodeTimestamp(payload['timestamp'])?.toLocal() ?? DateTime.now();
  final String? isolateId = payload['isolateId'] as String?;
  final String? isolateName = payload['isolateName'] as String?;
  final int? isolateNumber = _parseIsolateNumber(payload['isolateNumber']);
  return UyavaNodeEvent(
    nodeId: nodeId,
    message: message,
    severity: severity,
    tags: tags,
    timestamp: timestamp,
    sourceRef: sourceRef,
    sourceId: sourceId,
    sourceType: sourceType,
    isolateId: isolateId,
    isolateName: isolateName,
    isolateNumber: isolateNumber,
  );
}

/// Applies a node lifecycle payload: { nodeId: String, state: 'initialized'|'disposed'|'unknown' }
///
/// Returns the normalized [NodeLifecycle] when both the node id and state are
/// valid; otherwise returns null and no update is performed.
NodeLifecycle? applyNodeLifecycle(
  GraphController controller,
  Map<dynamic, dynamic> payload,
) {
  final id = payload['nodeId'] as String?;
  final stateStr = payload['state'] as String?;
  if (id == null || stateStr == null) return null;
  NodeLifecycle? state;
  switch (stateStr) {
    case 'initialized':
      state = NodeLifecycle.initialized;
      break;
    case 'disposed':
      state = NodeLifecycle.disposed;
      break;
    case 'unknown':
      state = NodeLifecycle.unknown;
      break;
  }
  if (state != null) {
    controller.updateNodeLifecycle(id, state);
  }
  return state;
}

/// Applies a 'replaceGraph' payload to the provided controller with the given
/// viewport size. Keeps this logic consistent across hosts.
void applyReplaceGraph(
  GraphController controller,
  Map<dynamic, dynamic> payload,
  Size viewportSize,
) {
  controller.replaceGraph(
    payload.cast<String, dynamic>(),
    toSize2D(viewportSize),
  );
}

/// Records event-chain progress if the given node event payload embeds a chain snapshot.
///
/// Expected structure:
/// ```
/// {
///   'nodeId': '...',
///   'severity': 'info',
///   'timestamp': '2024-01-01T00:00:00Z',
///   'payload': {
///     'chain': {'id': 'chain', 'step': 'start', 'attempt': '123'},
///     'edgeId': 'optional-edge'
///   }
/// }
/// ```
GraphEventChainProgressResult? recordEventChainProgressFromNodeEvent(
  GraphController controller,
  Map<String, dynamic> nodeEvent,
) {
  final Object? rawInner = nodeEvent['payload'];
  if (rawInner is! Map) return null;
  final Object? chainRaw = rawInner['chain'];
  if (chainRaw is! Map) return null;

  final String? nodeId = nodeEvent['nodeId'] as String?;
  if (nodeId == null || nodeId.isEmpty) return null;

  final Map<String, dynamic> chain = Map<String, dynamic>.from(
    chainRaw.cast<String, dynamic>(),
  );
  final Object? rawStatus = rawInner['status'];
  if (rawStatus is String && rawStatus.trim().isNotEmpty) {
    chain.putIfAbsent('status', () => rawStatus.trim());
  }
  final String? edgeId = rawInner['edgeId'] as String?;
  final UyavaSeverity? severity = _decodeSeverity(nodeEvent['severity']);
  final DateTime? timestamp = _decodeTimestamp(nodeEvent['timestamp']);

  return controller.recordEventChainProgress(
    nodeId: nodeId,
    chain: chain,
    edgeId: edgeId,
    severity: severity,
    timestamp: timestamp,
  );
}
