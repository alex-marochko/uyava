/// Configuration for force-directed layout parameters.
class LayoutConfig {
  // Viewport padding to keep nodes away from edges.
  final double padding;

  // Simulation parameters.
  final double alphaDecay; // how fast alpha cools towards alphaMin
  final double alphaMin; // threshold to consider converged
  final double velocityDecay; // friction

  // Force strengths and distances.
  final double manyBodyStrength; // negative to repel
  final double linkDistance;
  final double linkStrength;
  final double collisionRadius; // visual node radius approximation
  final double gravityLinkDistance; // parent-child desired distance
  final double gravityLinkStrength; // softness of parent-child link

  // Group-aware multipliers (>= 0). Defaults keep prior behavior.
  // When nodes belong to the same immediate parent group (non-null parentId):
  //  - linkStrength is multiplied by sameGroupLinkStrengthFactor
  //  - linkDistance is multiplied by sameGroupLinkDistanceFactor
  // For nodes in different immediate groups (or one/top-level null):
  //  - linkStrength is multiplied by interGroupLinkStrengthFactor
  //  - linkDistance is multiplied by interGroupLinkDistanceFactor
  // Many-body repulsion between nodes in different immediate groups is
  // multiplied by interGroupRepulsionFactor (same-group stays baseline).
  final double sameGroupLinkStrengthFactor;
  final double sameGroupLinkDistanceFactor;
  final double interGroupLinkStrengthFactor;
  final double interGroupLinkDistanceFactor;
  final double interGroupRepulsionFactor;

  // Optional group anchors to encourage cluster separation.
  final bool enableGroupAnchors;
  final double anchorLinkDistance;
  final double anchorLinkStrength;
  final double anchorRepulsionFactor;
  final double anchorSmoothing;
  // Optional: soften mixing for very chatty root pairs
  // by normalizing inter-root link strength by count^power.
  // 0.0 disables normalization. 0.5 means divide by sqrt(count).
  final double interRootLinkNormalizationPower;
  // Optional: soft collision for anchors using an approximate group radius.
  // Radius ≈ collisionRadius * anchorCollisionScale * sqrt(groupSize).
  // Strength 0 disables; higher values push overlapping groups apart more.
  final double anchorCollisionStrength;
  final double anchorCollisionScale;

  // Optional hierarchical subtree separation.
  // For every parent, sibling child-subtrees are pushed apart as clusters.
  // This helps keep branches separated across all hierarchy levels.
  // Strength 0 disables this force.
  final double subtreeSeparationStrength;
  final double subtreeSeparationScale;
  final double subtreeSeparationGap;

  const LayoutConfig({
    this.padding = 50.0,
    this.alphaDecay = 0.025,
    this.alphaMin = 0.001,
    this.velocityDecay = 0.45,
    this.manyBodyStrength = -30.0,
    this.linkDistance = 98.0,
    this.linkStrength = 1.0,
    this.collisionRadius = 54.0,
    this.gravityLinkDistance = 0.70,
    this.gravityLinkStrength = 1.25,
    this.sameGroupLinkStrengthFactor = 1.25,
    this.sameGroupLinkDistanceFactor = 0.82,
    this.interGroupLinkStrengthFactor = 1.25,
    this.interGroupLinkDistanceFactor = 2.00,
    this.interGroupRepulsionFactor = 2.00,
    this.enableGroupAnchors = true,
    this.anchorLinkDistance = 96.0,
    this.anchorLinkStrength = 0.64,
    this.anchorRepulsionFactor = 4.5,
    this.anchorSmoothing = 0.89,
    this.interRootLinkNormalizationPower = 0.85,
    this.anchorCollisionStrength = 1.15,
    this.anchorCollisionScale = 1.40,
    this.subtreeSeparationStrength = 0.0,
    this.subtreeSeparationScale = 1.40,
    this.subtreeSeparationGap = 34.0,
  });

  LayoutConfig copyWith({
    double? padding,
    double? alphaDecay,
    double? alphaMin,
    double? velocityDecay,
    double? manyBodyStrength,
    double? linkDistance,
    double? linkStrength,
    double? collisionRadius,
    double? gravityLinkDistance,
    double? gravityLinkStrength,
    double? sameGroupLinkStrengthFactor,
    double? sameGroupLinkDistanceFactor,
    double? interGroupLinkStrengthFactor,
    double? interGroupLinkDistanceFactor,
    double? interGroupRepulsionFactor,
    bool? enableGroupAnchors,
    double? anchorLinkDistance,
    double? anchorLinkStrength,
    double? anchorRepulsionFactor,
    double? anchorSmoothing,
    double? interRootLinkNormalizationPower,
    double? anchorCollisionStrength,
    double? anchorCollisionScale,
    double? subtreeSeparationStrength,
    double? subtreeSeparationScale,
    double? subtreeSeparationGap,
  }) {
    return LayoutConfig(
      padding: padding ?? this.padding,
      alphaDecay: alphaDecay ?? this.alphaDecay,
      alphaMin: alphaMin ?? this.alphaMin,
      velocityDecay: velocityDecay ?? this.velocityDecay,
      manyBodyStrength: manyBodyStrength ?? this.manyBodyStrength,
      linkDistance: linkDistance ?? this.linkDistance,
      linkStrength: linkStrength ?? this.linkStrength,
      collisionRadius: collisionRadius ?? this.collisionRadius,
      gravityLinkDistance: gravityLinkDistance ?? this.gravityLinkDistance,
      gravityLinkStrength: gravityLinkStrength ?? this.gravityLinkStrength,
      sameGroupLinkStrengthFactor:
          sameGroupLinkStrengthFactor ?? this.sameGroupLinkStrengthFactor,
      sameGroupLinkDistanceFactor:
          sameGroupLinkDistanceFactor ?? this.sameGroupLinkDistanceFactor,
      interGroupLinkStrengthFactor:
          interGroupLinkStrengthFactor ?? this.interGroupLinkStrengthFactor,
      interGroupLinkDistanceFactor:
          interGroupLinkDistanceFactor ?? this.interGroupLinkDistanceFactor,
      interGroupRepulsionFactor:
          interGroupRepulsionFactor ?? this.interGroupRepulsionFactor,
      enableGroupAnchors: enableGroupAnchors ?? this.enableGroupAnchors,
      anchorLinkDistance: anchorLinkDistance ?? this.anchorLinkDistance,
      anchorLinkStrength: anchorLinkStrength ?? this.anchorLinkStrength,
      anchorRepulsionFactor:
          anchorRepulsionFactor ?? this.anchorRepulsionFactor,
      anchorSmoothing: anchorSmoothing ?? this.anchorSmoothing,
      interRootLinkNormalizationPower:
          interRootLinkNormalizationPower ??
          this.interRootLinkNormalizationPower,
      anchorCollisionStrength:
          anchorCollisionStrength ?? this.anchorCollisionStrength,
      anchorCollisionScale: anchorCollisionScale ?? this.anchorCollisionScale,
      subtreeSeparationStrength:
          subtreeSeparationStrength ?? this.subtreeSeparationStrength,
      subtreeSeparationScale:
          subtreeSeparationScale ?? this.subtreeSeparationScale,
      subtreeSeparationGap: subtreeSeparationGap ?? this.subtreeSeparationGap,
    );
  }
}
