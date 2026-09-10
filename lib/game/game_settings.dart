/// Preferências locais que afetam a apresentação da partida, não suas regras.
class GameSettings {
  const GameSettings({
    this.soundVolume = defaultSoundVolume,
    this.hapticsEnabled = true,
  }) : assert(soundVolume >= 0 && soundVolume <= 1);

  static const defaultSoundVolume = 1.0;

  final double soundVolume;
  final bool hapticsEnabled;

  GameSettings copyWith({double? soundVolume, bool? hapticsEnabled}) {
    return GameSettings(
      soundVolume: soundVolume ?? this.soundVolume,
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
    );
  }
}
