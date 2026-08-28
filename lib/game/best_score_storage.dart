import 'package:shared_preferences/shared_preferences.dart';

/// Armazena somente o recorde local da partida atual.
class BestScoreStorage {
  BestScoreStorage({SharedPreferencesAsync? preferences})
    : _preferences = preferences;

  static const _bestScoreKey = 'best_score';

  SharedPreferencesAsync? _preferences;

  SharedPreferencesAsync get _activePreferences =>
      _preferences ??= SharedPreferencesAsync();

  Future<int> load() async {
    try {
      return await _activePreferences.getInt(_bestScoreKey) ?? 0;
    } catch (_) {
      return 0;
    }
  }

  Future<void> save(int score) async {
    try {
      await _activePreferences.setInt(_bestScoreKey, score);
    } catch (_) {
      // Falhas de persistência não devem impedir o encerramento da partida.
    }
  }

  Future<int> saveIfHigher(int score) async {
    final storedScore = await load();
    final bestScore = score > storedScore ? score : storedScore;
    if (bestScore > storedScore) {
      await save(bestScore);
    }
    return bestScore;
  }
}
