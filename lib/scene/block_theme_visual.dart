import 'dart:math' as math;

import 'package:blocky/game/block_color_palette.dart';
import 'package:blocky/game/block_theme.dart';
import 'package:blocky/game/game_config.dart';
import 'package:blocky/game/game_sound.dart';
import 'package:flutter_scene/scene.dart';
import 'package:vector_math/vector_math.dart' as vm;

enum BlockImpactMotion { standard, squashAndStretch }

/// Define uma sequência de cores próxima entre blocos da mesma partida.
class BlockColorProgression {
  const BlockColorProgression({
    required this.hueStep,
    required this.saturation,
    required this.value,
  });

  final double hueStep;
  final double saturation;
  final double value;
}

/// Parâmetros visuais de um impacto de posicionamento.
class BlockImpactVisual {
  const BlockImpactVisual({
    required this.motion,
    required this.duration,
    required this.horizontalScale,
    required this.verticalScale,
    required this.reboundHorizontalScale,
    required this.reboundVerticalScale,
  });

  final BlockImpactMotion motion;
  final Duration duration;
  final double horizontalScale;
  final double verticalScale;
  final double reboundHorizontalScale;
  final double reboundVerticalScale;
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

/// Oscilação visual aplicada a pedaços de bloco durante a queda.
class BlockFallingVisual {
  const BlockFallingVisual({
    required this.wobbleAmplitude,
    required this.wobbleFrequency,
  });

  final double wobbleAmplitude;
  final double wobbleFrequency;
}

/// Balanço visual aplicado a um bloco recém-posicionado com `Perfect`.
///
/// Não representa uma transformação lógica do bloco: serve apenas para dar
/// personalidade ao tema durante o breve feedback de acerto.
class BlockPerfectWobbleVisual {
  const BlockPerfectWobbleVisual({
    required this.duration,
    required this.translationAmplitude,
    required this.rotationAmplitude,
  });

  final Duration duration;
  final double translationAmplitude;
  final double rotationAmplitude;
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
    required this.fallingVisual,
    required this.perfectWobble,
    required this.recoveryGrowthOvershoot,
    required this.sounds,
    required this.colorProgression,
    required this.metallicFactor,
    required this.roughnessFactor,
    required this.materialAlpha,
    required this.transmission,
  });

  static const classic = BlockThemeVisual(
    theme: BlockTheme.classic,
    placementImpact: BlockImpactVisual(
      motion: BlockImpactMotion.standard,
      duration: GameConfig.placementImpactDuration,
      horizontalScale: GameConfig.placementImpactHorizontalScale,
      verticalScale: GameConfig.placementImpactVerticalScale,
      reboundHorizontalScale: 0.0,
      reboundVerticalScale: 0.0,
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
    fallingVisual: BlockFallingVisual(
      wobbleAmplitude: 0.0,
      wobbleFrequency: 0.0,
    ),
    perfectWobble: BlockPerfectWobbleVisual(
      duration: Duration.zero,
      translationAmplitude: 0.0,
      rotationAmplitude: 0.0,
    ),
    recoveryGrowthOvershoot: 0.0,
    sounds: BlockThemeSounds(
      placement: GameSound.placement,
      cut: GameSound.cut,
      perfect: GameSound.perfect,
      perfectRecovery: GameSound.perfectRecovery,
      gameOver: GameSound.gameOver,
    ),
    colorProgression: BlockColorProgression(
      hueStep: 8.0,
      saturation: 0.66,
      value: 0.92,
    ),
    metallicFactor: 0.05,
    roughnessFactor: 0.65,
    materialAlpha: 1.0,
    transmission: 0.0,
  );

  static const jelly = BlockThemeVisual(
    theme: BlockTheme.jelly,
    placementImpact: BlockImpactVisual(
      motion: BlockImpactMotion.squashAndStretch,
      duration: Duration(milliseconds: 180),
      horizontalScale: 0.045,
      verticalScale: 0.1,
      reboundHorizontalScale: 0.02,
      reboundVerticalScale: 0.04,
    ),
    perfectParticles: BlockParticleVisual(
      count: 13,
      lifetime: 0.52,
      effectDuration: Duration(milliseconds: 620),
      emitterRadius: 0.5,
      minimumSpeed: 0.6,
      maximumSpeed: 1.25,
      minimumSize: 0.04,
      maximumSize: 0.08,
      gravity: GameConfig.perfectParticleGravity,
    ),
    perfectRecoveryParticles: BlockParticleVisual(
      count: 22,
      lifetime: 0.62,
      effectDuration: Duration(milliseconds: 720),
      emitterRadius: 0.68,
      minimumSpeed: 0.85,
      maximumSpeed: 1.7,
      minimumSize: 0.05,
      maximumSize: 0.1,
      gravity: GameConfig.perfectParticleGravity,
    ),
    fallingVisual: BlockFallingVisual(
      wobbleAmplitude: 0.045,
      wobbleFrequency: 15.0,
    ),
    perfectWobble: BlockPerfectWobbleVisual(
      duration: Duration(milliseconds: 440),
      translationAmplitude: 0.1,
      rotationAmplitude: 0.075,
    ),
    recoveryGrowthOvershoot: 0.06,
    sounds: BlockThemeSounds(
      placement: GameSound.placement,
      cut: GameSound.cut,
      perfect: GameSound.perfect,
      perfectRecovery: GameSound.perfectRecovery,
      gameOver: GameSound.gameOver,
    ),
    colorProgression: BlockColorProgression(
      hueStep: 6.0,
      saturation: 0.38,
      value: 0.98,
    ),
    metallicFactor: 0.05,
    roughnessFactor: 0.65,
    // Mantém a sensação translúcida através de cores pastel, mas permanece
    // opaco para preservar a ordenação de profundidade entre os blocos.
    materialAlpha: 1.0,
    transmission: 0.0,
  );

  final BlockTheme theme;
  final BlockImpactVisual placementImpact;
  final BlockParticleVisual perfectParticles;
  final BlockParticleVisual perfectRecoveryParticles;
  final BlockFallingVisual fallingVisual;
  final BlockPerfectWobbleVisual perfectWobble;
  final double recoveryGrowthOvershoot;
  final BlockThemeSounds sounds;
  final BlockColorProgression colorProgression;
  final double metallicFactor;
  final double roughnessFactor;
  final double materialAlpha;
  final double transmission;

  static BlockThemeVisual forTheme(BlockTheme theme) => switch (theme) {
    BlockTheme.classic => classic,
    BlockTheme.jelly => jelly,
  };

  PhysicallyBasedMaterial createBlockMaterial({
    required int colorIndex,
    required double initialHue,
  }) {
    // Temas futuros podem configurar texturas e outros parâmetros do material
    // neste ponto, sem modificar as regras da partida.
    return PhysicallyBasedMaterial()
      ..baseColorFactor = blockColor(
        colorIndex,
        initialHue: initialHue,
        alpha: materialAlpha,
      )
      ..metallicFactor = metallicFactor
      ..roughnessFactor = roughnessFactor
      ..alphaMode = materialAlpha < 1.0 ? AlphaMode.blend : AlphaMode.opaque
      ..transmission = transmission
      ..ior = 1.33;
  }

  vm.Vector4 blockColor(
    int colorIndex, {
    required double initialHue,
    double alpha = 1.0,
  }) {
    final color = BlockColorPalette.colorForBlock(
      colorIndex,
      initialHue: initialHue,
      hueStep: colorProgression.hueStep,
      saturation: colorProgression.saturation,
      value: colorProgression.value,
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
