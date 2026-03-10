import 'package:flutter/animation.dart';
import 'package:uyava_protocol/uyava_protocol.dart';

/// Configuration for DevTools/desktop rendering and transition thresholds.
class RenderConfig {
  // Node appearance
  final double parentNodeRadius;
  final double childNodeRadius;
  final double nodeFadeFactor; // fraction of alpha reduction at t=1
  final double nodeRadiusShrinkFactor; // fraction of radius reduction at t=1
  // Lifecycle dimming (multipliers for final node alpha)
  final double uninitializedAlphaMultiplier; // applied to NodeLifecycle.unknown
  final double disposedAlphaMultiplier; // applied to NodeLifecycle.disposed

  // Edge appearance
  final double edgeStrokeAlpha; // 0..1 multiplier for edge color alpha
  // Edge direction indicators
  final bool edgeArrowsEnabled; // draw small source-side arrowheads
  final double edgeArrowBaseWidth; // width of triangle base in px
  final double edgeArrowLength; // length from base center to tip in px

  // Events
  final Duration eventDuration;
  final double eventDotRadius;
  // Severity emphasis (optional highlight for warn/error/fatal)
  final bool severityEmphasisEnabled; // enable emphasis for severe events
  // Minimum level to emphasize.
  final UyavaSeverity severityEmphasisMinLevel;
  // Light preset multipliers
  final double severityNodePulseScale; // multiply node pulse scale
  final double severityEdgeDotScale; // multiply edge dot radius
  // Edge event queue badge
  final double queueLabelRadius; // px radius of queue badge circle
  final double queueLabelOffset; // px offset beyond arrow tip along edge
  final int queueLabelMinCountToShow; // show badge when count >= this
  final int queueLabelMaxCount; // cap displayed number, show like `9+`
  final Duration queueLabelFadeIn;
  final Duration queueLabelFadeOut;
  // Badge tinting
  final bool badgeTintBySeverity; // color badges by max severity in window
  // Node event badge (count of node pulses within window)
  final bool nodeEventBadgeEnabled; // draw node-level event count badge
  final bool
  nodeEventBadgeLeftSide; // place on left side (mirror of parent badge)
  // Node pulse (node events)
  final double nodePulseMaxScale; // radius multiplier at peak
  final double nodePulseAlpha; // max alpha of the halo
  final double nodePulseStrokeWidth; // halo stroke width in px
  // Flash overlay at pulse start
  final bool nodeFlashEnabled;
  final Duration nodeFlashDuration; // short high-contrast flash window
  final double nodeFlashAlpha; // flash alpha multiplier (0..1)
  final double nodeFlashScaleBoost; // additional scale during flash (e.g. 0.1)
  final bool nodeFlashAdditive; // use additive blend for flash
  // Contrast-aware flash (optional)
  final bool nodeFlashContrastAware; // adapt flash for low-contrast node colors
  final double nodeFlashMinContrast; // WCAG-like ratio to trigger adaptation
  // When contrast-aware triggers, optionally draw an inverted-color flash
  // relative to the node's base color instead of white+difference.
  final bool nodeFlashInvertColor;

  // Policies and thresholds
  final Curve ease; // default ease curve for policies
  final double cloudFadeWindow; // tail window for cloud fade-in (0..1)
  final double edgeRemapThreshold; // eased progress threshold for remap
  final double expandRevealWindow; // child reveal tail window (0..1)

  // Edge stabilization (warm-up) gating
  final bool hideEdgesDuringWarmup; // gate edges until layout stabilizes
  final double edgeStableSpeedThreshold; // px/sec threshold (EMA)
  final double edgeUnstableHysteresisMultiplier; // >1 to avoid flapping
  final double edgeStabilityEmaFactor; // 0..1 smoothing factor
  final Duration edgeWarmupFadeIn; // fade-in when becoming stable
  final Duration edgeWarmupFadeOut; // fade-out when becoming unstable
  final double edgeMinAlphaDuringWarmup; // min alpha while unstable (0..1)
  // Viewport controls
  final double minViewportScale; // lower bound for zoom
  final double maxViewportScale; // upper bound for zoom
  final double defaultViewportScale; // default scale on reset
  final double viewportFitPadding; // padding when fitting (px)
  final double viewportZoomStep; // zoom multiplier for toolbar buttons

