import 'dart:math' as math;

import 'package:blocky/game/block_color_palette.dart';
import 'package:blocky/game/game_haptics.dart';
import 'package:blocky/game/block_overlap.dart';
import 'package:blocky/game/blocky_game_controller.dart';
import 'package:blocky/game/game_config.dart';
import 'package:blocky/game/game_sound.dart';
import 'package:flutter/widgets.dart' hide BoxShape;
import 'package:flutter_scene/physics.dart';
import 'package:flutter_scene/scene.dart';
import 'package:flutter_scene_rapier/flutter_scene_rapier.dart';
import 'package:vector_math/vector_math.dart' as vm;

class BlockyScene extends StatefulWidget {
  const BlockyScene({
    super.key,
    required this.gameController,
    required this.soundPlayer,
  });

  final BlockyGameController gameController;
  final GameSoundPlayer soundPlayer;

  @override
  State<BlockyScene> createState() => _BlockySceneState();
}

class _BlockySceneState extends State<BlockyScene> {
  static const _initialCameraPositionY = 9.8;
  static const _initialCameraTargetY = 2.0;

  final Scene _scene = Scene();
  PhysicsWorld? _physicsWorld;
  late PhysicallyBasedMaterial _movingBlockMaterial;
  late Node _movingBlock;
  final PerspectiveCamera _camera = PerspectiveCamera(
    // Aumente o módulo de Z para afastar a câmera; diminua para aproximá-la.
    // Ajuste position.y para alterar a altura física da câmera.
    // Ajuste target.y para o enquadramento vertical: aumente-o para fazer os
    // blocos aparecerem mais abaixo na tela; diminua-o para fazê-los subir.
    position: vm.Vector3(0.0, _initialCameraPositionY, -17.0),
    target: vm.Vector3(0.0, _initialCameraTargetY, 0.0),
  );

  bool _isReady = false;
  bool _hasResolvedPlacement = false;
  double _movingDirection = 1.0;
  double _towerCenterX = 0.0;
  double _towerCenterZ = 0.0;
  double _towerTopY = 0.0;
  double _towerWidth = GameConfig.blockWidth;
  double _towerDepth = GameConfig.blockDepth;
  MovingBlockAxis? _lastReducedAxis;
  final math.Random _random = math.Random();
  late double _initialBlockHue;
  int _nextBlockColorIndex = 0;
  int _sceneRound = -1;
  final List<Node> _fallingPieces = [];
  final List<_PerfectParticleEffect> _perfectParticleEffects = [];
  Node? _impactBlock;
  double _impactElapsedSeconds = 0.0;
  Node? _recoveryBlock;
  MovingBlockAxis? _recoveryAxis;
  double _recoveryInitialScale = 1.0;
  double _recoveryElapsedSeconds = 0.0;

  @override
  void initState() {
    super.initState();
    widget.gameController.addListener(_onGameStateChanged);
    _initializeScene();
  }

  @override
  void dispose() {
    widget.gameController.removeListener(_onGameStateChanged);
    _scene.removeAll();
    final physicsWorld = _physicsWorld;
    if (physicsWorld != null) {
      _scene.root.removeComponent(physicsWorld);
    }
    super.dispose();
  }

  void _onGameStateChanged() {
    if (_isReady && widget.gameController.round != _sceneRound) {
      _resetRoundScene();
    } else if (_isReady && !widget.gameController.isMoving) {
      _resolveMovingBlockPlacement();
    }

    if (mounted) setState(() {});
  }

  Future<void> _initializeScene() async {
    await Scene.initializeStaticResources();
    await RapierWorld.ensureInitialized();
    if (!mounted) return;

    _scene.directionalLight = DirectionalLight(
      direction: vm.Vector3(-0.5, -1.0, -0.35),
      intensity: 1.6,
    );
    _physicsWorld = PhysicsWorld(
      RapierWorld(gravity: vm.Vector3(0.0, -GameConfig.physicsGravity, 0.0)),
    );
    _scene.root.addComponent(_physicsWorld!);
    _resetRoundScene();
    _isReady = true;
    if (!widget.gameController.isMoving) {
      _resolveMovingBlockPlacement();
    }

    if (mounted) setState(() {});
  }

