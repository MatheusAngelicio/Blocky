import 'package:blocky/game/block_color_palette.dart';
import 'package:blocky/game/block_overlap.dart';
import 'package:blocky/game/blocky_game_controller.dart';
import 'package:blocky/game/game_config.dart';
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

  test('increases block speed smoothly up to a maximum', () {
    final initialSpeed = GameConfig.movingBlockSpeedForScore(0);
    final intermediateSpeed = GameConfig.movingBlockSpeedForScore(10);
    final advancedSpeed = GameConfig.movingBlockSpeedForScore(30);
    final maximumApproach = GameConfig.movingBlockSpeedForScore(1000);

    expect(initialSpeed, GameConfig.movingBlockInitialSpeed);
    expect(intermediateSpeed, greaterThan(initialSpeed));
    expect(advancedSpeed, greaterThan(intermediateSpeed));
    expect(
      maximumApproach,
      lessThanOrEqualTo(GameConfig.movingBlockMaximumSpeed),
    );
    expect(
      maximumApproach,
      closeTo(GameConfig.movingBlockMaximumSpeed, 0.0001),
    );
  });

  test('shows perfect feedback without changing the normal score', () async {
    final gameController = BlockyGameController(
      perfectFeedbackDuration: const Duration(milliseconds: 10),
    );

    gameController.startNextBlock(isPerfect: true);

    expect(gameController.score, 1);
    expect(gameController.isShowingPerfect, isTrue);

    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(gameController.isShowingPerfect, isFalse);
    gameController.dispose();
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

  test('identifies a placement within the perfect tolerance', () {
    const below = BlockAxisRange(center: 0.0, length: 3.6);

    expect(
      isPerfectBlockPlacement(
        below: below,
        current: const BlockAxisRange(center: 0.12, length: 3.6),
        tolerance: GameConfig.perfectPlacementTolerance,
      ),
      isTrue,
    );
    expect(
      isPerfectBlockPlacement(
        below: below,
        current: const BlockAxisRange(center: 0.13, length: 3.6),
        tolerance: GameConfig.perfectPlacementTolerance,
      ),
      isFalse,
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
