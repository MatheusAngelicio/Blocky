import 'dart:math' as math;

import 'package:blocky/game/block_theme.dart';
import 'package:flutter_scene/scene.dart';
import 'package:vector_math/vector_math.dart' as vm;

/// Paleta contínua que comunica a altura da torre sem criar cenários extras.
abstract final class SkyProgression {
  static const _scoreToReachNight = 80;

  static final _variations = <SkyProgressionVariation>[
    SkyProgressionVariation('balanced', vm.Vector3(1.0, 1.0, 1.0)),
    SkyProgressionVariation('solar', vm.Vector3(1.36, 0.76, 0.42)),
    SkyProgressionVariation('ocean', vm.Vector3(0.5, 0.9, 1.52)),
    SkyProgressionVariation('violet', vm.Vector3(0.72, 0.46, 1.54)),
    SkyProgressionVariation('rose', vm.Vector3(1.34, 0.5, 1.04)),
  ];

  static final _stops = <_SkyStop>[
    _SkyStop(
      0.0,
      SkyPalette(
        zenith: vm.Vector3(0.34, 0.73, 0.52),
        horizon: vm.Vector3(0.48, 0.80, 0.48),
        ground: vm.Vector3(0.62, 0.86, 0.36),
        sun: vm.Vector3(1.5, 1.4, 1.1),
      ),
    ),
    _SkyStop(
      0.22,
      SkyPalette(
        zenith: vm.Vector3(0.72, 0.50, 0.28),
        horizon: vm.Vector3(0.98, 0.69, 0.34),
        ground: vm.Vector3(0.74, 0.50, 0.25),
        sun: vm.Vector3(1.8, 1.15, 0.72),
      ),
    ),
    _SkyStop(
      0.45,
      SkyPalette(
        zenith: vm.Vector3(0.68, 0.22, 0.31),
        horizon: vm.Vector3(1.0, 0.40, 0.24),
        ground: vm.Vector3(0.42, 0.15, 0.19),
        sun: vm.Vector3(1.7, 0.56, 0.35),
      ),
    ),
    _SkyStop(
      0.65,
      SkyPalette(
        zenith: vm.Vector3(0.26, 0.10, 0.42),
        horizon: vm.Vector3(0.48, 0.20, 0.57),
        ground: vm.Vector3(0.18, 0.07, 0.27),
        sun: vm.Vector3(0.68, 0.34, 0.9),
      ),
    ),
    _SkyStop(
      0.82,
      SkyPalette(
        zenith: vm.Vector3(0.04, 0.09, 0.28),
        horizon: vm.Vector3(0.12, 0.20, 0.44),
        ground: vm.Vector3(0.03, 0.05, 0.13),
        sun: vm.Vector3(0.2, 0.32, 0.72),
      ),
    ),
    _SkyStop(
      1.0,
      SkyPalette(
        zenith: vm.Vector3(0.008, 0.015, 0.06),
        horizon: vm.Vector3(0.025, 0.045, 0.12),
        ground: vm.Vector3(0.005, 0.008, 0.02),
        sun: vm.Vector3(0.04, 0.06, 0.16),
      ),
    ),
  ];

  /// Escolhe uma atmosfera perceptivelmente diferente para cada partida.
  ///
  /// A variação anterior é excluída para que um restart não reapresente a
  /// mesma cor de fundo na mesma sessão.
  static SkyProgressionVariation randomVariation(
    math.Random random, {
    SkyProgressionVariation? previous,
  }) {
    if (previous == null) {
      return _variations[random.nextInt(_variations.length)];
    }

    final previousIndex = _variations.indexOf(previous);
    if (previousIndex < 0) {
      return _variations[random.nextInt(_variations.length)];
    }
    var index = random.nextInt(_variations.length - 1);
    if (index >= previousIndex) index++;
    return _variations[index];
  }

  static SkyPalette paletteForScore(
    int score, {
    BlockTheme theme = BlockTheme.classic,
    SkyProgressionVariation? variation,
  }) {
    final progress = (score / _scoreToReachNight).clamp(0.0, 1.0).toDouble();
    final upperIndex = _stops.indexWhere((stop) => stop.progress >= progress);
    if (upperIndex <= 0) {
      return _applyTheme(
        _stops.first.palette,
        theme: theme,
        variation: variation,
      );
    }

    final from = _stops[upperIndex - 1];
    final to = _stops[upperIndex];
    final segmentProgress =
        ((progress - from.progress) / (to.progress - from.progress))
            .clamp(0.0, 1.0)
            .toDouble();
    return _applyTheme(
      SkyPalette.lerp(from.palette, to.palette, segmentProgress),
      theme: theme,
      variation: variation,
    );
  }

  static void applyTo(
    GradientSkySource sky,
    int score, {
    BlockTheme theme = BlockTheme.classic,
    SkyProgressionVariation? variation,
  }) {
    final palette = paletteForScore(score, theme: theme, variation: variation);
    sky.zenithColor = palette.zenith;
    sky.horizonColor = palette.horizon;
    sky.groundColor = palette.ground;
    sky.sunColor = palette.sun;
  }

  static SkyPalette _applyTheme(
    SkyPalette palette, {
    required BlockTheme theme,
    required SkyProgressionVariation? variation,
  }) {
    final profile = SkyThemeProfile.forTheme(theme);
    return palette
        .blend(profile.atmosphere, profile.atmosphereStrength)
        .withVariation(variation);
  }
}

