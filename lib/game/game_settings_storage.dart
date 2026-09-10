import 'package:blocky/game/game_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persiste as preferências locais de apresentação do jogador.
class GameSettingsStorage {
  GameSettingsStorage({SharedPreferencesAsync? preferences})
    : _preferences = preferences;

  static const _soundVolumeKey = 'sound_volume';
  static const _hapticsEnabledKey = 'haptics_enabled';
  static const _languageKey = 'app_language';
  static const _cameraAngleKey = 'camera_angle';

  SharedPreferencesAsync? _preferences;

  SharedPreferencesAsync get _activePreferences =>
      _preferences ??= SharedPreferencesAsync();

  Future<GameSettings> load() async {
    try {
      final volume = await _activePreferences.getDouble(_soundVolumeKey);
      final hapticsEnabled = await _activePreferences.getBool(
        _hapticsEnabledKey,
      );
      final languageName = await _activePreferences.getString(_languageKey);
      final cameraAngle = await _activePreferences.getDouble(_cameraAngleKey);
      return GameSettings(
        soundVolume: (volume ?? GameSettings.defaultSoundVolume)
            .clamp(0.0, 1.0)
            .toDouble(),
        hapticsEnabled: hapticsEnabled ?? true,
        language:
            AppLanguage.values.asNameMap()[languageName] ?? AppLanguage.system,
        cameraAngle: (cameraAngle ?? 0.0).clamp(-1.0, 1.0).toDouble(),
      );
    } catch (_) {
      return const GameSettings();
    }
  }

  Future<void> save(GameSettings settings) async {
    try {
      await Future.wait([
        _activePreferences.setDouble(_soundVolumeKey, settings.soundVolume),
        _activePreferences.setBool(_hapticsEnabledKey, settings.hapticsEnabled),
        _activePreferences.setString(_languageKey, settings.language.name),
        _activePreferences.setDouble(_cameraAngleKey, settings.cameraAngle),
      ]);
    } catch (_) {
      // Preferências são opcionais e não devem bloquear a navegação.
    }
  }
}
