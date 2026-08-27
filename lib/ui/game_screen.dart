import 'package:blocky/game/blocky_game_controller.dart';
import 'package:blocky/game/game_config.dart';
import 'package:blocky/scene/blocky_scene.dart';
import 'package:flutter/material.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final BlockyGameController _gameController;

  @override
  void initState() {
    super.initState();
    _gameController = BlockyGameController();
    _gameController.addListener(_onGameStateChanged);
  }

  @override
  void dispose() {
    _gameController.removeListener(_onGameStateChanged);
    _gameController.dispose();
    super.dispose();
  }

  void _onGameStateChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GameConfig.backgroundColor,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _gameController.stopMovingBlock(),
        child: Stack(
          fit: StackFit.expand,
          children: [
            BlockyScene(gameController: _gameController),
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
          ],
        ),
      ),
    );
  }
}
