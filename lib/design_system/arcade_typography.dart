import 'package:blocky/design_system/arcade_colors.dart';
import 'package:flutter/material.dart';

abstract final class ArcadeTypography {
  static const fontFamily = 'ArcadePixel';

  static const logo = TextStyle(
    color: ArcadeColors.primary,
    fontFamily: fontFamily,
    fontSize: 38,
    fontWeight: FontWeight.w900,
    letterSpacing: 3.2,
    height: 1.18,
    shadows: [Shadow(color: ArcadeColors.titleShadow, offset: Offset(3, 4))],
  );
  static const heading = TextStyle(
    color: ArcadeColors.white,
    fontFamily: fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w900,
    letterSpacing: 1.2,
    height: 1.45,
  );
  static const tagline = TextStyle(
    color: ArcadeColors.softText,
    fontFamily: fontFamily,
    fontSize: 10,
    fontWeight: FontWeight.w800,
    letterSpacing: 1.1,
    height: 1.45,
  );
  static const label = TextStyle(
    color: ArcadeColors.muted,
    fontFamily: fontFamily,
    fontSize: 9,
    fontWeight: FontWeight.w800,
    letterSpacing: 0.75,
    height: 1.45,
  );
  static const button = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w900,
    letterSpacing: 0.65,
    height: 1.35,
  );
  static const value = TextStyle(
    color: ArcadeColors.white,
    fontFamily: fontFamily,
    fontSize: 25,
    fontWeight: FontWeight.w900,
    letterSpacing: 0.75,
    height: 1.28,
  );

  static final textTheme = const TextTheme(
    displayLarge: logo,
    headlineMedium: heading,
    bodyMedium: tagline,
    labelLarge: button,
    labelMedium: label,
  );
}
