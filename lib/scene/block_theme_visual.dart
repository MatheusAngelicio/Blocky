import 'dart:math' as math;

import 'package:blocky/game/block_color_palette.dart';
import 'package:blocky/game/block_theme.dart';
import 'package:blocky/game/game_config.dart';
import 'package:blocky/game/game_sound.dart';
import 'package:flutter_scene/scene.dart';
import 'package:vector_math/vector_math.dart' as vm;

enum BlockImpactMotion {
  standard,
  squashAndStretch,
  firmSettle,
  neonPulse,
  brickLock,
}

/// Detalhes geométricos leves adicionados sobre o paralelepípedo lógico.
///
/// Eles são recriados quando um bloco é cortado, mantendo a regra e o
/// collider do jogo sempre como uma caixa simples.
enum BlockSurfaceDetail {
  none,
  classicTopSheen,
  jellyTopHighlight,
  cheeseHoles,
  chocolateSegments,
  neonStrips,
  brickStuds,
}

/// Define uma sequência de cores próxima entre blocos da mesma partida.
class BlockColorProgression {
  const BlockColorProgression({
    required this.hueStep,
    required this.saturation,
    required this.value,
    this.initialHueStart,
    this.initialHueRange = 0.0,
    this.hueCycleRange,
    this.saturationVariation = 0.0,
    this.valueVariation = 0.0,
    this.variationFrequency = 0.0,
  });

  final double hueStep;
  final double saturation;
  final double value;
  final double? initialHueStart;
  final double initialHueRange;
  final double? hueCycleRange;
  final double saturationVariation;
  final double valueVariation;
  final double variationFrequency;

  double hueForBlock(int index, double randomHue) {
    final start = initialHueStart;
    if (start == null) return randomHue + index * hueStep;

    final randomOffset = randomHue / 360.0 * initialHueRange;
    final cycleRange = hueCycleRange;
    if (cycleRange == null) {
      return start + randomOffset + index * hueStep;
    }

    return start + (randomOffset + index * hueStep) % cycleRange;
  }

  double saturationForBlock(int index, double randomHue) {
    return (saturation + _variation(index, randomHue) * saturationVariation)
        .clamp(0.0, 1.0)
        .toDouble();
  }

  double valueForBlock(int index, double randomHue) {
    return (value + _variation(index, randomHue) * valueVariation)
        .clamp(0.0, 1.0)
        .toDouble();
  }

  double _variation(int index, double randomHue) {
    if (variationFrequency == 0.0) return 0.0;

    return math.sin(
      randomHue / 360.0 * math.pi * 2 + index * variationFrequency,
    );
  }
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
    required this.surfaceDetail,
    required this.placementImpact,
    required this.perfectParticles,
    required this.perfectRecoveryParticles,
    required this.cutParticles,
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
    surfaceDetail: BlockSurfaceDetail.classicTopSheen,
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
    cutParticles: null,
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
    surfaceDetail: BlockSurfaceDetail.jellyTopHighlight,
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
    cutParticles: null,
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