  const RenderConfig({
    this.parentNodeRadius = 20.0,
    this.childNodeRadius = 15.0,
    this.nodeFadeFactor = 0.7,
    this.nodeRadiusShrinkFactor = 0.6,
    this.uninitializedAlphaMultiplier = 0.8,
    this.disposedAlphaMultiplier = 0.35,
    this.edgeStrokeAlpha = 0.5,
    this.edgeArrowsEnabled = true,
    this.edgeArrowBaseWidth = 6.0,
    this.edgeArrowLength = 8.0,
    this.eventDuration = const Duration(milliseconds: 1500),
    this.eventDotRadius = 3.0,
    this.severityEmphasisEnabled = true,
    this.severityEmphasisMinLevel = UyavaSeverity.warn,
    this.severityNodePulseScale = 1.25,
    this.severityEdgeDotScale = 1.25,
    this.queueLabelRadius = 9.0,
    this.queueLabelOffset = 6.0,
    this.queueLabelMinCountToShow = 2,
    this.queueLabelMaxCount = 9,
    this.queueLabelFadeIn = const Duration(milliseconds: 150),
    this.queueLabelFadeOut = const Duration(milliseconds: 150),
    this.badgeTintBySeverity = true,
    this.nodeEventBadgeEnabled = true,
    this.nodeEventBadgeLeftSide = true,
    this.nodePulseMaxScale = 2.0,
    this.nodePulseAlpha = 1.0,
    this.nodePulseStrokeWidth = 4.0,
    this.nodeFlashEnabled = true,
    this.nodeFlashDuration = const Duration(milliseconds: 100),
    this.nodeFlashAlpha = 0.35,
    this.nodeFlashScaleBoost = 0.1,
    this.nodeFlashAdditive = true,
    this.nodeFlashContrastAware = true,
    this.nodeFlashMinContrast = 1.0,
    this.nodeFlashInvertColor = true,
    this.ease = Curves.easeInOut,
    this.cloudFadeWindow = 0.15,
    this.edgeRemapThreshold = 0.5,
    this.expandRevealWindow = 0.15,
    this.hideEdgesDuringWarmup = false,
    this.edgeStableSpeedThreshold = 120.0,
    this.edgeUnstableHysteresisMultiplier = 1.5,
    this.edgeStabilityEmaFactor = 0.25,
    this.edgeWarmupFadeIn = const Duration(milliseconds: 400),
    this.edgeWarmupFadeOut = const Duration(milliseconds: 200),
    this.edgeMinAlphaDuringWarmup = 0.0,
    this.minViewportScale = 0.2,
    this.maxViewportScale = 6.0,
    this.defaultViewportScale = 1.0,
    this.viewportFitPadding = 96.0,
    this.viewportZoomStep = 1.2,
  });

