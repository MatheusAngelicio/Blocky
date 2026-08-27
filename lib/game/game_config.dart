import 'dart:math' as math;

import 'package:flutter/material.dart';

abstract final class GameConfig {
  static const backgroundColor = Color(0xFF101018);

  static const blockWidth = 3.6;
  static const blockHeight = 0.6;
  static const blockDepth = 3.6;
  static const blockGap = 0.04;
  static const blockVerticalStep = blockHeight + blockGap;
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
  static const perfectFeedbackDuration = Duration(milliseconds: 700);

  static double movingBlockSpeedForScore(int score) {
    return movingBlockMaximumSpeed -
        (movingBlockMaximumSpeed - movingBlockInitialSpeed) *
            math.exp(-score * movingBlockSpeedGrowthRate);
  }
}
