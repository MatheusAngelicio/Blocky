/// Configuration that changes how the app starts without affecting gameplay.
abstract final class AppConfiguration {
  /// Makes every block theme available for this execution only.
  static const unlockAllThemes = bool.fromEnvironment(
    'UNLOCK_ALL_THEMES',
    defaultValue: false,
  );
}
