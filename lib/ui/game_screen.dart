import 'dart:async';

import 'package:blocky/app/blocky_arcade.dart';
import 'package:blocky/app/blocky_colors.dart';
import 'package:blocky/audio/asset_game_sound_player.dart';
import 'package:blocky/game/blocky_game_controller.dart';
import 'package:blocky/game/game_sound.dart';
import 'package:blocky/game/block_theme.dart';
import 'package:blocky/scene/blocky_scene.dart';
import 'package:flutter/material.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key, this.blockTheme = BlockTheme.jelly});

  final BlockTheme blockTheme;

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
    _soundPlayer = AssetGameSoundPlayer();
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
            ),
            IgnorePointer(
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ArcadeStat(
                      label: 'SCORE',
                      value: '${_gameController.score}',
                      accent: BlockyColors.primary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 9,
                      ),
                      valueStyle: BlockyTypography.value.copyWith(
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
                          accent: BlockyColors.perfectBorder,
                          backgroundColor: BlockyColors.scorePanel,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          shadowOffset: const Offset(3, 4),
                          child: Text(
                            _gameController.perfectFeedbackText,
                            textAlign: TextAlign.center,
                            style: BlockyTypography.heading.copyWith(
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
                  color: BlockyColors.gameOverOverlay,
                  child: SafeArea(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 28),
                        child: ArcadePanel(
                          accent: BlockyColors.primary,
                          borderWidth: 3,
                          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                          shadowOffset: const Offset(6, 7),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'BLOCKY',
                                style: BlockyTypography.logo.copyWith(
                                  fontSize: 25,
                                  letterSpacing: 3,
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'GAME OVER',
                                style: BlockyTypography.heading,
                              ),
                              const SizedBox(height: 24),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: 110,
                                    child: ArcadeStat(
                                      label: 'SCORE',
                                      value: '${_gameController.score}',
                                      valueStyle: BlockyTypography.value
                                          .copyWith(fontSize: 40),
                                    ),
                                  ),
                                  const SizedBox(width: 18),
                                  SizedBox(
                                    width: 110,
                                    child: ArcadeStat(
                                      label: 'BEST',
                                      value: '${_gameController.bestScore}',
                                      accent: BlockyColors.secondaryBorder,
                                      valueStyle: BlockyTypography.value
                                          .copyWith(fontSize: 40),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 18),
                              Text(
                                '+ ${_gameController.coinsEarnedThisGame} BLOCKY COINS',
                                style: BlockyTypography.button.copyWith(
                                  color: BlockyColors.primary,
                                  fontSize: 13,
                                  letterSpacing: 1.0,
                                ),
                              ),
                              const SizedBox(height: 28),
                              ArcadeButton(
                                label: 'PLAY AGAIN',
                                onPressed: _gameController.restartGame,
                              ),
                              const SizedBox(height: 12),
                              ArcadeButton(
                                label: 'HOME',
                                color: BlockyColors.secondaryBorder,
                                foregroundColor: BlockyColors.frame,
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
