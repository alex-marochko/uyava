part of 'package:uyava_example/main.dart';

const Map<UyavaStandardType, List<String>> _standardTypeTags = {
  UyavaStandardType.widget: ['ui', 'widget'],
  UyavaStandardType.screen: ['ui', 'screen'],
  UyavaStandardType.bloc: ['logic', 'bloc'],
  UyavaStandardType.provider: ['logic', 'provider'],
  UyavaStandardType.riverpod: ['logic', 'riverpod'],
  UyavaStandardType.state: ['logic', 'state'],
  UyavaStandardType.service: ['service', 'backend'],
  UyavaStandardType.repository: ['data', 'repository'],
  UyavaStandardType.usecase: ['domain', 'usecase'],
  UyavaStandardType.manager: ['domain', 'manager'],
  UyavaStandardType.database: ['data', 'database'],
  UyavaStandardType.api: ['integration', 'api'],
  UyavaStandardType.source: ['integration', 'source'],
  UyavaStandardType.model: ['data', 'model'],
  UyavaStandardType.stream: ['messaging', 'stream'],
  UyavaStandardType.queue: ['messaging', 'queue'],
  UyavaStandardType.event: ['messaging', 'event'],
  UyavaStandardType.group: ['group'],
  UyavaStandardType.sensor: ['device', 'sensor'],
  UyavaStandardType.ai: ['ai', 'ml'],
};

const Map<String, List<String>> _featureBaseTags = {
  'Authentication': ['auth'],
  'Restaurant Feed': ['restaurants', 'feed'],
  'Order & Checkout': ['orders', 'checkout'],
  'Profile & Settings': ['profile', 'settings'],
  'Real-time Tracking': ['tracking', 'realtime'],
  'Customer Support': ['support', 'chat'],
  'Infrastructure': ['infrastructure', 'platform'],
};

String _slugifyTag(String input) {
  final String lower = input.toLowerCase().trim();
  if (lower.isEmpty) return '';
  final String collapsed = lower.replaceAll(RegExp(r'[^a-z0-9]+'), '-');
  final String normalized = collapsed.replaceAll(RegExp(r'-+'), '-');
  return normalized.replaceAll(RegExp(r'^-|-$'), '');
}

List<String> _defaultTagsForFeatureNode({
  required String feature,
  required UyavaStandardType? standardType,
  String? label,
  List<String> extras = const [],
}) {
  final LinkedHashSet<String> tags = LinkedHashSet<String>();
  final String featureSlug = _slugifyTag(feature);
  if (featureSlug.isNotEmpty) {
    tags.add('feature-$featureSlug');
  }
  final List<String>? featureExtras = _featureBaseTags[feature];
  if (featureExtras != null) {
    for (final String extra in featureExtras) {
      final String slug = _slugifyTag(extra);
      if (slug.isNotEmpty) tags.add(slug);
    }
  }
  if (standardType != null) {
    final List<String>? base = _standardTypeTags[standardType];
    if (base != null) {
      tags.addAll(base);
    }
  }
  if (label != null && label.isNotEmpty) {
    final String labelSlug = _slugifyTag(label);
    if (labelSlug.isNotEmpty) {
      tags.add(labelSlug);
    }
  }
  for (final String extra in extras) {
    final String slug = _slugifyTag(extra);
    if (slug.isNotEmpty) tags.add(slug);
  }
  return tags.toList(growable: false);
}

Map<String, List<UyavaNode>> _decorateFeatureNodesWithTags(
  Map<String, List<UyavaNode>> features,
) {
  final Map<String, List<UyavaNode>> result = <String, List<UyavaNode>>{};
  features.forEach((String feature, List<UyavaNode> nodes) {
    result[feature] = [
      for (final UyavaNode node in nodes) _withDefaultTags(feature, node),
    ];
  });
  return result;
}

UyavaNode _withDefaultTags(String feature, UyavaNode node) {
  UyavaStandardType? standardType;
  for (final UyavaStandardType candidate in UyavaStandardType.values) {
    if (candidate.name == node.type) {
      standardType = candidate;
      break;
    }
  }
  final List<String> computedTags = _defaultTagsForFeatureNode(
    feature: feature,
    standardType: standardType,
    label: node.label ?? node.id,
  );
  if (computedTags.isEmpty && (node.tags == null || node.tags!.isEmpty)) {
    return node;
  }
  final LinkedHashSet<String> merged = LinkedHashSet<String>();
  if (node.tags != null) {
    merged.addAll(node.tags!);
  }
  merged.addAll(computedTags);
  return UyavaNode(
    id: node.id,
    type: node.type,
    label: node.label,
    description: node.description,
    parentId: node.parentId,
    tags: merged.toList(growable: false),
    color: node.color,
    shape: node.shape,
  );
}
