import 'dart:math' as math;

import 'package:blocky/game/game_config.dart';
import 'package:blocky/game/moving_block_axis.dart';
import 'package:blocky/scene/block_theme_visual.dart';
import 'package:blocky/scene/scene_effect_models.dart';
import 'package:flutter_scene/scene.dart';
import 'package:vector_math/vector_math.dart' as vm;

typedef SceneBlockColorResolver =
    vm.Vector4 Function(int colorIndex, {double alpha});

/// Coordena feedbacks visuais temporários sem alterar dimensões lógicas.
class SceneFeedbackController {
  SceneFeedbackController({
    required Scene scene,
    required BlockThemeVisual visual,
    required SceneBlockColorResolver colorForIndex,
  }) : _scene = scene,
       _visual = visual,
       _colorForIndex = colorForIndex;

  final Scene _scene;
  final BlockThemeVisual _visual;
  final SceneBlockColorResolver _colorForIndex;
  final List<SceneTransientParticleEffect> _particleEffects = [];
  final List<ScenePerfectLightPulse> _lightPulses = [];
  final List<ScenePerfectWobble> _perfectWobbles = [];

  Node? _impactBlock;
  double _impactElapsedSeconds = 0.0;
  Node? _recoveryBlock;
  MovingBlockAxis? _recoveryAxis;
  double _recoveryInitialScale = 1.0;
  double _recoveryElapsedSeconds = 0.0;

  bool get isActive =>
      _particleEffects.isNotEmpty ||
      _lightPulses.isNotEmpty ||
      _perfectWobbles.isNotEmpty ||
      _impactBlock != null ||
      _recoveryBlock != null;

  void playPerfectParticles(
    vm.Vector3 position, {
    required int colorIndex,
    bool isRecovery = false,
  }) {
    final particles = isRecovery
        ? _visual.perfectRecoveryParticles
        : _visual.perfectParticles;
    _createParticleEffect(
      position: position,
      particles: particles,
      color: _colorForIndex(colorIndex, alpha: 0.9),
    );
  }

  void playCutParticles(vm.Vector3 position, {required int colorIndex}) {
    final particles = _visual.cutParticles;
    if (particles == null) return;

    _createParticleEffect(
      position: position,
      particles: particles,
      color: _colorForIndex(colorIndex, alpha: 0.95),
    );
  }

  void playPerfectLightPulse(
    Node block, {
    required double width,
    required double depth,
    required int colorIndex,
  }) {
    final color = _colorForIndex(colorIndex);
    final material = PhysicallyBasedMaterial()
      ..baseColorFactor = vm.Vector4(color.x, color.y, color.z, 0.0)
      ..emissiveFactor = vm.Vector4(color.x, color.y, color.z, 1.0)
      ..emissiveStrength = GameConfig.perfectLightPulseEmissiveStrength
      ..metallicFactor = 0.0
      ..roughnessFactor = 1.0
      ..alphaMode = AlphaMode.blend;
    final pulse =
        Node(
            mesh: Mesh(
              CuboidGeometry(
                vm.Vector3(width, GameConfig.perfectLightPulseHeight, depth),
              ),
              material,
            ),
          )
          ..position = vm.Vector3(
            block.position.x,
            block.position.y -
                GameConfig.blockHeight / 2 -
                GameConfig.blockGap / 2,
            block.position.z,
          )
          ..scale = vm.Vector3(
            GameConfig.perfectLightPulseInitialScale,
            1.0,
            GameConfig.perfectLightPulseInitialScale,
          )
          ..castsShadows = false;

    _scene.add(pulse);
    _lightPulses.add(
      ScenePerfectLightPulse(node: pulse, material: material, color: color),
    );
  }

  void playPerfectWobble(Node block) {
    final wobble = _visual.perfectWobble;
    if (wobble.duration == Duration.zero) return;

    _perfectWobbles.add(
      ScenePerfectWobble(
        node: block,
        basePosition: block.position,
        baseRotation: block.rotation,
      ),
    );
  }

  void playPlacementImpact(Node block) {
    _impactBlock = block;
    _impactElapsedSeconds = 0.0;
    block.scale = vm.Vector3.all(1.0);
  }

  void playRecoveryGrowth(
    Node block, {
    required MovingBlockAxis axis,
    required double initialScale,
  }) {
    _recoveryBlock = block;
    _recoveryAxis = axis;
    _recoveryInitialScale = initialScale;
    _recoveryElapsedSeconds = 0.0;
    _setRecoveryScale(block, initialScale);
  }

  /// Atualiza todos os feedbacks e informa quando o ticker pode ser reavaliado.
  bool update(double deltaSeconds) {
    final wasActive = isActive;
    _updatePlacementImpact(deltaSeconds);
    _updateRecoveryGrowth(deltaSeconds);
    _updatePerfectWobbles(deltaSeconds);
    _updateLightPulses(deltaSeconds);
    _removeExpiredParticleEffects(deltaSeconds);
    return wasActive && !isActive;
  }

