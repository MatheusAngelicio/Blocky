import 'dart:math' as math;

abstract final class GameConfig {
  static const blockWidth = 3.6;
  static const blockHeight = 0.6;
  static const blockDepth = 3.6;
  static const blockGap = 0.04;
  static const blockVerticalStep = blockHeight + blockGap;
  // Elementos de cenário iniciais: não participam do overlap da partida.
  static const foundationWidth = 4.9;
  static const foundationDepth = 4.9;
  // Altura do único pedestal inicial. Ajuste este valor para testá-lo.
  static const foundationHeight = 1.45;
  static const foundationBaseGlowWidth = 5.16;
  static const foundationBaseGlowDepth = 5.16;
  static const foundationBaseGlowHeight = 0.025;
  static const movingBlockCenterY = 0.64;
  // Curva de dificuldade: começa mais ágil, mas cresce ao longo de uma partida
  // maior. Em torno de 94 blocos, ela terá percorrido 95% do caminho ao teto.
  static const movingBlockInitialSpeed = 4.4;
  static const movingBlockMaximumSpeed = 11.0;
  static const movingBlockSpeedGrowthRate = 0.032;
  // A partir deste score, Perfects aliviam gradualmente a velocidade. O piso
  // é a velocidade que a curva já teria atingido neste mesmo score.
  static const perfectSpeedReliefStartScore = 20;
  static const perfectSpeedReliefPerPerfect = 0.18;
  // Distância extra além da borda visível antes do bloco inverter. Aplica-se
  // aos dois eixos de movimento (X e Z) para manter o percurso mais amplo.
  static const movingBlockViewportOverscan = 2.2;
  // Mesmo quando muito fino, o bloco mantém um pequeno percurso para o jogo
  // continuar controlável. A escala reduz linearmente conforme ele é cortado.
  static const movingBlockMinimumTravelScale = 0.70;
  static const cameraFollowSpeed = 3.5;
  static const cameraHorizontalFollowSpeed = 7.0;
  static const physicsGravity = 9.81;
  static const fallingPieceMass = 0.5;
  static const fallingPieceOutwardSpeed = 1.2;
  static const fallingPieceAngularSpeed = 4.0;
  static const fallingPieceCleanupDistance = 14.0;
  static const placementImpactDuration = Duration(milliseconds: 120);
  static const placementImpactHorizontalScale = 0.03;
  static const placementImpactVerticalScale = 0.08;
  static const perfectParticleCount = 10;
  static const perfectParticleLifetime = 0.45;
  static const perfectParticleEffectDuration = Duration(milliseconds: 550);
  static const perfectParticleEmitterRadius = 0.45;
  static const perfectParticleMinimumSpeed = 0.55;
  static const perfectParticleMaximumSpeed = 1.15;
  static const perfectParticleMinimumSize = 0.035;
  static const perfectParticleMaximumSize = 0.07;
  static const perfectParticleGravity = 2.0;
  // Distância máxima, em unidades da cena, para considerar um encaixe perfeito.
  static const perfectPlacementTolerance = 0.12;
  // Pulso visual exibido sob um bloco encaixado perfeitamente.
  static const perfectLightPulseDuration = Duration(milliseconds: 260);
  static const perfectLightPulseInitialScale = 0.72;
  static const perfectLightPulseFinalScale = 1.3;
  static const perfectLightPulseHeight = 0.018;
  static const perfectLightPulseOpacity = 0.78;
  static const perfectLightPulseEmissiveStrength = 2.2;
  // Pequenas estrelas de fundo reutilizadas durante toda a partida.
  static const backgroundStarCount = 14;
  static const backgroundStarFieldWidth = 11.0;
  static const backgroundStarFieldHeight = 8.0;
  static const backgroundStarFieldDepth = 6.5;
  static const backgroundStarMinimumSize = 0.028;
  static const backgroundStarMaximumSize = 0.07;
  static const backgroundStarDayOpacity = 0.14;
  static const backgroundStarNightOpacity = 0.62;
  static const gameOverCameraRevealDuration = Duration(milliseconds: 850);
  static const gameOverCameraRevealHoldDuration = Duration(milliseconds: 900);
  static const gameOverCameraFramingPadding = 1.05;
  // Acima do centro para manter a base da torre perto da parte inferior.
  static const gameOverCameraTargetHeightRatio = 0.64;
  static const perfectStreakForRecovery = 4;
  static const blocksPerBlockyCoin = 10;
  static const blockyCoinsPerPerfectRecovery = 1;
  static const perfectRecoveryAmount = 0.6;
  static const perfectRecoveryAnimationDuration = Duration(milliseconds: 220);
  static const perfectRecoveryFeedbackDuration = Duration(milliseconds: 700);
  static const perfectRecoveryParticleCount = 18;
  static const perfectRecoveryParticleLifetime = 0.55;
  static const perfectRecoveryParticleEffectDuration = Duration(
    milliseconds: 650,
  );
  static const perfectRecoveryParticleEmitterRadius = 0.65;
  static const perfectRecoveryParticleMinimumSpeed = 0.8;
  static const perfectRecoveryParticleMaximumSpeed = 1.6;
  static const perfectRecoveryParticleMinimumSize = 0.045;
  static const perfectRecoveryParticleMaximumSize = 0.09;
  static const perfectFeedbackDuration = Duration(milliseconds: 700);

  static double movingBlockSpeedForScore(int score) {
    return movingBlockMaximumSpeed -
        (movingBlockMaximumSpeed - movingBlockInitialSpeed) *
            math.exp(-score * movingBlockSpeedGrowthRate);
  }

  static double minimumSpeedAfterPerfectRelief() {
    return movingBlockSpeedForScore(perfectSpeedReliefStartScore);
  }

  static double movingBlockTravelScale({
    required double currentLength,
    required double originalLength,
  }) {
    final sizeRatio = (currentLength / originalLength).clamp(0.0, 1.0);
    return movingBlockMinimumTravelScale +
        (1.0 - movingBlockMinimumTravelScale) * sizeRatio;
  }

  static double recoverBlockLength({
    required double currentLength,
    required double maximumLength,
  }) {
    return math.min(maximumLength, currentLength + perfectRecoveryAmount);
  }
}
