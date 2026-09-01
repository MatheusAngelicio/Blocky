import 'package:blocky/game/block_placement_result.dart';
import 'package:blocky/game/block_tower.dart';
import 'package:blocky/game/game_config.dart';
import 'package:blocky/game/moving_block_axis.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BlockTower', () {
    test('starts with the original centered dimensions', () {
      final tower = BlockTower();

      expect(tower.centerX, 0.0);
      expect(tower.centerZ, 0.0);
      expect(tower.topY, 0.0);
      expect(tower.width, GameConfig.blockWidth);
      expect(tower.depth, GameConfig.blockDepth);
      expect(tower.lastReducedAxis, isNull);
    });

    test('aligns a Perfect without changing block dimensions', () {
      final tower = BlockTower();

      final placement = tower.place(
        axis: MovingBlockAxis.x,
        currentCenter: GameConfig.perfectPlacementTolerance,
        blockY: GameConfig.blockVerticalStep,
      );

      expect(placement.status, BlockPlacementStatus.perfect);
      expect(placement.isPerfect, isTrue);
      expect(tower.centerX, 0.0);
      expect(tower.width, GameConfig.blockWidth);
      expect(tower.depth, GameConfig.blockDepth);
      expect(tower.topY, GameConfig.blockVerticalStep);
      expect(tower.lastReducedAxis, isNull);
    });

    test('cuts on X and returns the complete excess geometry', () {
      final tower = BlockTower();

      final placement = tower.place(
        axis: MovingBlockAxis.x,
        currentCenter: 1.0,
        blockY: GameConfig.blockVerticalStep,
      );

      expect(placement.status, BlockPlacementStatus.cut);
      expect(placement.wasCut, isTrue);
      expect(tower.centerX, closeTo(0.5, 0.0001));
      expect(tower.width, closeTo(2.6, 0.0001));
      expect(tower.depth, GameConfig.blockDepth);
      expect(tower.lastReducedAxis, MovingBlockAxis.x);
      expect(placement.cutOff!.range.center, closeTo(2.3, 0.0001));
      expect(placement.cutOff!.range.length, closeTo(1.0, 0.0001));
      expect(placement.cutOff!.width, closeTo(1.0, 0.0001));
      expect(placement.cutOff!.depth, GameConfig.blockDepth);
      expect(placement.cutOff!.outwardDirection, 1.0);
    });

    test('cuts on Z and reports a negative outward direction', () {
      final tower = BlockTower();

      final placement = tower.place(
        axis: MovingBlockAxis.z,
        currentCenter: -0.8,
        blockY: GameConfig.blockVerticalStep,
      );

      expect(tower.centerZ, closeTo(-0.4, 0.0001));
      expect(tower.depth, closeTo(2.8, 0.0001));
      expect(tower.width, GameConfig.blockWidth);
      expect(tower.lastReducedAxis, MovingBlockAxis.z);
      expect(placement.cutOff!.range.center, closeTo(-2.2, 0.0001));
      expect(placement.cutOff!.width, GameConfig.blockWidth);
      expect(placement.cutOff!.depth, closeTo(0.8, 0.0001));
      expect(placement.cutOff!.outwardDirection, -1.0);
    });

    test('does not mutate the tower when there is no overlap', () {
      final tower = BlockTower();

      final placement = tower.place(
        axis: MovingBlockAxis.x,
        currentCenter: GameConfig.blockWidth + 0.1,
        blockY: GameConfig.blockVerticalStep,
      );

      expect(placement.status, BlockPlacementStatus.missed);
      expect(placement.hasOverlap, isFalse);
      expect(tower.centerX, 0.0);
      expect(tower.centerZ, 0.0);
      expect(tower.topY, 0.0);
      expect(tower.width, GameConfig.blockWidth);
      expect(tower.depth, GameConfig.blockDepth);
      expect(tower.lastReducedAxis, isNull);
    });

    test('recovers the last reduced axis up to its original maximum', () {
      final tower = BlockTower();
      tower.place(
        axis: MovingBlockAxis.x,
        currentCenter: 1.0,
        blockY: GameConfig.blockVerticalStep,
      );

      final firstRecovery = tower.recoverLastReducedAxis();
      final secondRecovery = tower.recoverLastReducedAxis();
      final unavailableRecovery = tower.recoverLastReducedAxis();

      expect(firstRecovery, isNotNull);
      expect(firstRecovery!.axis, MovingBlockAxis.x);
      expect(firstRecovery.previousLength, closeTo(2.6, 0.0001));
      expect(firstRecovery.recoveredLength, closeTo(3.2, 0.0001));
      expect(firstRecovery.initialVisualScale, closeTo(2.6 / 3.2, 0.0001));
      expect(secondRecovery!.recoveredLength, GameConfig.blockWidth);
      expect(tower.width, GameConfig.blockWidth);
      expect(unavailableRecovery, isNull);
    });

    test('reset restores every geometric value', () {
      final tower = BlockTower();
      tower.place(axis: MovingBlockAxis.z, currentCenter: 1.0, blockY: 4.0);

      tower.reset();

      expect(tower.centerX, 0.0);
      expect(tower.centerZ, 0.0);
      expect(tower.topY, 0.0);
      expect(tower.width, GameConfig.blockWidth);
      expect(tower.depth, GameConfig.blockDepth);
      expect(tower.lastReducedAxis, isNull);
    });
  });
}