  void clear() {
    for (final effect in _particleEffects) {
      _scene.remove(effect.node);
    }
    for (final pulse in _lightPulses) {
      _scene.remove(pulse.node);
    }
    for (final wobble in _perfectWobbles) {
      wobble.node
        ..position = wobble.basePosition
        ..rotation = wobble.baseRotation;
    }
    _impactBlock?.scale = vm.Vector3.all(1.0);
    _recoveryBlock?.scale = vm.Vector3.all(1.0);

    _particleEffects.clear();
    _lightPulses.clear();
    _perfectWobbles.clear();
    _impactBlock = null;
    _impactElapsedSeconds = 0.0;
    _recoveryBlock = null;
    _recoveryAxis = null;
    _recoveryElapsedSeconds = 0.0;
  }

  void _createParticleEffect({
    required vm.Vector3 position,
    required BlockParticleVisual particles,
    required vm.Vector4 color,
  }) {
    final transparentColor = vm.Vector4(color.x, color.y, color.z, 0.0);
    final system = ParticleSystem(
      maxParticles: particles.count,
      shape: SphereEmitterShape(
        radius: particles.emitterRadius,
        surfaceOnly: true,
        hemisphere: true,
      ),
      spawner: Spawner(
        bursts: [ParticleBurst(time: 0.0, count: particles.count)],
      ),
      lifetime: ConstantFloat(particles.lifetime),
      startSpeed: UniformFloat(particles.minimumSpeed, particles.maximumSpeed),
      startSize: UniformFloat(particles.minimumSize, particles.maximumSize),
      startColor: ConstantColor(color),
      gravity: vm.Vector3(0.0, -particles.gravity, 0.0),
      looping: false,
      duration: 0.01,
      modules: [
        SizeOverLifeModule(
          CurveFloat(ParticleCurve.linear(from: 1.0, to: 0.2)),
        ),
        ColorOverLifeModule(
          GradientColor(
            ColorGradient([
              ColorStop(0.0, color),
              ColorStop(1.0, transparentColor),
            ]),
          ),
        ),
      ],
    );
    final effectNode = Node()
      ..position = vm.Vector3(
        position.x,
        position.y + GameConfig.blockHeight / 2,
        position.z,
      )
      ..addComponent(ParticleEmitterComponent(system: system));

    _scene.add(effectNode);
    _particleEffects.add(
      SceneTransientParticleEffect(
        effectNode,
        particles.effectDuration.inMicroseconds /
            Duration.microsecondsPerSecond,
      ),
    );
  }

  void _removeExpiredParticleEffects(double deltaSeconds) {
    _particleEffects.removeWhere((effect) {
      effect.remainingSeconds -= deltaSeconds;
      if (effect.remainingSeconds > 0.0) return false;

      _scene.remove(effect.node);
      return true;
    });
  }

  void _updateLightPulses(double deltaSeconds) {
    if (_lightPulses.isEmpty) return;

    final duration =
        GameConfig.perfectLightPulseDuration.inMicroseconds /
        Duration.microsecondsPerSecond;
    _lightPulses.removeWhere((pulse) {
      pulse.elapsedSeconds += deltaSeconds;
      final progress = (pulse.elapsedSeconds / duration)
          .clamp(0.0, 1.0)
          .toDouble();
      final scale =
          GameConfig.perfectLightPulseInitialScale +
          (GameConfig.perfectLightPulseFinalScale -
                  GameConfig.perfectLightPulseInitialScale) *
              (1.0 - math.pow(1.0 - progress, 3.0).toDouble());
      final opacity =
          GameConfig.perfectLightPulseOpacity *
          math.pow(1.0 - progress, 1.7).toDouble();

      pulse.node.scale = vm.Vector3(scale, 1.0, scale);
      pulse.material.baseColorFactor = vm.Vector4(
        pulse.color.x,
        pulse.color.y,
        pulse.color.z,
        opacity,
      );

      if (progress < 1.0) return false;
      _scene.remove(pulse.node);
      return true;
    });
  }

  void _updatePerfectWobbles(double deltaSeconds) {
    final visual = _visual.perfectWobble;
    if (_perfectWobbles.isEmpty) return;

    final duration =
        visual.duration.inMicroseconds / Duration.microsecondsPerSecond;
    _perfectWobbles.removeWhere((effect) {
      effect.elapsedSeconds += deltaSeconds;
      final progress = (effect.elapsedSeconds / duration)
          .clamp(0.0, 1.0)
          .toDouble();
      final envelope = math.sin(math.pi * progress) * (1.0 - progress);
      final phase = progress * math.pi * 5.0;
      final translation = visual.translationAmplitude * envelope;
      final rotation = visual.rotationAmplitude * envelope;

      effect.node.position =
          effect.basePosition +
          vm.Vector3(
            math.sin(phase * 1.1) * translation,
            math.sin(phase * 1.7) * translation * 0.28,
            math.sin(phase * 0.85) * translation * 0.85,
          );
      effect.node.rotation =
          effect.baseRotation *
          vm.Quaternion.euler(
            math.sin(phase * 0.9) * rotation,
            math.sin(phase * 1.3) * rotation * 0.72,
            math.sin(phase * 1.6) * rotation * 0.62,
          );

      if (progress < 1.0) return false;
      effect.node
        ..position = effect.basePosition
        ..rotation = effect.baseRotation;
      return true;
    });
  }

