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
        fontFamily: 'monospace',
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFFD65C),
          secondary: Color(0xFF7CE5A2),
          surface: Color(0xFF211D32),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            shape: const RoundedRectangleBorder(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            textStyle: const TextStyle(
              fontFamily: 'monospace',
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
