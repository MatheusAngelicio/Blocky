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
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xE8282341),
                        border: Border.all(
                          color: const Color(0xFFFFD65C),
                          width: 2,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x99080611),
                            offset: Offset(3, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'SCORE',
                            style: TextStyle(
                              color: Color(0xFFFFD65C),
                              fontFamily: 'monospace',
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.8,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${_gameController.score}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontFamily: 'monospace',
                              fontSize: 30,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
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
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 290),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xE8282341),
                          border: Border.all(
                            color: const Color(0xFF8EE8C5),
                            width: 2,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x99080611),
                              offset: Offset(3, 4),
                            ),
                          ],
                        ),
                        child: Text(
                          _gameController.perfectFeedbackText,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFFB7F7D5),
                            fontFamily: 'monospace',
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.1,
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
                  color: const Color(0xD6151225),
                  child: SafeArea(
                    child: Center(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 28),
                        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                        decoration: BoxDecoration(
                          color: const Color(0xFF282341),
                          border: Border.all(
                            color: const Color(0xFFFFD65C),
                            width: 3,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0xFF080611),
                              offset: Offset(6, 7),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'BLOCKY',
                              style: TextStyle(
                                color: Color(0xFFFFD65C),
                                fontFamily: 'monospace',
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 3,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'GAME OVER',
                              style: TextStyle(
                                color: Colors.white,
                                fontFamily: 'monospace',
                                fontSize: 30,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _GameOverStat(
                                  label: 'SCORE',
                                  value: _gameController.score,
                                ),
                                const SizedBox(width: 36),
                                _GameOverStat(
                                  label: 'BEST',
                                  value: _gameController.bestScore,
                                ),
                              ],
                            ),
                            const SizedBox(height: 28),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton(
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFFFFD65C),
                                  foregroundColor: const Color(0xFF171323),
                                  side: const BorderSide(
                                    color: Color(0xFF171323),
                                    width: 2,
                                  ),
                                ),
                                onPressed: _gameController.restartGame,
                                child: const Text('PLAY AGAIN'),
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFFCEC5E7),
                                  side: const BorderSide(
                                    color: Color(0xFF8D82BB),
                                    width: 2,
                                  ),
                                  shape: const RoundedRectangleBorder(),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 15,
                                  ),
                                  textStyle: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text('HOME'),
                              ),
                            ),
                          ],
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
            fontFamily: 'monospace',
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
            fontFamily: 'monospace',
            fontSize: 48,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.4,
          ),
        ),
      ],
    );
  }
}
