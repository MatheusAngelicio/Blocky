import 'package:blocky/game/block_overlap.dart';
import 'package:blocky/game/blocky_game_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('stops the moving block', () {
    final gameController = BlockyGameController();

    expect(gameController.isMoving, isTrue);

    gameController.stopMovingBlock();

    expect(gameController.isMoving, isFalse);
  });

  test('calculates the valid horizontal block overlap', () {
    final overlap = calculateBlockOverlap(
      below: const BlockFootprint(centerX: 0.0, width: 3.6),
      current: const BlockFootprint(centerX: 1.0, width: 3.6),
    );

    expect(overlap.hasOverlap, isTrue);
    expect(overlap.width, closeTo(2.6, 0.0001));
    expect(overlap.centerX, closeTo(0.5, 0.0001));
  });

  test('identifies when blocks do not overlap', () {
    final overlap = calculateBlockOverlap(
      below: const BlockFootprint(centerX: 0.0, width: 3.6),
      current: const BlockFootprint(centerX: 4.0, width: 3.6),
    );

    expect(overlap.hasOverlap, isFalse);
  });
}
