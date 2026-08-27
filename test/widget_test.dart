import 'package:blocky/game/block_color_palette.dart';
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

  test('alternates the moving axis for each next block', () {
    final gameController = BlockyGameController();

    expect(gameController.movingAxis, MovingBlockAxis.x);

    gameController.startNextBlock();

    expect(gameController.isMoving, isTrue);
    expect(gameController.movingAxis, MovingBlockAxis.z);

    gameController.startNextBlock();

    expect(gameController.movingAxis, MovingBlockAxis.x);
  });

  test('adds one point after a successful placement', () {
    final gameController = BlockyGameController();

    expect(gameController.score, 0);

    gameController.startNextBlock();

    expect(gameController.score, 1);
  });

  test('cycles block colors through deterministic hue steps', () {
    const initialHue = 37.0;
    final firstColor = BlockColorPalette.colorForBlock(
      0,
      initialHue: initialHue,
    );
    final nextColor = BlockColorPalette.colorForBlock(
      1,
      initialHue: initialHue,
    );

    expect(nextColor, isNot(firstColor));
    expect(
      BlockColorPalette.colorForBlock(20, initialHue: initialHue),
      firstColor,
    );
  });

  test('calculates the valid horizontal block overlap', () {
    final overlap = calculateBlockOverlap(
      below: const BlockAxisRange(center: 0.0, length: 3.6),
      current: const BlockAxisRange(center: 1.0, length: 3.6),
    );

    expect(overlap.hasOverlap, isTrue);
    expect(overlap.length, closeTo(2.6, 0.0001));
    expect(overlap.center, closeTo(0.5, 0.0001));
  });

  test('identifies when blocks do not overlap', () {
    final overlap = calculateBlockOverlap(
      below: const BlockAxisRange(center: 0.0, length: 3.6),
      current: const BlockAxisRange(center: 4.0, length: 3.6),
    );

    expect(overlap.hasOverlap, isFalse);
  });
}
