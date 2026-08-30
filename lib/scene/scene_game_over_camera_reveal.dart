import 'dart:math' as math;

import 'package:blocky/game/game_config.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_scene/scene.dart';
import 'package:vector_math/vector_math.dart' as vm;

/// Enquadra a torre e segura o resultado antes da interface de Game Over.
class SceneGameOverCameraReveal {
  bool get isActive => _isActive;

  bool _isActive = false;
  double _elapsedSeconds = 0.0;
  late vm.Vector3 _startPosition;
  late vm.Vector3 _startTarget;
  late vm.Vector3 _endPosition;
  late vm.Vector3 _endTarget;

  void reset() {
    _isActive = false;
    _elapsedSeconds = 0.0;
  }

  void start({
    required PerspectiveCamera camera,
    required Size viewportSize,
    required double towerCenterX,
    required double towerCenterZ,
    required double towerTopY,
  }) {
    if (_isActive) return;

    _isActive = true;
    _elapsedSeconds = 0.0;
    _startPosition = vm.Vector3.copy(camera.position);
    _startTarget = vm.Vector3.copy(camera.target);
    final towerBaseY =
        -GameConfig.blockHeight / 2 -
        GameConfig.foundationHeight -
        GameConfig.foundationBaseGlowHeight;
    final towerVisualTopY = towerTopY + GameConfig.blockHeight / 2;
    final towerHeight = math.max(
      GameConfig.blockHeight,
      towerVisualTopY - towerBaseY,
    );
    _endTarget = vm.Vector3(
      towerCenterX,
      towerBaseY + towerHeight * GameConfig.gameOverCameraTargetHeightRatio,
      towerCenterZ,
    );

    final viewDirection = _startPosition - _startTarget;
    final currentDistance = viewDirection.length;
    viewDirection.normalize();
    final viewportAspectRatio = viewportSize.height == 0.0
        ? 0.5
        : viewportSize.width / viewportSize.height;
    final horizontalFov =
        2 * math.atan(math.tan(camera.fovRadiansY / 2) * viewportAspectRatio);
    final maximumVerticalExtent = math.max(
      _endTarget.y - towerBaseY,
      towerVisualTopY - _endTarget.y,
    );
    final distanceNeededForHeight =
        maximumVerticalExtent / math.tan(camera.fovRadiansY / 2);
    final towerFootprint = math.max(
      GameConfig.foundationWidth,
      GameConfig.foundationDepth,
    );
    final distanceNeededForWidth =
        towerFootprint / (2 * math.tan(horizontalFov / 2));
    final revealDistance =
        math.max(
          currentDistance,
          math.max(distanceNeededForHeight, distanceNeededForWidth),
        ) *
        GameConfig.gameOverCameraFramingPadding;
    _endPosition = _endTarget + viewDirection * revealDistance;
  }

  /// Retorna `true` uma única vez quando a animação e a pausa terminarem.
  bool update(PerspectiveCamera camera, double deltaSeconds) {
    if (!_isActive) return false;

    _elapsedSeconds += deltaSeconds;
    final revealDuration =
        GameConfig.gameOverCameraRevealDuration.inMicroseconds /
        Duration.microsecondsPerSecond;
    final holdDuration =
        GameConfig.gameOverCameraRevealHoldDuration.inMicroseconds /
        Duration.microsecondsPerSecond;
    final progress = (_elapsedSeconds / revealDuration)
        .clamp(0.0, 1.0)
        .toDouble();
    final easedProgress = 1.0 - math.pow(1.0 - progress, 3.0).toDouble();
    camera.position =
        _startPosition + (_endPosition - _startPosition) * easedProgress;
    camera.target = _startTarget + (_endTarget - _startTarget) * easedProgress;

    if (_elapsedSeconds < revealDuration + holdDuration) return false;

    _isActive = false;
    return true;
  }
}
