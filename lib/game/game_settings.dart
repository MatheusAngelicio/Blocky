/// Idioma escolhido pelo jogador, ou o idioma definido pelo dispositivo.
enum AppLanguage { system, english, portuguese }

/// Preferências locais que afetam a apresentação da partida, não suas regras.
class GameSettings {
  const GameSettings({
    this.soundVolume = defaultSoundVolume,
    this.hapticsEnabled = true,
    this.language = AppLanguage.system,
    this.cameraAngle = 0.0,
  }) : assert(soundVolume >= 0 && soundVolume <= 1),
       assert(cameraAngle >= -1 && cameraAngle <= 1);

  static const defaultSoundVolume = 1.0;

  final double soundVolume;
  final bool hapticsEnabled;
  final AppLanguage language;
  final double cameraAngle;

  GameSettings copyWith({
    double? soundVolume,
    bool? hapticsEnabled,
    AppLanguage? language,
    double? cameraAngle,
  }) {
    return GameSettings(
      soundVolume: soundVolume ?? this.soundVolume,
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
      language: language ?? this.language,
      cameraAngle: cameraAngle ?? this.cameraAngle,
    );
  }
}
