import 'dart:math' as math;

class BlockAxisRange {
  const BlockAxisRange({required this.center, required this.length});

  final double center;
  final double length;

  double get start => center - length / 2;
  double get end => center + length / 2;
}

class BlockOverlap {
  const BlockOverlap({required this.start, required this.end});

  final double start;
  final double end;

  bool get hasOverlap => end > start;
  double get length => math.max(0.0, end - start);
  double get center => (start + end) / 2;
}

BlockOverlap calculateBlockOverlap({
  required BlockAxisRange current,
  required BlockAxisRange below,
}) {
  return BlockOverlap(
    start: math.max(current.start, below.start),
    end: math.min(current.end, below.end),
  );
}