/// Assinatura cromática do cenário de um tema, sem introduzir cenário 3D.
///
/// O céu continua progredindo com a altura da torre; este perfil apenas leva
/// cada uma das quatro cores para uma atmosfera que combina com os blocos.
class SkyThemeProfile {
  const SkyThemeProfile({
    required this.atmosphere,
    required this.atmosphereStrength,
    required this.starColor,
    required this.minimumStarVisibility,
  });

  static final classic = SkyThemeProfile(
    atmosphere: SkyPalette(
      zenith: vm.Vector3(0.0, 0.0, 0.0),
      horizon: vm.Vector3(0.0, 0.0, 0.0),
      ground: vm.Vector3(0.0, 0.0, 0.0),
      sun: vm.Vector3(0.0, 0.0, 0.0),
    ),
    atmosphereStrength: 0.0,
    starColor: vm.Vector3(1.0, 0.96, 0.82),
    minimumStarVisibility: 0.0,
  );

  static final jelly = SkyThemeProfile(
    atmosphere: SkyPalette(
      zenith: vm.Vector3(0.38, 0.34, 0.72),
      horizon: vm.Vector3(0.94, 0.55, 0.82),
      ground: vm.Vector3(0.3, 0.2, 0.5),
      sun: vm.Vector3(1.25, 0.95, 1.45),
    ),
    atmosphereStrength: 0.34,
    starColor: vm.Vector3(0.85, 0.7, 1.0),
    minimumStarVisibility: 0.06,
  );

  static final chocolate = SkyThemeProfile(
    atmosphere: SkyPalette(
      zenith: vm.Vector3(0.16, 0.045, 0.025),
      horizon: vm.Vector3(0.56, 0.17, 0.045),
      ground: vm.Vector3(0.12, 0.025, 0.012),
      sun: vm.Vector3(1.45, 0.48, 0.12),
    ),
    atmosphereStrength: 0.5,
    starColor: vm.Vector3(1.0, 0.64, 0.28),
    minimumStarVisibility: 0.02,
  );

  static final cheese = SkyThemeProfile(
    atmosphere: SkyPalette(
      zenith: vm.Vector3(0.28, 0.72, 0.55),
      horizon: vm.Vector3(1.0, 0.78, 0.18),
      ground: vm.Vector3(0.52, 0.55, 0.12),
      sun: vm.Vector3(1.55, 1.2, 0.42),
    ),
    atmosphereStrength: 0.4,
    starColor: vm.Vector3(1.0, 0.87, 0.34),
    minimumStarVisibility: 0.0,
  );

  static final neon = SkyThemeProfile(
    atmosphere: SkyPalette(
      zenith: vm.Vector3(0.012, 0.018, 0.11),
      horizon: vm.Vector3(0.22, 0.015, 0.38),
      ground: vm.Vector3(0.006, 0.004, 0.035),
      sun: vm.Vector3(0.42, 0.06, 0.85),
    ),
    atmosphereStrength: 0.9,
    starColor: vm.Vector3(0.12, 0.86, 1.0),
    minimumStarVisibility: 0.48,
  );

  final SkyPalette atmosphere;
  final double atmosphereStrength;
  final vm.Vector3 starColor;
  final double minimumStarVisibility;

  static SkyThemeProfile forTheme(BlockTheme theme) => switch (theme) {
    BlockTheme.classic => classic,
    BlockTheme.jelly => jelly,
    BlockTheme.chocolate => chocolate,
    BlockTheme.cheese => cheese,
    BlockTheme.neon => neon,
  };
}

class SkyPalette {
  const SkyPalette({
    required this.zenith,
    required this.horizon,
    required this.ground,
    required this.sun,
  });

  final vm.Vector3 zenith;
  final vm.Vector3 horizon;
  final vm.Vector3 ground;
  final vm.Vector3 sun;

  static SkyPalette lerp(SkyPalette from, SkyPalette to, double progress) {
    vm.Vector3 blend(vm.Vector3 start, vm.Vector3 end) =>
        start + (end - start) * progress;

    return SkyPalette(
      zenith: blend(from.zenith, to.zenith),
      horizon: blend(from.horizon, to.horizon),
      ground: blend(from.ground, to.ground),
      sun: blend(from.sun, to.sun),
    );
  }

  SkyPalette blend(SkyPalette target, double progress) {
    return lerp(this, target, progress);
  }

  SkyPalette withVariation(SkyProgressionVariation? variation) {
    if (variation == null) return this;
    return SkyPalette(
      zenith: _applyScale(zenith, variation.colorScale),
      horizon: _applyScale(horizon, variation.colorScale),
      ground: _applyScale(ground, variation.colorScale),
      sun: _applyScale(sun, variation.colorScale),
    );
  }

  static vm.Vector3 _applyScale(vm.Vector3 color, vm.Vector3 scale) {
    return vm.Vector3(color.x * scale.x, color.y * scale.y, color.z * scale.z);
  }
}

/// Mantém a sequência de altitude intacta, alterando sua atmosfera por rodada.
class SkyProgressionVariation {
  SkyProgressionVariation(this.name, this.colorScale);

  final vm.Vector3 colorScale;
  final String name;
}

class _SkyStop {
  const _SkyStop(this.progress, this.palette);

  final double progress;
  final SkyPalette palette;
}
