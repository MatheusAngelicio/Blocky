import 'package:blocky/game/block_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Guarda somente o último tema visual escolhido pelo jogador.
class BlockThemeStorage {
  BlockThemeStorage({SharedPreferencesAsync? preferences})
    : _preferences = preferences;

  static const _selectedThemeKey = 'selected_block_theme';

  SharedPreferencesAsync? _preferences;

  SharedPreferencesAsync get _activePreferences =>
      _preferences ??= SharedPreferencesAsync();

  Future<BlockTheme> load() async {
    try {
      final savedTheme = await _activePreferences.getString(_selectedThemeKey);
      return BlockTheme.values.asNameMap()[savedTheme] ?? BlockTheme.jelly;
    } catch (_) {
      return BlockTheme.jelly;
    }
  }

  Future<void> save(BlockTheme theme) async {
    try {
      await _activePreferences.setString(_selectedThemeKey, theme.name);
    } catch (_) {
      // Falhas de persistência não devem impedir a seleção do tema atual.
    }
  }
}
