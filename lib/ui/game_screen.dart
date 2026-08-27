import 'package:blocky/game/game_config.dart';
import 'package:blocky/scene/blocky_scene.dart';
import 'package:flutter/material.dart';

class GameScreen extends StatelessWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: GameConfig.backgroundColor,
      body: SizedBox.expand(child: BlockyScene()),
    );
  }
}