  static const chocolate = BlockThemeVisual(
    theme: BlockTheme.chocolate,
    surfaceDetail: BlockSurfaceDetail.chocolateSegments,
    placementImpact: BlockImpactVisual(
      motion: BlockImpactMotion.firmSettle,
      duration: Duration(milliseconds: 105),
      horizontalScale: 0.014,
      verticalScale: 0.035,
      reboundHorizontalScale: 0.006,
      reboundVerticalScale: 0.012,
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
    cutParticles: BlockParticleVisual(
      count: 14,
      lifetime: 0.5,
      effectDuration: Duration(milliseconds: 560),
      emitterRadius: 0.1,
      minimumSpeed: 0.35,
      maximumSpeed: 0.9,
      minimumSize: 0.022,
      maximumSize: 0.052,
      gravity: 3.6,
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
      hueStep: 4.2,
      saturation: 0.48,
      value: 0.87,
      initialHueStart: 16.0,
      initialHueRange: 30.0,
      hueCycleRange: 30.0,
      saturationVariation: 0.16,
      valueVariation: 0.25,
      variationFrequency: 0.85,
    ),
    metallicFactor: 0.0,
    roughnessFactor: 0.42,
    materialAlpha: 1.0,
    transmission: 0.0,
  );

  static const cheese = BlockThemeVisual(
    theme: BlockTheme.cheese,
    surfaceDetail: BlockSurfaceDetail.cheeseHoles,
    placementImpact: BlockImpactVisual(
      motion: BlockImpactMotion.firmSettle,
      duration: Duration(milliseconds: 145),
      horizontalScale: 0.018,
      verticalScale: 0.048,
      reboundHorizontalScale: 0.009,
      reboundVerticalScale: 0.016,
    ),
    perfectParticles: BlockParticleVisual(
      count: 8,
      lifetime: 0.4,
      effectDuration: Duration(milliseconds: 470),
      emitterRadius: 0.38,
      minimumSpeed: 0.42,
      maximumSpeed: 0.9,
      minimumSize: 0.028,
      maximumSize: 0.058,
      gravity: 3.2,
    ),
    perfectRecoveryParticles: BlockParticleVisual(
      count: 15,
      lifetime: 0.5,
      effectDuration: Duration(milliseconds: 580),
      emitterRadius: 0.55,
      minimumSpeed: 0.62,
      maximumSpeed: 1.28,
      minimumSize: 0.035,
      maximumSize: 0.075,
      gravity: 3.4,
    ),
    cutParticles: BlockParticleVisual(
      count: 9,
      lifetime: 0.42,
      effectDuration: Duration(milliseconds: 480),
      emitterRadius: 0.08,
      minimumSpeed: 0.3,
      maximumSpeed: 0.72,
      minimumSize: 0.024,
      maximumSize: 0.05,
      gravity: 4.2,
    ),
    fallingVisual: BlockFallingVisual(
      wobbleAmplitude: 0.012,
      wobbleFrequency: 8.0,
    ),
    perfectWobble: BlockPerfectWobbleVisual(
      duration: Duration(milliseconds: 180),
      translationAmplitude: 0.022,
      rotationAmplitude: 0.018,
    ),
    recoveryGrowthOvershoot: 0.015,
    sounds: BlockThemeSounds(
      placement: GameSound.placement,
      cut: GameSound.cut,
      perfect: GameSound.perfect,
      perfectRecovery: GameSound.perfectRecovery,
      gameOver: GameSound.gameOver,
    ),
    colorProgression: BlockColorProgression(
      hueStep: 3.5,
      saturation: 0.69,
      value: 0.96,
      initialHueStart: 38.0,
      initialHueRange: 26.0,
      hueCycleRange: 26.0,
      saturationVariation: 0.08,
      valueVariation: 0.11,
      variationFrequency: 0.7,
    ),
    metallicFactor: 0.0,
    roughnessFactor: 0.76,
    materialAlpha: 1.0,
    transmission: 0.0,
  );

  /// Painel grafite polido, moldura rosa, base ciano e trilhas de circuito
  /// coloridas. O impacto propaga um pulso curto em vez de amassar o bloco.
  static const neon = BlockThemeVisual(
    theme: BlockTheme.neon,
    surfaceDetail: BlockSurfaceDetail.neonStrips,
    placementImpact: BlockImpactVisual(
      motion: BlockImpactMotion.neonPulse,
      duration: Duration(milliseconds: 135),
      horizontalScale: 0.032,
      verticalScale: 0.022,
      reboundHorizontalScale: 0.012,
      reboundVerticalScale: 0.008,
    ),
    perfectParticles: BlockParticleVisual(
      count: 7,
      lifetime: 0.36,
      effectDuration: Duration(milliseconds: 420),
      emitterRadius: 0.42,
      minimumSpeed: 0.6,
      maximumSpeed: 1.15,
      minimumSize: 0.022,
      maximumSize: 0.052,
      gravity: 2.4,
    ),
    perfectRecoveryParticles: BlockParticleVisual(
      count: 13,
      lifetime: 0.46,
      effectDuration: Duration(milliseconds: 530),
      emitterRadius: 0.58,
      minimumSpeed: 0.8,
      maximumSpeed: 1.45,
      minimumSize: 0.028,
      maximumSize: 0.064,
      gravity: 2.7,
    ),
    cutParticles: BlockParticleVisual(
      count: 7,
      lifetime: 0.34,
      effectDuration: Duration(milliseconds: 400),
      emitterRadius: 0.08,
      minimumSpeed: 0.38,
      maximumSpeed: 0.82,
      minimumSize: 0.018,
      maximumSize: 0.04,
      gravity: 3.8,
    ),
    fallingVisual: BlockFallingVisual(
      wobbleAmplitude: 0.02,
      wobbleFrequency: 12.0,
    ),
    perfectWobble: BlockPerfectWobbleVisual(
      duration: Duration(milliseconds: 230),
      translationAmplitude: 0.035,
      rotationAmplitude: 0.028,
    ),
    recoveryGrowthOvershoot: 0.025,
    sounds: BlockThemeSounds(
      placement: GameSound.placement,
      cut: GameSound.cut,
      perfect: GameSound.perfect,
      perfectRecovery: GameSound.perfectRecovery,
      gameOver: GameSound.gameOver,
    ),
    colorProgression: BlockColorProgression(
      hueStep: 17.0,
      saturation: 0.68,
      value: 0.3,
      initialHueStart: 198.0,
      initialHueRange: 105.0,
      hueCycleRange: 105.0,
      saturationVariation: 0.08,
      valueVariation: 0.08,
      variationFrequency: 0.9,
    ),
    metallicFactor: 0.72,
    roughnessFactor: 0.22,
    materialAlpha: 1.0,
    transmission: 0.0,
  );

  /// Plástico colorido e brilhante com studs regulares de peças de montar.
  /// O impacto comprime e trava brevemente, como uma peça sendo encaixada.
  static const lego = BlockThemeVisual(
    theme: BlockTheme.lego,
    surfaceDetail: BlockSurfaceDetail.brickStuds,
    placementImpact: BlockImpactVisual(
      motion: BlockImpactMotion.brickLock,
      duration: Duration(milliseconds: 115),
      horizontalScale: 0.012,
      verticalScale: 0.055,
      reboundHorizontalScale: 0.006,
      reboundVerticalScale: 0.018,
    ),
    perfectParticles: BlockParticleVisual(
      count: 8,
      lifetime: 0.38,
      effectDuration: Duration(milliseconds: 440),
      emitterRadius: 0.4,
      minimumSpeed: 0.46,
      maximumSpeed: 0.98,
      minimumSize: 0.026,
      maximumSize: 0.054,
      gravity: 3.1,
    ),
    perfectRecoveryParticles: BlockParticleVisual(
      count: 15,
      lifetime: 0.48,
      effectDuration: Duration(milliseconds: 550),
      emitterRadius: 0.56,
      minimumSpeed: 0.62,
      maximumSpeed: 1.26,
      minimumSize: 0.035,
      maximumSize: 0.07,
      gravity: 3.4,
    ),
    cutParticles: BlockParticleVisual(
      count: 8,
      lifetime: 0.38,
      effectDuration: Duration(milliseconds: 430),
      emitterRadius: 0.1,
      minimumSpeed: 0.32,
      maximumSpeed: 0.74,
      minimumSize: 0.022,
      maximumSize: 0.045,
      gravity: 4.0,
    ),
    fallingVisual: BlockFallingVisual(
      wobbleAmplitude: 0.008,
      wobbleFrequency: 8.0,
    ),
    perfectWobble: BlockPerfectWobbleVisual(
      duration: Duration(milliseconds: 160),
      translationAmplitude: 0.018,
      rotationAmplitude: 0.014,
    ),
    recoveryGrowthOvershoot: 0.012,
    sounds: BlockThemeSounds(
      placement: GameSound.placement,
      cut: GameSound.cut,
      perfect: GameSound.perfect,
      perfectRecovery: GameSound.perfectRecovery,
      gameOver: GameSound.gameOver,
    ),
    colorProgression: BlockColorProgression(
      hueStep: 44.0,
      saturation: 0.88,
      value: 0.94,
      initialHueStart: 0.0,
      initialHueRange: 14.0,
      hueCycleRange: 315.0,
      saturationVariation: 0.04,
      valueVariation: 0.05,
      variationFrequency: 0.72,
    ),
    metallicFactor: 0.0,
    roughnessFactor: 0.24,
    materialAlpha: 1.0,
    transmission: 0.0,
  );

  final BlockTheme theme;
  final BlockSurfaceDetail surfaceDetail;
  final BlockImpactVisual placementImpact;
  final BlockParticleVisual perfectParticles;
  final BlockParticleVisual perfectRecoveryParticles;
  final BlockParticleVisual? cutParticles;
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
    BlockTheme.chocolate => chocolate,
    BlockTheme.cheese => cheese,
    BlockTheme.neon => neon,
    BlockTheme.lego => lego,
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
      0,
      initialHue: colorProgression.hueForBlock(colorIndex, initialHue),
      saturation: colorProgression.saturationForBlock(colorIndex, initialHue),
      value: colorProgression.valueForBlock(colorIndex, initialHue),
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