  void _resetRoundScene() {
    _scene.removeAll();
    _fallingPieces.clear();
    _perfectParticleEffects.clear();
    _impactBlock = null;
    _impactElapsedSeconds = 0.0;
    _recoveryBlock = null;
    _recoveryAxis = null;
    _recoveryElapsedSeconds = 0.0;
    _sceneRound = widget.gameController.round;
    _hasResolvedPlacement = false;
    _movingDirection = 1.0;
    _towerCenterX = 0.0;
    _towerCenterZ = 0.0;
    _towerTopY = 0.0;
    _towerWidth = GameConfig.blockWidth;
    _towerDepth = GameConfig.blockDepth;
    _lastReducedAxis = null;
    _initialBlockHue = _random.nextDouble() * 360.0;
    _nextBlockColorIndex = 0;
    _resetCamera();

    _scene.add(
      Node(
        mesh: Mesh(
          _createBlockGeometry(GameConfig.blockWidth, GameConfig.blockDepth),
          _createBlockMaterial(_nextBlockColorIndex++),
        ),
      ),
    );
    _createMovingBlock();
  }

  void _resetCamera() {
    _camera.position = vm.Vector3(0.0, _initialCameraPositionY, -17.0);
    _camera.target = vm.Vector3(0.0, _initialCameraTargetY, 0.0);
  }

  CuboidGeometry _createBlockGeometry(double width, double depth) {
    return CuboidGeometry(vm.Vector3(width, GameConfig.blockHeight, depth));
  }

  PhysicallyBasedMaterial _createBlockMaterial(int colorIndex) {
    return PhysicallyBasedMaterial()
      ..baseColorFactor = _linearBlockColor(colorIndex)
      ..metallicFactor = 0.05
      ..roughnessFactor = 0.65;
  }

  vm.Vector4 _linearBlockColor(int colorIndex, {double alpha = 1.0}) {
    final color = BlockColorPalette.colorForBlock(
      colorIndex,
      initialHue: _initialBlockHue,
    );

    return vm.Vector4(
      _sRgbToLinear(color.r),
      _sRgbToLinear(color.g),
      _sRgbToLinear(color.b),
      alpha,
    );
  }

  double _sRgbToLinear(double value) {
    if (value <= 0.04045) return value / 12.92;

    return math.pow((value + 0.055) / 1.055, 2.4).toDouble();
  }

  void _createMovingBlock() {
    _hasResolvedPlacement = false;
    _movingDirection = 1.0;
    _movingBlockMaterial = _createBlockMaterial(_nextBlockColorIndex++);
    _movingBlock =
        Node(
            mesh: Mesh(
              _createBlockGeometry(_towerWidth, _towerDepth),
              _movingBlockMaterial,
            ),
          )
          ..position = vm.Vector3(
            _towerCenterX,
            _towerTopY + GameConfig.blockVerticalStep,
            _towerCenterZ,
          );
    _scene.add(_movingBlock);
  }

