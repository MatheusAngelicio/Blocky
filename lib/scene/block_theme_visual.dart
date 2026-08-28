import 'dart:math' as math;

import 'package:blocky/game/block_color_palette.dart';
import 'package:blocky/game/block_theme.dart';
import 'package:blocky/game/game_config.dart';
import 'package:blocky/game/game_sound.dart';
import 'package:flutter_scene/scene.dart';
import 'package:vector_math/vector_math.dart' as vm;

/// Parâmetros visuais de um impacto de posicionamento.
class BlockImpactVisual {
  const BlockImpactVisual({
    required this.duration,
    required this.horizontalScale,
    required this.verticalScale,
  });

  final Duration duration;
  final double horizontalScale;
  final double verticalScale;
}

/// Parâmetros visuais de uma emissão curta de partículas.
class BlockParticleVisual {
  const BlockParticleVisual({
    required this.count,
    required this.lifetime,
    required this.effectDuration,
    required this.emitterRadius,
    required this.minimumSpeed,
    required this.maximumSpeed,
    required this.minimumSize,
    required this.maximumSize,
    required this.gravity,
  });

  final int count;
  final double lifetime;
  final Duration effectDuration;
  final double emitterRadius;
  final double minimumSpeed;
  final double maximumSpeed;
  final double minimumSize;
  final double maximumSize;
  final double gravity;
}

/// Sons associados aos eventos de um estilo de bloco.
class BlockThemeSounds {
  const BlockThemeSounds({
    required this.placement,
    required this.cut,
    required this.perfect,
    required this.perfectRecovery,
    required this.gameOver,
  });

  final GameSound placement;
  final GameSound cut;
  final GameSound perfect;
  final GameSound perfectRecovery;
  final GameSound gameOver;
}

/// Implementação visual de um [BlockTheme] para a cena 3D.
///
/// Novos temas podem variar material, textura, impacto, partículas e sons sem
/// introduzir regras de posicionamento ou pontuação nesta camada.
class BlockThemeVisual {
  const BlockThemeVisual({
    required this.theme,
    required this.placementImpact,
    required this.perfectParticles,
    required this.perfectRecoveryParticles,
    required this.sounds,
  });

  static const classic = BlockThemeVisual(
    theme: BlockTheme.classic,
    placementImpact: BlockImpactVisual(
      duration: GameConfig.placementImpactDuration,
      horizontalScale: GameConfig.placementImpactHorizontalScale,
      verticalScale: GameConfig.placementImpactVerticalScale,
    ),
    perfectParticles: BlockParticleVisual(
      count: GameConfig.perfectParticleCount,
      lifetime: GameConfig.perfectParticleLifetime,
      effectDuration: GameConfig.perfectParticleEffectDuration,
      emitterRadius: GameConfig.perfectParticleEmitterRadius,
      minimumSpeed: GameConfig.perfectParticleMinimumSpeed,
      maximumSpeed: GameConfig.perfectParticleMaximumSpeed,
      minimumSize: GameConfig.perfectParticleMinimumSize,
      maximumSize: GameConfig.perfectParticleMaximumSize,
      gravity: GameConfig.perfectParticleGravity,
    ),
    perfectRecoveryParticles: BlockParticleVisual(
      count: GameConfig.perfectRecoveryParticleCount,
      lifetime: GameConfig.perfectRecoveryParticleLifetime,
      effectDuration: GameConfig.perfectRecoveryParticleEffectDuration,
      emitterRadius: GameConfig.perfectRecoveryParticleEmitterRadius,
      minimumSpeed: GameConfig.perfectRecoveryParticleMinimumSpeed,
      maximumSpeed: GameConfig.perfectRecoveryParticleMaximumSpeed,
      minimumSize: GameConfig.perfectRecoveryParticleMinimumSize,
      maximumSize: GameConfig.perfectRecoveryParticleMaximumSize,
      gravity: GameConfig.perfectParticleGravity,
    ),
    sounds: BlockThemeSounds(
      placement: GameSound.placement,
      cut: GameSound.cut,
      perfect: GameSound.perfect,
      perfectRecovery: GameSound.perfectRecovery,
      gameOver: GameSound.gameOver,
    ),
  );

  final BlockTheme theme;
  final BlockImpactVisual placementImpact;
  final BlockParticleVisual perfectParticles;
  final BlockParticleVisual perfectRecoveryParticles;
  final BlockThemeSounds sounds;

  static BlockThemeVisual forTheme(BlockTheme theme) => switch (theme) {
    BlockTheme.classic => classic,
  };

  PhysicallyBasedMaterial createBlockMaterial({
    required int colorIndex,
    required double initialHue,
  }) {
    // Temas futuros podem configurar texturas e outros parâmetros do material
    // neste ponto, sem modificar as regras da partida.
    return PhysicallyBasedMaterial()
      ..baseColorFactor = blockColor(colorIndex, initialHue: initialHue)
      ..metallicFactor = 0.05
      ..roughnessFactor = 0.65;
  }

  vm.Vector4 blockColor(
    int colorIndex, {
    required double initialHue,
    double alpha = 1.0,
  }) {
    final color = BlockColorPalette.colorForBlock(
      colorIndex,
      initialHue: initialHue,
    );

    return vm.Vector4(
      _sRgbToLinear(color.r),
      _sRgbToLinear(color.g),
      _sRgbToLinear(color.b),
      alpha,
    );
  }

  static double _sRgbToLinear(double value) {
    if (value <= 0.04045) return value / 12.92;

    return math.pow((value + 0.055) / 1.055, 2.4).toDouble();
  }
}
