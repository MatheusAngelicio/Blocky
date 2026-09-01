import 'package:blocky/app/arcade_design_system.dart';
import 'package:blocky/ui/home_screen.dart';
import 'package:flutter/material.dart';

class BlockyApp extends StatelessWidget {
  const BlockyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Blocky',
      theme: ArcadeTheme.dark(),
      home: const HomeScreen(),
    );
  }
}
