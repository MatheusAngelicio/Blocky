import 'package:flutter/material.dart';

abstract final class GameConfig {
  static const backgroundColor = Color(0xFF101018);

  static const blockWidth = 3.6;
  static const blockHeight = 0.6;
  static const blockDepth = 3.6;
  static const blockGap = 0.04;
  static const blockVerticalStep = blockHeight + blockGap;
  static const movingBlockCenterY = 0.64;
  static const movingBlockSpeed = 3.5;
}
