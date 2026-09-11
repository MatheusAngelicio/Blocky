import 'package:blocky/game/block_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Guarda os temas de bloco adquiridos neste dispositivo.
class BlockThemeUnlockStorage {
  BlockThemeUnlockStorage({SharedPreferencesAsync? preferences})
    : _preferences = preferences;

  static const _unlockedThemesKey = 'unlocked_block_themes';

  SharedPreferencesAsync? _preferences;

  SharedPreferencesAsync get _activePreferences =>
      _preferences ??= SharedPreferencesAsync();

  Future<Set<BlockTheme>> load() async {
    try {
      final names = await _activePreferences.getStringList(_unlockedThemesKey);
      final themesByName = BlockTheme.values.asNameMap();
      final unlockedThemes =
          names
              ?.map((name) => themesByName[name])
              .whereType<BlockTheme>()
              .toSet() ??
          <BlockTheme>{};
      return {...unlockedThemes, BlockTheme.classic};
    } catch (_) {
      return {BlockTheme.classic};
    }
  }

  Future<void> save(Set<BlockTheme> themes) async {
    try {
      final names = BlockTheme.values
          .where(themes.contains)
          .map((theme) => theme.name)
          .toList();
      await _activePreferences.setStringList(_unlockedThemesKey, names);
    } catch (_) {
      // Desbloqueios são opcionais e não devem interromper a navegação.
    }
  }
}
