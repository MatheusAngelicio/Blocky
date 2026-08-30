import 'package:blocky/app/blocky_colors.dart';
import 'package:blocky/app/blocky_arcade.dart';
import 'package:blocky/ui/home_screen.dart';
import 'package:flutter/material.dart';

class BlockyApp extends StatelessWidget {
  const BlockyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Blocky',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        fontFamily: BlockyTypography.fontFamily,
        colorScheme: const ColorScheme.dark(
          primary: BlockyColors.primary,
          secondary: BlockyColors.secondary,
          surface: BlockyColors.modalSurface,
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            shape: const RoundedRectangleBorder(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            textStyle: BlockyTypography.button,
          ),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
