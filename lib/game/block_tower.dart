import 'package:blocky/game/block_overlap.dart';
import 'package:blocky/game/block_placement_result.dart';
import 'package:blocky/game/game_config.dart';
import 'package:blocky/game/moving_block_axis.dart';

/// Estado geométrico e regras de posicionamento da torre.
///
/// Não conhece Flutter Scene, Nodes, materiais, áudio ou pontuação.
class BlockTower {
  BlockTower({
    this.maximumWidth = GameConfig.blockWidth,
    this.maximumDepth = GameConfig.blockDepth,
    this.perfectTolerance = GameConfig.perfectPlacementTolerance,
  }) : assert(maximumWidth > 0.0),
       assert(maximumDepth > 0.0),
       assert(perfectTolerance >= 0.0),
       _width = maximumWidth,
       _depth = maximumDepth;

  final double maximumWidth;
  final double maximumDepth;
  final double perfectTolerance;

  double _centerX = 0.0;
  double _centerZ = 0.0;
  double _topY = 0.0;
  double _width;
  double _depth;
  MovingBlockAxis? _lastReducedAxis;

  double get centerX => _centerX;
  double get centerZ => _centerZ;
  double get topY => _topY;
  double get width => _width;
  double get depth => _depth;
  MovingBlockAxis? get lastReducedAxis => _lastReducedAxis;

  double centerFor(MovingBlockAxis axis) => switch (axis) {
    MovingBlockAxis.x => _centerX,
    MovingBlockAxis.z => _centerZ,
  };

  double lengthFor(MovingBlockAxis axis) => switch (axis) {
    MovingBlockAxis.x => _width,
    MovingBlockAxis.z => _depth,
  };

  double maximumLengthFor(MovingBlockAxis axis) => switch (axis) {
    MovingBlockAxis.x => maximumWidth,
    MovingBlockAxis.z => maximumDepth,
  };

  void reset() {
    _centerX = 0.0;
    _centerZ = 0.0;
    _topY = 0.0;
    _width = maximumWidth;
    _depth = maximumDepth;
    _lastReducedAxis = null;
  }

  BlockPlacementResult place({
    required MovingBlockAxis axis,
    required double currentCenter,
    required double blockY,
  }) {
    final currentLength = lengthFor(axis);
    final below = BlockAxisRange(
      center: centerFor(axis),
      length: currentLength,
    );
    final current = BlockAxisRange(
      center: currentCenter,
      length: currentLength,
    );
    final overlap = calculateBlockOverlap(below: below, current: current);
    if (!overlap.hasOverlap) {
      return const BlockPlacementResult.missed();
    }

    final isPerfect = isPerfectBlockPlacement(
      below: below,
      current: current,
      tolerance: perfectTolerance,
    );
    if (isPerfect) {
      _setCenter(axis, below.center);
      _topY = blockY;
      return const BlockPlacementResult.perfect();
    }

    final cutRange = calculateCutOffRange(current: current, overlap: overlap);
    assert(cutRange != null, 'A non-perfect overlap must produce a cut.');
    _setCenter(axis, overlap.center);
    _setLength(axis, overlap.length);
    _lastReducedAxis = axis;
    _topY = blockY;
    return BlockPlacementResult.cut(
      cutOff: BlockCutOff(
        axis: axis,
        range: cutRange!,
        width: axis == MovingBlockAxis.x ? cutRange.length : _width,
        depth: axis == MovingBlockAxis.z ? cutRange.length : _depth,
        outwardDirection: cutRange.center > overlap.center ? 1.0 : -1.0,
      ),
    );
  }

  BlockRecoveryResult? recoverLastReducedAxis() {
    final axis = _lastReducedAxis;
    if (axis == null) return null;

    final previousLength = lengthFor(axis);
    final recoveredLength = GameConfig.recoverBlockLength(
      currentLength: previousLength,
      maximumLength: maximumLengthFor(axis),
    );
    if (recoveredLength == previousLength) return null;

    _setLength(axis, recoveredLength);
    return BlockRecoveryResult(
      axis: axis,
      previousLength: previousLength,
      recoveredLength: recoveredLength,
    );
  }

  void _setCenter(MovingBlockAxis axis, double center) {
    switch (axis) {
      case MovingBlockAxis.x:
        _centerX = center;
      case MovingBlockAxis.z:
        _centerZ = center;
    }
  }

  void _setLength(MovingBlockAxis axis, double length) {
    switch (axis) {
      case MovingBlockAxis.x:
        _width = length;
      case MovingBlockAxis.z:
        _depth = length;
    }
  }
}
