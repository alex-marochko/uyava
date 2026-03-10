import 'dart:math' as math;

class Vector2 {
  final double x;
  final double y;

  const Vector2(this.x, this.y);

  static const zero = Vector2(0, 0);

  double get dx => x;
  double get dy => y;

  double get distance => math.sqrt(x * x + y * y);

  Vector2 operator +(Vector2 other) => Vector2(x + other.x, y + other.y);
  Vector2 operator -(Vector2 other) => Vector2(x - other.x, y - other.y);
  Vector2 operator *(double s) => Vector2(x * s, y * s);
  Vector2 operator /(double s) => Vector2(x / s, y / s);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Vector2 && x == other.x && y == other.y;

  @override
  int get hashCode => Object.hash(x, y);

  @override
  String toString() => 'Vector2($x, $y)';
}
