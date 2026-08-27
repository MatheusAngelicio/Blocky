import 'package:blocky/ui/game_screen.dart';
import 'package:flutter/material.dart';

class BlockyApp extends StatelessWidget {
  const BlockyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Blocky',
      theme: ThemeData.dark(useMaterial3: true),
      home: const GameScreen(),
    );
  }
}