  void _updatePlacementImpact(double deltaSeconds) {
    final block = _impactBlock;
    if (block == null) return;

    _impactElapsedSeconds += deltaSeconds;
    final impact = _visual.placementImpact;
    final duration =
        impact.duration.inMicroseconds / Duration.microsecondsPerSecond;
    final progress = (_impactElapsedSeconds / duration)
        .clamp(0.0, 1.0)
        .toDouble();
    block.scale = _impactScale(impact, progress);

    if (progress == 1.0) {
      block.scale = vm.Vector3.all(1.0);
      _impactBlock = null;
    }
  }

  vm.Vector3 _impactScale(BlockImpactVisual impact, double progress) {
    return switch (impact.motion) {
      BlockImpactMotion.standard => _standardImpactScale(impact, progress),
      BlockImpactMotion.squashAndStretch => _jellyImpactScale(impact, progress),
      BlockImpactMotion.firmSettle => _firmSettleImpactScale(impact, progress),
    };
  }

  vm.Vector3 _standardImpactScale(BlockImpactVisual impact, double progress) {
    final intensity = math.sin(math.pi * progress);
    return vm.Vector3(
      1.0 + impact.horizontalScale * intensity,
      1.0 - impact.verticalScale * intensity,
      1.0 + impact.horizontalScale * intensity,
    );
  }

  vm.Vector3 _jellyImpactScale(BlockImpactVisual impact, double progress) {
    const squashPortion = 0.42;
    if (progress < squashPortion) {
      final squashProgress = progress / squashPortion;
      final intensity = math.sin(math.pi / 2 * squashProgress);
      return vm.Vector3(
        1.0 + impact.horizontalScale * intensity,
        1.0 - impact.verticalScale * intensity,
        1.0 + impact.horizontalScale * intensity,
      );
    }

    final reboundProgress = ((progress - squashPortion) / (1 - squashPortion))
        .clamp(0.0, 1.0)
        .toDouble();
    final intensity = math.sin(math.pi * reboundProgress);
    return vm.Vector3(
      1.0 - impact.reboundHorizontalScale * intensity,
      1.0 + impact.reboundVerticalScale * intensity,
      1.0 - impact.reboundHorizontalScale * intensity,
    );
  }

  vm.Vector3 _firmSettleImpactScale(BlockImpactVisual impact, double progress) {
    const compressionPortion = 0.6;
    if (progress < compressionPortion) {
      final compressionProgress = progress / compressionPortion;
      final intensity = math.sin(math.pi / 2 * compressionProgress);
      return vm.Vector3(
        1.0 + impact.horizontalScale * intensity,
        1.0 - impact.verticalScale * intensity,
        1.0 + impact.horizontalScale * intensity,
      );
    }

    final reboundProgress =
        ((progress - compressionPortion) / (1.0 - compressionPortion))
            .clamp(0.0, 1.0)
            .toDouble();
    final intensity = math.sin(math.pi * reboundProgress);
    return vm.Vector3(
      1.0 - impact.reboundHorizontalScale * intensity,
      1.0 + impact.reboundVerticalScale * intensity,
      1.0 - impact.reboundHorizontalScale * intensity,
    );
  }

  void _updateRecoveryGrowth(double deltaSeconds) {
    final block = _recoveryBlock;
    final axis = _recoveryAxis;
    if (block == null || axis == null) return;

    _recoveryElapsedSeconds += deltaSeconds;
    final duration =
        GameConfig.perfectRecoveryAnimationDuration.inMicroseconds /
        Duration.microsecondsPerSecond;
    final progress = (_recoveryElapsedSeconds / duration)
        .clamp(0.0, 1.0)
        .toDouble();
    final easedProgress = 1.0 - math.pow(1.0 - progress, 3.0).toDouble();
    final recoveryProgress =
        easedProgress +
        _visual.recoveryGrowthOvershoot * math.sin(math.pi * progress);
    final scale =
        _recoveryInitialScale +
        (1.0 - _recoveryInitialScale) * recoveryProgress;
    _setRecoveryScale(block, scale);

    if (progress == 1.0) {
      block.scale = vm.Vector3.all(1.0);
      _recoveryBlock = null;
      _recoveryAxis = null;
    }
  }

  void _setRecoveryScale(Node block, double scale) {
    block.scale = switch (_recoveryAxis) {
      MovingBlockAxis.x => vm.Vector3(scale, 1.0, 1.0),
      MovingBlockAxis.z => vm.Vector3(1.0, 1.0, scale),
      null => vm.Vector3.all(1.0),
    };
  }
}