  void _resolveMovingBlockPlacement() {
    if (_hasResolvedPlacement) return;

    _hasResolvedPlacement = true;
    final position = _movingBlock.position;
    final movesOnX = widget.gameController.movingAxis == MovingBlockAxis.x;
    final below = BlockAxisRange(
      center: movesOnX ? _towerCenterX : _towerCenterZ,
      length: movesOnX ? _towerWidth : _towerDepth,
    );
    final current = BlockAxisRange(
      center: movesOnX ? position.x : position.z,
      length: movesOnX ? _towerWidth : _towerDepth,
    );
    final overlap = calculateBlockOverlap(below: below, current: current);

    if (!overlap.hasOverlap) {
      _movingBlock.visible = false;
      widget.gameController.endGame();
      GameHaptics.trigger(GameHapticEvent.gameOver);
      widget.soundPlayer.play(GameSound.gameOver);
      return;
    }

    final isPerfect = isPerfectBlockPlacement(
      below: below,
      current: current,
      tolerance: GameConfig.perfectPlacementTolerance,
    );
    if (!isPerfect) {
      _createFallingPiece(
        movesOnX: movesOnX,
        current: current,
        overlap: overlap,
        position: position,
      );
      widget.soundPlayer.play(GameSound.cut);
    }

    if (isPerfect && movesOnX) {
      _towerCenterX = below.center;
    } else if (isPerfect) {
      _towerCenterZ = below.center;
    } else if (movesOnX) {
      _towerCenterX = overlap.center;
      _towerWidth = overlap.length;
      _lastReducedAxis = MovingBlockAxis.x;
    } else {
      _towerCenterZ = overlap.center;
      _towerDepth = overlap.length;
      _lastReducedAxis = MovingBlockAxis.z;
    }
    _towerTopY = position.y;

    _movingBlock.position = vm.Vector3(
      _towerCenterX,
      _towerTopY,
      _towerCenterZ,
    );
    if (!isPerfect) {
      _movingBlock.mesh = Mesh(
        _createBlockGeometry(_towerWidth, _towerDepth),
        _movingBlockMaterial,
      );
    }
    if (widget.gameController.startNextBlock(isPerfect: isPerfect)) {
      final recovered =
          widget.gameController.consumePerfectRecovery() &&
          _applyPerfectRecovery();
      if (recovered) {
        _createPerfectParticleEffect(_movingBlock.position, isRecovery: true);
      } else {
        _playPlacementImpact(_movingBlock);
        if (isPerfect) {
          _createPerfectParticleEffect(_movingBlock.position);
        }
      }
      GameHaptics.trigger(
        recovered
            ? GameHapticEvent.perfectRecovery
            : isPerfect
            ? GameHapticEvent.perfect
            : GameHapticEvent.placement,
      );
      widget.soundPlayer.play(
        recovered
            ? GameSound.perfectRecovery
            : isPerfect
            ? GameSound.perfect
            : GameSound.placement,
      );
      _createMovingBlock();
    }
  }

  bool _applyPerfectRecovery() {
    final axis = _lastReducedAxis;
    if (axis == null) return false;

    final previousLength = axis == MovingBlockAxis.x
        ? _towerWidth
        : _towerDepth;
    switch (_lastReducedAxis) {
      case MovingBlockAxis.x:
        _towerWidth = GameConfig.recoverBlockLength(
          currentLength: _towerWidth,
          maximumLength: GameConfig.blockWidth,
        );
      case MovingBlockAxis.z:
        _towerDepth = GameConfig.recoverBlockLength(
          currentLength: _towerDepth,
          maximumLength: GameConfig.blockDepth,
        );
      case null:
        return false;
    }

    final recoveredLength = axis == MovingBlockAxis.x
        ? _towerWidth
        : _towerDepth;
    if (recoveredLength == previousLength) return false;

    _movingBlock.mesh = Mesh(
      _createBlockGeometry(_towerWidth, _towerDepth),
      _movingBlockMaterial,
    );
    _playPerfectRecoveryGrowth(
      _movingBlock,
      axis: axis,
      initialScale: previousLength / recoveredLength,
    );
    return true;
  }

  void _createFallingPiece({
    required bool movesOnX,
    required BlockAxisRange current,
    required BlockOverlap overlap,
    required vm.Vector3 position,
  }) {
    final cutRange = calculateCutOffRange(current: current, overlap: overlap);
    if (cutRange == null) return;

    final width = movesOnX ? cutRange.length : _towerWidth;
    final depth = movesOnX ? _towerDepth : cutRange.length;
    final movesTowardsPositiveAxis = cutRange.center > overlap.center;
    final outwardDirection = movesTowardsPositiveAxis ? 1.0 : -1.0;
    final linearVelocity = movesOnX
        ? vm.Vector3(
            outwardDirection * GameConfig.fallingPieceOutwardSpeed,
            0,
            0,
          )
        : vm.Vector3(
            0,
            0,
            outwardDirection * GameConfig.fallingPieceOutwardSpeed,
          );
    final angularVelocity = movesOnX
        ? vm.Vector3(
            0,
            0,
            outwardDirection * GameConfig.fallingPieceAngularSpeed,
          )
        : vm.Vector3(
            outwardDirection * GameConfig.fallingPieceAngularSpeed,
            0,
            0,
          );
    final piece =
        Node(
            mesh: Mesh(
              _createBlockGeometry(width, depth),
              _movingBlockMaterial,
            ),
          )
          ..position = movesOnX
              ? vm.Vector3(cutRange.center, position.y, position.z)
              : vm.Vector3(position.x, position.y, cutRange.center)
          ..addComponent(
            RigidBody(
              mass: GameConfig.fallingPieceMass,
              linearVelocity: linearVelocity,
              angularVelocity: angularVelocity,
            ),
          )
          // As sobras caem visualmente, mas não colidem com a torre nem entre si.
          ..addComponent(
            Collider(
              shape: BoxShape(
                halfExtents: vm.Vector3(
                  width / 2,
                  GameConfig.blockHeight / 2,
                  depth / 2,
                ),
              ),
              collisionMask: 0,
            ),
          );

    _scene.add(piece);
    _fallingPieces.add(piece);
  }

