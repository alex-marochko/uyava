import 'dart:math' as math;

import 'package:flutter/material.dart';

double adaptiveFieldWidth({
  required double availableWidth,
  required double trailingWidth,
  required double minWidth,
  required double maxWidth,
  required double horizontalPadding,
  required String text,
  required TextStyle style,
}) {
  final double availableSpace = availableWidth.isFinite
      ? math.max(0, availableWidth - trailingWidth)
      : double.infinity;
  final double desiredWidth =
      measureTextWidth(text.isEmpty ? ' ' : text, style) + horizontalPadding;
  final double clampedWidth = desiredWidth.clamp(minWidth, maxWidth).toDouble();
  if (!availableSpace.isFinite) {
    return clampedWidth;
  }
  return math.max(minWidth, math.min(availableSpace, clampedWidth));
}

double measureTextWidth(String text, TextStyle style) {
  final TextPainter painter = TextPainter(
    text: TextSpan(text: text, style: style),
    maxLines: 1,
    textDirection: TextDirection.ltr,
  )..layout();
  return painter.width;
}
