/// Idioma escolhido pelo jogador, ou o idioma definido pelo dispositivo.
enum AppLanguage { system, english, portuguese }

/// Preferências locais que afetam a apresentação da partida, não suas regras.
class GameSettings {
  const GameSettings({
    this.soundVolume = defaultSoundVolume,
    this.hapticsEnabled = true,
    this.language = AppLanguage.system,
  }) : assert(soundVolume >= 0 && soundVolume <= 1);

  static const defaultSoundVolume = 1.0;

  final double soundVolume;
  final bool hapticsEnabled;
  final AppLanguage language;

  GameSettings copyWith({
    double? soundVolume,
    bool? hapticsEnabled,
    AppLanguage? language,
  }) {
    return GameSettings(
      soundVolume: soundVolume ?? this.soundVolume,
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
      language: language ?? this.language,
    );
  }
}
