import 'package:flutter/material.dart';

/// Semantic color tokens shared by every game in the arcade collection.
///
/// Game-specific palettes live next to their game instead of being added here.
abstract final class ArcadeColors {
  static const canvasTop = Color(0xFF3C2A63);
  static const canvas = Color(0xFF171323);
  static const surface = Color(0xFF282341);
  static const elevatedSurface = Color(0xFF211D32);
  static const hudSurface = Color(0xE8282341);
  static const scrim = Color(0xD6151225);

  static const primary = Color(0xFFFFD65C);
  static const secondary = Color(0xFF7CE5A2);
  static const success = Color(0xFF8EE8C5);
  static const outline = Color(0xFF655B84);
  static const strongOutline = Color(0xFF8D82BB);

  static const ink = Color(0xFF171323);
  static const shadow = Color(0xFF080611);
  static const muted = Color(0xFFBDB5D7);
  static const softText = Color(0xFFCEC5E7);
  static const titleShadow = Color(0xFF6E4A1C);
  static const disabled = Color(0xFF615C72);

  static const white = Colors.white;
  static const black = Colors.black;
  static const transparent = Colors.transparent;
}
