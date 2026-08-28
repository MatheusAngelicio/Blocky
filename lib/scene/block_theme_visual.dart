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
    required this.baseColorTextureAsset,
    required this.textureTiling,
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
    baseColorTextureAsset: null,
    textureTiling: 1.0,
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
    baseColorTextureAsset: null,
    textureTiling: 1.0,
  );

  static const chocolate = BlockThemeVisual(
    theme: BlockTheme.chocolate,
    placementImpact: BlockImpactVisual(
      motion: BlockImpactMotion.standard,
      duration: GameConfig.placementImpactDuration,
      horizontalScale: 0.02,
      verticalScale: 0.05,
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
    baseColorTextureAsset: 'assets/images/chocolate_block_base_color_v2.png',
    textureTiling: 2.5,
  );

  final BlockTheme theme;
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
  final String? baseColorTextureAsset;
  final double textureTiling;

  static BlockThemeVisual forTheme(BlockTheme theme) => switch (theme) {
    BlockTheme.classic => classic,
    BlockTheme.jelly => jelly,
    BlockTheme.chocolate => chocolate,
  };

  PhysicallyBasedMaterial createBlockMaterial({
    required int colorIndex,
    required double initialHue,
    Texture2D? baseColorTexture,
  }) {
    // Temas futuros podem configurar texturas e outros parâmetros do material
    // neste ponto, sem modificar as regras da partida.
    return PhysicallyBasedMaterial(baseColorTexture: baseColorTexture)
      ..baseColorFactor = blockColor(
        colorIndex,
        initialHue: initialHue,
        alpha: materialAlpha,
      )
      ..metallicFactor = metallicFactor
      ..roughnessFactor = roughnessFactor
      ..baseColorTextureTransform = TextureTransform(
        scale: vm.Vector2.all(textureTiling),
      )
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