  void _removeFallenPieces() {
    final removalY = _towerTopY - GameConfig.fallingPieceCleanupDistance;
    var removedPiece = false;
    _fallingPieces.removeWhere((piece) {
      if (piece.position.y > removalY) return false;

      _scene.remove(piece);
      removedPiece = true;
      return true;
    });

    if (removedPiece && mounted) setState(() {});
  }

  void _createPerfectParticleEffect(
    vm.Vector3 position, {
    bool isRecovery = false,
  }) {
    final particleCount = isRecovery
        ? GameConfig.perfectRecoveryParticleCount
        : GameConfig.perfectParticleCount;
    final particleLifetime = isRecovery
        ? GameConfig.perfectRecoveryParticleLifetime
        : GameConfig.perfectParticleLifetime;
    final effectDuration = isRecovery
        ? GameConfig.perfectRecoveryParticleEffectDuration
        : GameConfig.perfectParticleEffectDuration;
    final emitterRadius = isRecovery
        ? GameConfig.perfectRecoveryParticleEmitterRadius
        : GameConfig.perfectParticleEmitterRadius;
    final minimumSpeed = isRecovery
        ? GameConfig.perfectRecoveryParticleMinimumSpeed
        : GameConfig.perfectParticleMinimumSpeed;
    final maximumSpeed = isRecovery
        ? GameConfig.perfectRecoveryParticleMaximumSpeed
        : GameConfig.perfectParticleMaximumSpeed;
    final minimumSize = isRecovery
        ? GameConfig.perfectRecoveryParticleMinimumSize
        : GameConfig.perfectParticleMinimumSize;
    final maximumSize = isRecovery
        ? GameConfig.perfectRecoveryParticleMaximumSize
        : GameConfig.perfectParticleMaximumSize;
    final color = _linearBlockColor(_nextBlockColorIndex - 1, alpha: 0.9);
    final transparentColor = vm.Vector4(color.x, color.y, color.z, 0.0);
    final system = ParticleSystem(
      maxParticles: particleCount,
      shape: SphereEmitterShape(
        radius: emitterRadius,
        surfaceOnly: true,
        hemisphere: true,
      ),
      spawner: Spawner(
        bursts: [ParticleBurst(time: 0.0, count: particleCount)],
      ),
      lifetime: ConstantFloat(particleLifetime),
      startSpeed: UniformFloat(minimumSpeed, maximumSpeed),
      startSize: UniformFloat(minimumSize, maximumSize),
      startColor: ConstantColor(color),
      gravity: vm.Vector3(0.0, -GameConfig.perfectParticleGravity, 0.0),
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
    _perfectParticleEffects.add(
      _PerfectParticleEffect(
        effectNode,
        effectDuration.inMicroseconds / Duration.microsecondsPerSecond,
      ),
    );
  }

  void _removeExpiredPerfectParticleEffects(double deltaSeconds) {
    var removedEffect = false;
    _perfectParticleEffects.removeWhere((effect) {
      effect.remainingSeconds -= deltaSeconds;
      if (effect.remainingSeconds > 0.0) return false;

      _scene.remove(effect.node);
      removedEffect = true;
      return true;
    });

    if (removedEffect && mounted) setState(() {});
  }

  void _playPlacementImpact(Node block) {
    _impactBlock = block;
    _impactElapsedSeconds = 0.0;
    block.scale = vm.Vector3.all(1.0);
  }

  void _updatePlacementImpact(double deltaSeconds) {
    final block = _impactBlock;
    if (block == null) return;

    _impactElapsedSeconds += deltaSeconds;
    final duration =
        GameConfig.placementImpactDuration.inMicroseconds /
        Duration.microsecondsPerSecond;
    final progress = (_impactElapsedSeconds / duration).clamp(0.0, 1.0);
    final intensity = math.sin(math.pi * progress);
    block.scale = vm.Vector3(
      1.0 + GameConfig.placementImpactHorizontalScale * intensity,
      1.0 - GameConfig.placementImpactVerticalScale * intensity,
      1.0 + GameConfig.placementImpactHorizontalScale * intensity,
    );

    if (progress == 1.0) {
      block.scale = vm.Vector3.all(1.0);
      _impactBlock = null;
    }
  }

  void _playPerfectRecoveryGrowth(
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

  void _updatePerfectRecoveryGrowth(double deltaSeconds) {
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
    final scale =
        _recoveryInitialScale + (1.0 - _recoveryInitialScale) * easedProgress;
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

  double _movementLimit(Size viewport) {
    final viewDirection = (_camera.target - _camera.position)..normalize();
    final position = _movingBlock.position;
    final depth = (position - _camera.position).dot(viewDirection);
    final halfFovX = math.atan(
      math.tan(_camera.fovRadiansY / 2) * viewport.aspectRatio,
    );
    final visibleHalfWidth = depth * math.tan(halfFovX);
    final movingLength = widget.gameController.movingAxis == MovingBlockAxis.x
        ? _towerWidth
        : _towerDepth;

    return math.max(0.0, visibleHalfWidth - movingLength / 2);
  }

  void _moveBlock(double deltaSeconds, double limit) {
    if (!widget.gameController.isMoving || limit == 0.0) return;

    final position = _movingBlock.position;
    final movesOnX = widget.gameController.movingAxis == MovingBlockAxis.x;
    final currentCoordinate = movesOnX ? position.x : position.z;
    final movementCenter = movesOnX ? _towerCenterX : _towerCenterZ;
    final speed = GameConfig.movingBlockSpeedForScore(
      widget.gameController.score,
    );
    final nextCoordinate =
        currentCoordinate + _movingDirection * speed * deltaSeconds;
    if (nextCoordinate >= movementCenter + limit ||
        nextCoordinate <= movementCenter - limit) {
      _movingDirection = -_movingDirection;
    }

    final clampedCoordinate = nextCoordinate.clamp(
      movementCenter - limit,
      movementCenter + limit,
    );
    _movingBlock.position = movesOnX
        ? vm.Vector3(clampedCoordinate, position.y, position.z)
        : vm.Vector3(position.x, position.y, clampedCoordinate);
  }

  void _updateCamera(double deltaSeconds) {
    final interpolation =
        1 - math.exp(-GameConfig.cameraFollowSpeed * deltaSeconds);
    final desiredPositionY = _initialCameraPositionY + _towerTopY;
    final desiredTargetY = _initialCameraTargetY + _towerTopY;
    final position = _camera.position;
    final target = _camera.target;

    _camera.position = vm.Vector3(
      position.x,
      position.y + (desiredPositionY - position.y) * interpolation,
      position.z,
    );
    _camera.target = vm.Vector3(
      target.x,
      target.y + (desiredTargetY - target.y) * interpolation,
      target.z,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isReady) return const SizedBox.expand();

    return LayoutBuilder(
      builder: (context, constraints) {
        final limit = _movementLimit(constraints.biggest);

        return TickerMode(
          enabled:
              widget.gameController.isMoving ||
              _fallingPieces.isNotEmpty ||
              _impactBlock != null ||
              _recoveryBlock != null ||
              _perfectParticleEffects.isNotEmpty,
          child: SceneView(
            _scene,
            camera: _camera,
            // Mantém uma única instância de ticker durante todas as rodadas.
            autoTick: true,
            onTick: (_, deltaSeconds) {
              if (widget.gameController.isMoving) {
                _updateCamera(deltaSeconds);
                _moveBlock(deltaSeconds, limit);
              }
              _updatePlacementImpact(deltaSeconds);
              _updatePerfectRecoveryGrowth(deltaSeconds);
              _removeFallenPieces();
              _removeExpiredPerfectParticleEffects(deltaSeconds);
            },
          ),
        );
      },
    );
  }
}

class _PerfectParticleEffect {
  _PerfectParticleEffect(this.node, this.remainingSeconds);

  final Node node;
  double remainingSeconds;
}
