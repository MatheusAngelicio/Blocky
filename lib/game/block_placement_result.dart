import 'package:blocky/game/block_overlap.dart';
import 'package:blocky/game/moving_block_axis.dart';

enum BlockPlacementStatus { missed, perfect, cut }

/// Geometria lógica do pedaço excedente de um posicionamento.
class BlockCutOff {
  const BlockCutOff({
    required this.axis,
    required this.range,
    required this.width,
    required this.depth,
    required this.outwardDirection,
  });

  final MovingBlockAxis axis;
  final BlockAxisRange range;
  final double width;
  final double depth;
  final double outwardDirection;
}

/// Resultado imutável que a cena usa para representar um posicionamento.
class BlockPlacementResult {
  const BlockPlacementResult._({required this.status, this.cutOff});

  const BlockPlacementResult.missed()
    : this._(status: BlockPlacementStatus.missed);

  const BlockPlacementResult.perfect()
    : this._(status: BlockPlacementStatus.perfect);

  const BlockPlacementResult.cut({required BlockCutOff cutOff})
    : this._(status: BlockPlacementStatus.cut, cutOff: cutOff);

  final BlockPlacementStatus status;
  final BlockCutOff? cutOff;

  bool get hasOverlap => status != BlockPlacementStatus.missed;
  bool get isPerfect => status == BlockPlacementStatus.perfect;
  bool get wasCut => status == BlockPlacementStatus.cut;
}

class BlockRecoveryResult {
  const BlockRecoveryResult({
    required this.axis,
    required this.previousLength,
    required this.recoveredLength,
  });

  final MovingBlockAxis axis;
  final double previousLength;
  final double recoveredLength;

  double get initialVisualScale => previousLength / recoveredLength;
}
