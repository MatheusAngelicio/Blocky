import 'package:shared_preferences/shared_preferences.dart';

/// Armazena o saldo total de Blocky Coins do jogador neste dispositivo.
class BlockyCoinStorage {
  BlockyCoinStorage({SharedPreferencesAsync? preferences})
    : _preferences = preferences;

  static const _blockyCoinsKey = 'blocky_coins';

  SharedPreferencesAsync? _preferences;

  SharedPreferencesAsync get _activePreferences =>
      _preferences ??= SharedPreferencesAsync();

  Future<int> load() async {
    try {
      return await _activePreferences.getInt(_blockyCoinsKey) ?? 0;
    } catch (_) {
      return 0;
    }
  }

  Future<void> save(int coins) async {
    try {
      await _activePreferences.setInt(_blockyCoinsKey, coins);
    } catch (_) {
      // Falhas de persistência não devem interromper uma partida em andamento.
    }
  }
}
