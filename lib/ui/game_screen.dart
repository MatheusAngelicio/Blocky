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
  }

  @override
  void dispose() {
    _gameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GameConfig.backgroundColor,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _gameController.stopMovingBlock(),
        child: SizedBox.expand(
          child: BlockyScene(gameController: _gameController),
        ),
      ),
    );
  }
}
