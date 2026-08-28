import 'dart:math' as math;

abstract final class GameConfig {
  static const blockWidth = 3.6;
  static const blockHeight = 0.6;
  static const blockDepth = 3.6;
  static const blockGap = 0.04;
  static const blockVerticalStep = blockHeight + blockGap;
  // Elementos de cenário iniciais: não participam do overlap da partida.
  static const foundationWidth = 5.2;
  static const foundationDepth = 5.2;
  static const foundationHeight = 0.78;
  static const foundationSlabWidth = 6.4;
  static const foundationSlabDepth = 5.8;
  static const foundationSlabHeight = 0.1;
  static const foundationSlabOffsetX = -0.45;
  static const foundationSlabOffsetZ = 0.28;
  static const movingBlockCenterY = 0.64;
  static const movingBlockInitialSpeed = 3.5;
  static const movingBlockMaximumSpeed = 7.0;
  static const movingBlockSpeedGrowthRate = 0.07;
  static const cameraFollowSpeed = 3.5;
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
  static const perfectStreakForRecovery = 4;
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

  static double recoverBlockLength({
    required double currentLength,
    required double maximumLength,
  }) {
    return math.min(maximumLength, currentLength + perfectRecoveryAmount);
  }
}
