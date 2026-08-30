import 'dart:math' as math;

import 'package:blocky/game/game_config.dart';
import 'package:blocky/scene/scene_effect_models.dart';
import 'package:flutter_scene/scene.dart';
import 'package:vector_math/vector_math.dart' as vm;

/// Campo de estrelas leve que acompanha verticalmente a câmera.
class SceneBackgroundStars {
  SceneBackgroundStars({required Scene scene, required math.Random random})
    : _scene = scene,
      _random = random;

  final Scene _scene;
  final math.Random _random;
  final List<SceneBackgroundStar> _stars = [];

  void clear() => _stars.clear();

  void create() {
    for (var index = 0; index < GameConfig.backgroundStarCount; index++) {
      final size =
          GameConfig.backgroundStarMinimumSize +
          _random.nextDouble() *
              (GameConfig.backgroundStarMaximumSize -
                  GameConfig.backgroundStarMinimumSize);
      final material = _createMaterial();
      final star = Node(
        mesh: Mesh(CuboidGeometry(vm.Vector3.all(size)), material),
      )..castsShadows = false;
      _stars.add(
        SceneBackgroundStar(
          node: star,
          material: material,
          horizontalOffset:
              (_random.nextDouble() - 0.5) *
              GameConfig.backgroundStarFieldWidth,
          verticalOffset:
              (_random.nextDouble() - 0.5) *
              GameConfig.backgroundStarFieldHeight,
          depth:
              GameConfig.backgroundStarFieldDepth + _random.nextDouble() * 0.6,
          blinkSpeed: 0.8 + _random.nextDouble() * 1.4,
          blinkPhase: _random.nextDouble() * math.pi * 2,
        ),
      );
      _scene.add(star);
    }
  }

  void update({
    required double deltaSeconds,
    required int score,
    required double cameraTargetY,
  }) {
    if (_stars.isEmpty) return;

    final nightProgress = (score / 80).clamp(0.0, 1.0).toDouble();
    final maximumOpacity =
        GameConfig.backgroundStarDayOpacity +
        (GameConfig.backgroundStarNightOpacity -
                GameConfig.backgroundStarDayOpacity) *
            nightProgress;
    for (final star in _stars) {
      star.elapsedSeconds += deltaSeconds;
      final blink = math
          .pow(
            (math.sin(star.elapsedSeconds * star.blinkSpeed + star.blinkPhase) +
                    1.0) /
                2.0,
            3.0,
          )
          .toDouble();
      final opacity = maximumOpacity * blink;
      star.node.position = vm.Vector3(
        star.horizontalOffset,
        cameraTargetY + star.verticalOffset,
        star.depth,
      );
      star.node.scale = vm.Vector3.all(0.7 + blink * 0.55);
      star.material.baseColorFactor = vm.Vector4(1.0, 0.96, 0.82, opacity);
      star.material.emissiveStrength = 0.55 + blink * 1.25;
    }
  }

  PhysicallyBasedMaterial _createMaterial() {
    return PhysicallyBasedMaterial()
      ..baseColorFactor = vm.Vector4(1.0, 0.96, 0.82, 0.0)
      ..emissiveFactor = vm.Vector4(1.0, 0.96, 0.82, 1.0)
      ..emissiveStrength = 1.0
      ..metallicFactor = 0.0
      ..roughnessFactor = 1.0
      ..alphaMode = AlphaMode.blend;
  }
}
