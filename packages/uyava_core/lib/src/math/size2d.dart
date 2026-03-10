class Size2D {
  final double width;
  final double height;

  const Size2D(this.width, this.height);

  static const zero = Size2D(0, 0);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Size2D && width == other.width && height == other.height;

  @override
  int get hashCode => Object.hash(width, height);

  @override
  String toString() => 'Size2D($width, $height)';
}
