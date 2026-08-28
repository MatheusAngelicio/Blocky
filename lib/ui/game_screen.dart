import 'dart:async';

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
      backgroundColor: const Color(0xFF7ECF8D),
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
                    child: Text(
                      '${_gameController.score}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
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
                    padding: const EdgeInsets.only(top: 88),
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: Text(
                        _gameController.perfectFeedbackText,
                        style: const TextStyle(
                          color: Color(0xFFFFE082),
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            if (_gameController.isGameOver)
              Positioned.fill(
                child: ColoredBox(
                  color: Color(0xB0101018),
                  child: SafeArea(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Blocky',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 42,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 20),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _GameOverStat(
                                label: 'SCORE',
                                value: _gameController.score,
                              ),
                              SizedBox(width: 36),
                              _GameOverStat(
                                label: 'BEST',
                                value: _gameController.bestScore,
                              ),
                            ],
                          ),
                          SizedBox(height: 28),
                          FilledButton(
                            onPressed: _gameController.restartGame,
                            child: Text('Play Again'),
                          ),
                        ],
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

class _GameOverStat extends StatelessWidget {
  const _GameOverStat({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$value',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 48,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
