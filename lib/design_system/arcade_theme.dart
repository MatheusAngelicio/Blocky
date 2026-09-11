import 'package:blocky/design_system/arcade_colors.dart';
import 'package:blocky/design_system/arcade_typography.dart';
import 'package:flutter/material.dart';

abstract final class ArcadeTheme {
  static ThemeData dark() {
    const colorScheme = ColorScheme.dark(
      primary: ArcadeColors.primary,
      secondary: ArcadeColors.secondary,
      surface: ArcadeColors.elevatedSurface,
      onPrimary: ArcadeColors.ink,
      onSecondary: ArcadeColors.ink,
      onSurface: ArcadeColors.white,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: ArcadeTypography.fontFamily,
      textTheme: ArcadeTypography.textTheme,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: ArcadeColors.canvas,
      splashColor: ArcadeColors.white.withValues(alpha: 0.08),
      highlightColor: ArcadeColors.transparent,
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: ArcadeColors.elevatedSurface,
        modalBackgroundColor: ArcadeColors.elevatedSurface,
        shape: RoundedRectangleBorder(),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: const RoundedRectangleBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: ArcadeTypography.button,
        ),
      ),
    );
  }
}