  RenderConfig copyWith({
    double? parentNodeRadius,
    double? childNodeRadius,
    double? nodeFadeFactor,
    double? nodeRadiusShrinkFactor,
    double? uninitializedAlphaMultiplier,
    double? disposedAlphaMultiplier,
    double? edgeStrokeAlpha,
    bool? edgeArrowsEnabled,
    double? edgeArrowBaseWidth,
    double? edgeArrowLength,
    Duration? eventDuration,
    double? eventDotRadius,
    bool? severityEmphasisEnabled,
    UyavaSeverity? severityEmphasisMinLevel,
    double? severityNodePulseScale,
    double? severityEdgeDotScale,
    double? queueLabelRadius,
    double? queueLabelOffset,
    int? queueLabelMinCountToShow,
    int? queueLabelMaxCount,
    Duration? queueLabelFadeIn,
    Duration? queueLabelFadeOut,
    bool? badgeTintBySeverity,
    bool? nodeEventBadgeEnabled,
    bool? nodeEventBadgeLeftSide,
    double? nodePulseMaxScale,
    double? nodePulseAlpha,
    double? nodePulseStrokeWidth,
    bool? nodeFlashEnabled,
    Duration? nodeFlashDuration,
    double? nodeFlashAlpha,
    double? nodeFlashScaleBoost,
    bool? nodeFlashAdditive,
    bool? nodeFlashContrastAware,
    double? nodeFlashMinContrast,
    bool? nodeFlashInvertColor,
    Curve? ease,
    double? cloudFadeWindow,
    double? edgeRemapThreshold,
    double? expandRevealWindow,
    bool? hideEdgesDuringWarmup,
    double? edgeStableSpeedThreshold,
    double? edgeUnstableHysteresisMultiplier,
    double? edgeStabilityEmaFactor,
    Duration? edgeWarmupFadeIn,
    Duration? edgeWarmupFadeOut,
    double? edgeMinAlphaDuringWarmup,
    double? minViewportScale,
    double? maxViewportScale,
    double? defaultViewportScale,
    double? viewportFitPadding,
    double? viewportZoomStep,
  }) {
    return RenderConfig(
      parentNodeRadius: parentNodeRadius ?? this.parentNodeRadius,
      childNodeRadius: childNodeRadius ?? this.childNodeRadius,
      nodeFadeFactor: nodeFadeFactor ?? this.nodeFadeFactor,
      nodeRadiusShrinkFactor:
          nodeRadiusShrinkFactor ?? this.nodeRadiusShrinkFactor,
      uninitializedAlphaMultiplier:
          uninitializedAlphaMultiplier ?? this.uninitializedAlphaMultiplier,
      disposedAlphaMultiplier:
          disposedAlphaMultiplier ?? this.disposedAlphaMultiplier,
      edgeStrokeAlpha: edgeStrokeAlpha ?? this.edgeStrokeAlpha,
      edgeArrowsEnabled: edgeArrowsEnabled ?? this.edgeArrowsEnabled,
      edgeArrowBaseWidth: edgeArrowBaseWidth ?? this.edgeArrowBaseWidth,
      edgeArrowLength: edgeArrowLength ?? this.edgeArrowLength,
      eventDuration: eventDuration ?? this.eventDuration,
      eventDotRadius: eventDotRadius ?? this.eventDotRadius,
      severityEmphasisEnabled:
          severityEmphasisEnabled ?? this.severityEmphasisEnabled,
      severityEmphasisMinLevel:
          severityEmphasisMinLevel ?? this.severityEmphasisMinLevel,
      severityNodePulseScale:
          severityNodePulseScale ?? this.severityNodePulseScale,
      severityEdgeDotScale: severityEdgeDotScale ?? this.severityEdgeDotScale,
      queueLabelRadius: queueLabelRadius ?? this.queueLabelRadius,
      queueLabelOffset: queueLabelOffset ?? this.queueLabelOffset,
      queueLabelMinCountToShow:
          queueLabelMinCountToShow ?? this.queueLabelMinCountToShow,
      queueLabelMaxCount: queueLabelMaxCount ?? this.queueLabelMaxCount,
      queueLabelFadeIn: queueLabelFadeIn ?? this.queueLabelFadeIn,
      queueLabelFadeOut: queueLabelFadeOut ?? this.queueLabelFadeOut,
      badgeTintBySeverity: badgeTintBySeverity ?? this.badgeTintBySeverity,
      nodeEventBadgeEnabled:
          nodeEventBadgeEnabled ?? this.nodeEventBadgeEnabled,
      nodeEventBadgeLeftSide:
          nodeEventBadgeLeftSide ?? this.nodeEventBadgeLeftSide,
      nodePulseMaxScale: nodePulseMaxScale ?? this.nodePulseMaxScale,
      nodePulseAlpha: nodePulseAlpha ?? this.nodePulseAlpha,
      nodePulseStrokeWidth: nodePulseStrokeWidth ?? this.nodePulseStrokeWidth,
      nodeFlashEnabled: nodeFlashEnabled ?? this.nodeFlashEnabled,
      nodeFlashDuration: nodeFlashDuration ?? this.nodeFlashDuration,
      nodeFlashAlpha: nodeFlashAlpha ?? this.nodeFlashAlpha,
      nodeFlashScaleBoost: nodeFlashScaleBoost ?? this.nodeFlashScaleBoost,
      nodeFlashAdditive: nodeFlashAdditive ?? this.nodeFlashAdditive,
      nodeFlashContrastAware:
          nodeFlashContrastAware ?? this.nodeFlashContrastAware,
      nodeFlashMinContrast: nodeFlashMinContrast ?? this.nodeFlashMinContrast,
      nodeFlashInvertColor: nodeFlashInvertColor ?? this.nodeFlashInvertColor,
      ease: ease ?? this.ease,
      cloudFadeWindow: cloudFadeWindow ?? this.cloudFadeWindow,
      edgeRemapThreshold: edgeRemapThreshold ?? this.edgeRemapThreshold,
      expandRevealWindow: expandRevealWindow ?? this.expandRevealWindow,
      hideEdgesDuringWarmup:
          hideEdgesDuringWarmup ?? this.hideEdgesDuringWarmup,
      edgeStableSpeedThreshold:
          edgeStableSpeedThreshold ?? this.edgeStableSpeedThreshold,
      edgeUnstableHysteresisMultiplier:
          edgeUnstableHysteresisMultiplier ??
          this.edgeUnstableHysteresisMultiplier,
      edgeStabilityEmaFactor:
          edgeStabilityEmaFactor ?? this.edgeStabilityEmaFactor,
      edgeWarmupFadeIn: edgeWarmupFadeIn ?? this.edgeWarmupFadeIn,
      edgeWarmupFadeOut: edgeWarmupFadeOut ?? this.edgeWarmupFadeOut,
      edgeMinAlphaDuringWarmup:
          edgeMinAlphaDuringWarmup ?? this.edgeMinAlphaDuringWarmup,
      minViewportScale: minViewportScale ?? this.minViewportScale,
      maxViewportScale: maxViewportScale ?? this.maxViewportScale,
      defaultViewportScale: defaultViewportScale ?? this.defaultViewportScale,
      viewportFitPadding: viewportFitPadding ?? this.viewportFitPadding,
      viewportZoomStep: viewportZoomStep ?? this.viewportZoomStep,
    );
  }
}
