import 'package:blocky/game/block_color_palette.dart';
import 'package:blocky/game/block_overlap.dart';
import 'package:blocky/game/block_theme.dart';
import 'package:blocky/game/blocky_game_controller.dart';
import 'package:blocky/game/best_score_storage.dart';
import 'package:blocky/game/game_config.dart';
import 'package:blocky/game/game_haptics.dart';
import 'package:blocky/game/game_sound.dart';
import 'package:blocky/scene/block_theme_visual.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('uses distinct haptic feedback for each gameplay event', () async {
    final feedbackTypes = <String>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          feedbackTypes.add(call.arguments! as String);
          return null;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null),
    );

    for (final event in GameHapticEvent.values) {
      GameHaptics.trigger(event);
    }
    await Future<void>.delayed(Duration.zero);

    expect(feedbackTypes, [
      'HapticFeedbackType.selectionClick',
      'HapticFeedbackType.lightImpact',
      'HapticFeedbackType.mediumImpact',
      'HapticFeedbackType.heavyImpact',
    ]);
  });

  test('declares every required gameplay sound asset', () {
    expect(GameSound.values, [
      GameSound.placement,
      GameSound.cut,
      GameSound.perfect,
      GameSound.perfectRecovery,
      GameSound.gameOver,
    ]);
  });

  test('provides Classic and Jelly block themes', () {
    expect(BlockTheme.values, [BlockTheme.classic, BlockTheme.jelly]);
    expect(
      BlockThemeVisual.forTheme(BlockTheme.classic),
      same(BlockThemeVisual.classic),
    );
    expect(
      BlockThemeVisual.forTheme(BlockTheme.jelly),
      same(BlockThemeVisual.jelly),
    );
    expect(
      BlockThemeVisual.jelly.placementImpact.motion,
      BlockImpactMotion.squashAndStretch,
    );
    expect(
      BlockThemeVisual.jelly.roughnessFactor,
      BlockThemeVisual.classic.roughnessFactor,
    );
    expect(BlockThemeVisual.jelly.materialAlpha, 1.0);
    expect(BlockThemeVisual.jelly.transmission, 0.0);
    expect(
      BlockThemeVisual.jelly.fallingVisual.wobbleAmplitude,
      greaterThan(0),
    );
    expect(
      BlockThemeVisual.jelly.perfectWobble.translationAmplitude,
      greaterThan(0),
    );
    expect(
      BlockThemeVisual.jelly.perfectWobble.rotationAmplitude,
      greaterThan(0),
    );
    expect(BlockThemeVisual.jelly.recoveryGrowthOvershoot, greaterThan(0));
  });

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
    expect(gameController.perfectStreak, 0);

    gameController.startNextBlock();

    expect(gameController.score, 1);
  });

  test('ends the game and prevents new blocks after a miss', () {
    final gameController = BlockyGameController(
      bestScoreStorage: _InMemoryBestScoreStorage(),
    );

    gameController.startNextBlock(isPerfect: true);
    gameController.endGame();

    expect(gameController.status, GameStatus.gameOver);
    expect(gameController.isMoving, isFalse);
    expect(gameController.startNextBlock(), isFalse);
    expect(gameController.score, 1);
    expect(gameController.perfectStreak, 0);
    gameController.dispose();
  });

  test('restarts the game from its initial state', () {
    final gameController = BlockyGameController(
      bestScoreStorage: _InMemoryBestScoreStorage(),
    );

    gameController.startNextBlock(isPerfect: true);
    gameController.endGame();
    gameController.restartGame();

    expect(gameController.status, GameStatus.playing);
    expect(gameController.isMoving, isTrue);
    expect(gameController.movingAxis, MovingBlockAxis.x);
    expect(gameController.score, 0);
    expect(gameController.isShowingPerfect, isFalse);
    expect(gameController.perfectStreak, 0);
    expect(gameController.round, 1);
    gameController.dispose();
  });

  test('loads and persists a new best score after game over', () async {
    final storage = _InMemoryBestScoreStorage(3);
    final gameController = BlockyGameController(bestScoreStorage: storage);

    expect(gameController.bestScore, 0);

    await gameController.loadBestScore();
    expect(gameController.bestScore, 3);

    for (var score = 0; score < 4; score++) {
      gameController.startNextBlock();
    }
    gameController.endGame();
    await Future<void>.delayed(Duration.zero);

    expect(gameController.bestScore, 4);
    expect(storage.storedScore, 4);

    gameController.restartGame();
    expect(gameController.bestScore, 4);
    gameController.dispose();
  });

  test('does not replace a stored best score before it is loaded', () async {
    final storage = _InMemoryBestScoreStorage(10);
    final gameController = BlockyGameController(bestScoreStorage: storage);

    gameController.startNextBlock();
    gameController.endGame();
    await Future<void>.delayed(Duration.zero);

    expect(gameController.bestScore, 10);
    expect(storage.storedScore, 10);
    gameController.dispose();
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

  test('recovers a block length without exceeding its original maximum', () {
    expect(
      GameConfig.recoverBlockLength(
        currentLength: 2.4,
        maximumLength: GameConfig.blockWidth,
      ),
      closeTo(3.0, 0.0001),
    );
    expect(
      GameConfig.recoverBlockLength(
        currentLength: 3.4,
        maximumLength: GameConfig.blockWidth,
      ),
      GameConfig.blockWidth,
    );
  });

  test('keeps the placement impact subtle and brief', () {
    expect(GameConfig.placementImpactDuration.inMilliseconds, lessThan(200));
    expect(GameConfig.placementImpactHorizontalScale, lessThan(0.05));
    expect(GameConfig.placementImpactVerticalScale, lessThan(0.1));
  });

  test('keeps the perfect particle effect compact', () {
    expect(GameConfig.perfectParticleCount, lessThanOrEqualTo(12));
    expect(GameConfig.perfectParticleLifetime, lessThan(0.6));
    expect(
      GameConfig.perfectParticleEffectDuration.inMilliseconds,
      lessThan(700),
    );
  });

  test('makes recovery feedback more noticeable without slowing the game', () {
    expect(
      GameConfig.perfectRecoveryAnimationDuration.inMilliseconds,
      lessThan(300),
    );
    expect(
      GameConfig.perfectRecoveryParticleCount,
      greaterThan(GameConfig.perfectParticleCount),
    );
    expect(
      GameConfig.perfectRecoveryParticleEffectDuration.inMilliseconds,
      lessThan(800),
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

  test('tracks consecutive perfect placements and resets on a normal one', () {
    final gameController = BlockyGameController();

    gameController.startNextBlock(isPerfect: true);
    expect(gameController.perfectStreak, 1);
    expect(gameController.perfectFeedbackText, 'PERFECT!');

    gameController.startNextBlock(isPerfect: true);
    expect(gameController.perfectStreak, 2);
    expect(gameController.perfectFeedbackText, 'PERFECT! x2');

    gameController.startNextBlock(isPerfect: true);
    gameController.startNextBlock(isPerfect: true);
    expect(gameController.perfectStreak, GameConfig.perfectStreakForRecovery);
    expect(gameController.perfectFeedbackText, 'PERFECT! x4');

    expect(gameController.consumePerfectRecovery(), isTrue);
    expect(gameController.perfectStreak, 0);
    expect(gameController.perfectFeedbackText, 'PERFECT RECOVERY!');

    gameController.startNextBlock();
    expect(gameController.perfectStreak, 0);
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
      BlockColorPalette.colorForBlock(45, initialHue: initialHue),
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

  test('calculates the overhanging portion to cut off', () {
    const current = BlockAxisRange(center: 1.0, length: 3.6);
    final overlap = calculateBlockOverlap(
      below: const BlockAxisRange(center: 0.0, length: 3.6),
      current: current,
    );

    final cutOff = calculateCutOffRange(current: current, overlap: overlap);

    expect(cutOff, isNotNull);
    expect(cutOff!.length, closeTo(1.0, 0.0001));
    expect(cutOff.center, closeTo(2.3, 0.0001));
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

class _InMemoryBestScoreStorage extends BestScoreStorage {
  _InMemoryBestScoreStorage([this.storedScore = 0]);

  int storedScore;

  @override
  Future<int> load() async => storedScore;

  @override
  Future<void> save(int score) async {
    storedScore = score;
  }
}
