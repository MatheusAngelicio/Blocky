import 'dart:async';

import 'package:blocky/design_system/arcade_colors.dart';
import 'package:blocky/design_system/design_system.dart';
import 'package:blocky/app/blocky_colors.dart';
import 'package:blocky/app/blocky_localizations.dart';
import 'package:blocky/audio/asset_game_sound_player.dart';
import 'package:blocky/game/blocky_game_controller.dart';
import 'package:blocky/game/game_sound.dart';
import 'package:blocky/game/game_settings.dart';
import 'package:blocky/game/block_theme.dart';
import 'package:blocky/scene/blocky_scene.dart';
import 'package:flutter/material.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({
    super.key,
    this.blockTheme = BlockTheme.classic,
    this.settings = const GameSettings(),
  });

  final BlockTheme blockTheme;
  final GameSettings settings;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final BlockyGameController _gameController;
  late final GameSoundPlayer _soundPlayer;

  @override
  void initState() {
    super.initState();
    _gameController = BlockyGameController();
    _soundPlayer = AssetGameSoundPlayer(volume: widget.settings.soundVolume);
    _gameController.addListener(_onGameStateChanged);
    unawaited(_gameController.loadBestScore());
    unawaited(_gameController.loadBlockyCoins());
  }

  @override
  void dispose() {
    _gameController.removeListener(_onGameStateChanged);
    _gameController.dispose();
    _soundPlayer.dispose();
    super.dispose();
  }

  void _onGameStateChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: BlockyColors.initialSky,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _gameController.stopMovingBlock(),
        child: Stack(
          fit: StackFit.expand,
          children: [
            BlockyScene(
              gameController: _gameController,
              soundPlayer: _soundPlayer,
              blockTheme: widget.blockTheme,
              hapticsEnabled: widget.settings.hapticsEnabled,
              cameraAngle: widget.settings.cameraAngle,
            ),
            IgnorePointer(
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ArcadeStat(
                      label: l10n.score,
                      value: '${_gameController.score}',
                      accent: ArcadeColors.primary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 9,
                      ),
                      valueStyle: ArcadeTypography.value.copyWith(
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (_gameController.isShowingPerfect)
              IgnorePointer(
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 118),
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 290),
                        child: ArcadePanel(
                          accent: ArcadeColors.success,
                          backgroundColor: ArcadeColors.hudSurface,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          shadowOffset: const Offset(3, 4),
                          child: Text(
                            l10n.perfectFeedback(
                              streak: _gameController.perfectStreak,
                              isRecovery: _gameController
                                  .isShowingPerfectRecoveryFeedback,
                            ),
                            textAlign: TextAlign.center,
                            style: ArcadeTypography.heading.copyWith(
                              color: BlockyColors.perfectText,
                              fontSize: 18,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            if (_gameController.isGameOver)
              Positioned.fill(
                child: ColoredBox(
                  color: ArcadeColors.scrim,
                  child: SafeArea(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 28),
                        child: ArcadePanel(
                          accent: ArcadeColors.primary,
                          borderWidth: 3,
                          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                          shadowOffset: const Offset(6, 7),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'BLOCKY',
                                style: ArcadeTypography.logo.copyWith(
                                  fontSize: 25,
                                  letterSpacing: 3,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                l10n.gameOver,
                                style: ArcadeTypography.heading,
                              ),
                              const SizedBox(height: 24),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: 110,
                                    child: ArcadeStat(
                                      label: l10n.score,
                                      value: '${_gameController.score}',
                                      valueStyle: ArcadeTypography.value
                                          .copyWith(fontSize: 40),
                                    ),
                                  ),
                                  const SizedBox(width: 18),
                                  SizedBox(
                                    width: 110,
                                    child: ArcadeStat(
                                      label: l10n.best,
                                      value: '${_gameController.bestScore}',
                                      accent: ArcadeColors.strongOutline,
                                      valueStyle: ArcadeTypography.value
                                          .copyWith(fontSize: 40),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 18),
                              ArcadeCoinAmount(
                                amount:
                                    '+${_gameController.coinsEarnedThisGame}',
                                textStyle: ArcadeTypography.button.copyWith(
                                  color: ArcadeColors.primary,
                                  fontSize: 13,
                                  letterSpacing: 1.0,
                                ),
                              ),
                              const SizedBox(height: 28),
                              ArcadeButton(
                                label: l10n.playAgain,
                                onPressed: _gameController.restartGame,
                              ),
                              const SizedBox(height: 12),
                              ArcadeButton(
                                label: l10n.home,
                                color: ArcadeColors.strongOutline,
                                foregroundColor: ArcadeColors.ink,
                                onPressed: () => Navigator.of(context).pop(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
