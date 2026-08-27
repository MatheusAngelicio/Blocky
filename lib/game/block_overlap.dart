import 'dart:math' as math;

class BlockFootprint {
  const BlockFootprint({required this.centerX, required this.width});

  final double centerX;
  final double width;

  double get left => centerX - width / 2;
  double get right => centerX + width / 2;
}

class BlockOverlap {
  const BlockOverlap({required this.left, required this.right});

  final double left;
  final double right;

  bool get hasOverlap => right > left;
  double get width => math.max(0.0, right - left);
  double get centerX => (left + right) / 2;
}

BlockOverlap calculateBlockOverlap({
  required BlockFootprint current,
  required BlockFootprint below,
}) {
  return BlockOverlap(
    left: math.max(current.left, below.left),
    right: math.min(current.right, below.right),
  );
}
