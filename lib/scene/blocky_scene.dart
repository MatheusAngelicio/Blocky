import 'dart:math' as math;
import 'dart:typed_data';

import 'package:blocky/game/block_theme.dart';
import 'package:blocky/game/game_haptics.dart';
import 'package:blocky/game/block_overlap.dart';
import 'package:blocky/game/blocky_game_controller.dart';
import 'package:blocky/game/game_config.dart';
import 'package:blocky/game/game_sound.dart';
import 'package:blocky/scene/block_theme_visual.dart';
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
    required this.blockTheme,
  });

  final BlockyGameController gameController;
  final GameSoundPlayer soundPlayer;
  final BlockTheme blockTheme;

  @override
  State<BlockyScene> createState() => _BlockySceneState();
}

class _BlockySceneState extends State<BlockyScene> {
  static const _initialCameraPositionX = -7.0;
  static const _initialCameraPositionY = 9.4;
  static const _initialCameraPositionZ = -12.5;
  static const _initialCameraTargetY = 1.55;

  final Scene _scene = Scene();
  late final BlockThemeVisual _blockThemeVisual;
  PhysicsWorld? _physicsWorld;
  late PhysicallyBasedMaterial _movingBlockMaterial;
  late Node _movingBlock;
  final PerspectiveCamera _camera = PerspectiveCamera(
    // Diminua os módulos de X/Z para aproximar a câmera; mantenha ambos
    // diferentes de zero para preservar a visão diagonal das duas laterais.
    // Ajuste position.y para alterar a altura física da câmera.
    // Ajuste target.y para o enquadramento vertical: aumente-o para fazer os
    // blocos aparecerem mais abaixo na tela; diminua-o para fazê-los subir.
    position: vm.Vector3(
      _initialCameraPositionX,
      _initialCameraPositionY,
      _initialCameraPositionZ,
    ),
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
  late int _movingBlockColorIndex;
  int _sceneRound = -1;
  final List<_FallingPiece> _fallingPieces = [];
  final List<_TransientParticleEffect> _transientParticleEffects = [];
  final List<_PerfectWobble> _perfectWobbles = [];
  final Map<Node, Node> _topFaceShades = {};
  Node? _impactBlock;
  double _impactElapsedSeconds = 0.0;
  Node? _recoveryBlock;
  MovingBlockAxis? _recoveryAxis;
  double _recoveryInitialScale = 1.0;
  double _recoveryElapsedSeconds = 0.0;

  @override
  void initState() {
    super.initState();
    _blockThemeVisual = BlockThemeVisual.forTheme(widget.blockTheme);
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

    _scene.skybox = Skybox(
      GradientSkySource(
        zenithColor: vm.Vector3(0.34, 0.73, 0.52),
        horizonColor: vm.Vector3(0.48, 0.80, 0.48),
        groundColor: vm.Vector3(0.62, 0.86, 0.36),
        sunDirection: vm.Vector3(-0.45, 0.75, -0.5),
        sunColor: vm.Vector3(1.5, 1.4, 1.1),
        sunSharpness: 1200.0,
      ),
    );
    _scene.directionalLight = DirectionalLight(
      direction: vm.Vector3(-0.45, -1.0, -0.5),
      intensity: 2.1,
      castsShadow: true,
      // As sombras de contato destacam a face superior que recebe outro
      // bloco, sem precisar adicionar geometria decorativa à torre.
      shadowSoftness: 0.1,
      shadowAmbientStrength: 0.48,
      contactShadows: true,
      contactShadowDistance: 0.65,
    );
    _scene.ambientOcclusion
      ..enabled = true
      ..radius = 0.55
      ..intensity = 0.9
      ..power = 1.35
      ..directLightAffect = 0.42;
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
    _transientParticleEffects.clear();
    _perfectWobbles.clear();
    _topFaceShades.clear();
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

    final baseBlockColorIndex = _nextBlockColorIndex++;
    final foundationTopY = -GameConfig.blockHeight / 2;
    _scene.add(
      _createBlockNode(
          width: GameConfig.foundationSlabWidth,
          depth: GameConfig.foundationSlabDepth,
          height: GameConfig.foundationSlabHeight,
          colorIndex: baseBlockColorIndex,
          material: _blockThemeVisual.createBlockMaterial(
            colorIndex: baseBlockColorIndex,
            initialHue: _initialBlockHue,
          ),
        )
        ..position = vm.Vector3(
          GameConfig.foundationSlabOffsetX,
          foundationTopY -
              GameConfig.foundationHeight -
              GameConfig.foundationSlabHeight / 2,
          GameConfig.foundationSlabOffsetZ,
        ),
    );
    _scene.add(
      _createBlockNode(
          width: GameConfig.foundationWidth,
          depth: GameConfig.foundationDepth,
          height: GameConfig.foundationHeight,
          colorIndex: baseBlockColorIndex,
          material: _blockThemeVisual.createBlockMaterial(
            colorIndex: baseBlockColorIndex,
            initialHue: _initialBlockHue,
          ),
        )
        ..position = vm.Vector3(
          0.0,
          foundationTopY - GameConfig.foundationHeight / 2,
          0.0,
        ),
    );
    _scene.add(
      _createBlockNode(
        width: GameConfig.blockWidth,
        depth: GameConfig.blockDepth,
        colorIndex: baseBlockColorIndex,
        material: _blockThemeVisual.createBlockMaterial(
          colorIndex: baseBlockColorIndex,
          initialHue: _initialBlockHue,
        ),
      ),
    );
    _createMovingBlock();
  }

  void _resetCamera() {
    _camera.position = vm.Vector3(
      _initialCameraPositionX,
      _initialCameraPositionY,
      _initialCameraPositionZ,
    );
    _camera.target = vm.Vector3(0.0, _initialCameraTargetY, 0.0);
  }

  MeshGeometry _createBlockGeometry(
    double width,
    double depth, {
    double height = GameConfig.blockHeight,
  }) {
    return CuboidGeometry(vm.Vector3(width, height, depth));
  }

  Node _createBlockNode({
    required double width,
    required double depth,
    double height = GameConfig.blockHeight,
    required int colorIndex,
    required PhysicallyBasedMaterial material,
  }) {
    final block = Node(
      mesh: Mesh(_createBlockGeometry(width, depth, height: height), material),
    );
    final topFaceShade =
        Node(
            mesh: Mesh(
              _createTopFaceShadeGeometry(width, depth),
              _createTopFaceShadeMaterial(colorIndex),
            ),
          )
          ..position = vm.Vector3(0.0, height / 2 + 0.003, 0.0)
          // A camada recebe a luz e as sombras da cena, mas não deve projetar uma
          // segunda sombra sobre a torre.
          ..castsShadows = false;
    block.add(topFaceShade);
    _topFaceShades[block] = topFaceShade;
    return block;
  }

  MeshGeometry _createTopFaceShadeGeometry(double width, double depth) {
    const inset = 0.006;
    final halfWidth = math.max(0.001, width / 2 - inset);
    final halfDepth = math.max(0.001, depth / 2 - inset);

    // A face mais próxima da câmera permanece luminosa; a face mais distante
    // recebe uma atenuação suave. Isso reproduz a profundidade do mockup sem
    // depender exclusivamente da resolução do shadow map.
    return MeshGeometry.fromArrays(
      positions: Float32List.fromList([
        -halfWidth,
        0.0,
        -halfDepth,
        halfWidth,
        0.0,
        -halfDepth,
        -halfWidth,
        0.0,
        halfDepth,
        halfWidth,
        0.0,
        halfDepth,
      ]),
      normals: Float32List.fromList([
        0.0,
        1.0,
        0.0,
        0.0,
        1.0,
        0.0,
        0.0,
        1.0,
        0.0,
        0.0,
        1.0,
        0.0,
      ]),
      // A camada de sombra também usa a textura do bloco. Sem UVs, todos os
      // vértices amostrariam o mesmo pixel e esconderiam o relevo do
      // chocolate na face superior.
      texCoords: Float32List.fromList([0.0, 0.0, 1.0, 0.0, 0.0, 1.0, 1.0, 1.0]),
      colors: Float32List.fromList([
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        0.72,
        0.72,
        0.72,
        1.0,
        0.72,
        0.72,
        0.72,
        1.0,
      ]),
      indices: [0, 2, 1, 1, 2, 3],
    );
  }

  PhysicallyBasedMaterial _createTopFaceShadeMaterial(int colorIndex) {
    return PhysicallyBasedMaterial()
      ..baseColorFactor = _linearBlockColor(colorIndex)
      ..metallicFactor = 0.0
      ..roughnessFactor = 0.78
      ..vertexColorWeight = 1.0;
  }

  void _updateBlockGeometry(
    Node block, {
    required double width,
    required double depth,
    required int colorIndex,
    required PhysicallyBasedMaterial material,
  }) {
    block.mesh = Mesh(_createBlockGeometry(width, depth), material);
    final topFaceShade = _topFaceShades[block];
    if (topFaceShade == null) return;

    topFaceShade.mesh = Mesh(
      _createTopFaceShadeGeometry(width, depth),
      _createTopFaceShadeMaterial(colorIndex),
    );
  }

  vm.Vector4 _linearBlockColor(int colorIndex, {double alpha = 1.0}) {
    return _blockThemeVisual.blockColor(
      colorIndex,
      initialHue: _initialBlockHue,
      alpha: alpha,
    );
  }

  void _createMovingBlock() {
    _hasResolvedPlacement = false;
    _movingDirection = 1.0;
    _movingBlockColorIndex = _nextBlockColorIndex++;
    _movingBlockMaterial = _blockThemeVisual.createBlockMaterial(
      colorIndex: _movingBlockColorIndex,
      initialHue: _initialBlockHue,
    );
    _movingBlock =
        _createBlockNode(
            width: _towerWidth,
            depth: _towerDepth,
            colorIndex: _movingBlockColorIndex,
            material: _movingBlockMaterial,
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
      widget.soundPlayer.play(_blockThemeVisual.sounds.gameOver);
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
      widget.soundPlayer.play(_blockThemeVisual.sounds.cut);
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
      _updateBlockGeometry(
        _movingBlock,
        width: _towerWidth,
        depth: _towerDepth,
        colorIndex: _movingBlockColorIndex,
        material: _movingBlockMaterial,
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
      if (isPerfect) {
        _playPerfectWobble(_movingBlock);
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
            ? _blockThemeVisual.sounds.perfectRecovery
            : isPerfect
            ? _blockThemeVisual.sounds.perfect
            : _blockThemeVisual.sounds.placement,
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

    _updateBlockGeometry(
      _movingBlock,
      width: _towerWidth,
      depth: _towerDepth,
      colorIndex: _movingBlockColorIndex,
      material: _movingBlockMaterial,
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
    _createCutParticleEffect(
      movesOnX
          ? vm.Vector3(cutRange.center, position.y, position.z)
          : vm.Vector3(position.x, position.y, cutRange.center),
    );
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
        _createBlockNode(
            width: width,
            depth: depth,
            colorIndex: _movingBlockColorIndex,
            material: _movingBlockMaterial,
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
    _fallingPieces.add(_FallingPiece(piece));
  }

  void _removeFallenPieces() {
    final removalY = _towerTopY - GameConfig.fallingPieceCleanupDistance;
    var removedPiece = false;
    _fallingPieces.removeWhere((piece) {
      if (piece.node.position.y > removalY) return false;

      _scene.remove(piece.node);
      _topFaceShades.remove(piece.node);
      removedPiece = true;
      return true;
    });

    if (removedPiece && mounted) setState(() {});
  }

  void _updateFallingPieceVisuals(double deltaSeconds) {
    final fallingVisual = _blockThemeVisual.fallingVisual;
    if (fallingVisual.wobbleAmplitude == 0.0) return;

    for (final piece in _fallingPieces) {
      piece.elapsedSeconds += deltaSeconds;
      final wobble = math.sin(
        piece.elapsedSeconds * fallingVisual.wobbleFrequency,
      );
      piece.node.scale = vm.Vector3(
        1.0 + fallingVisual.wobbleAmplitude * wobble,
        1.0 - fallingVisual.wobbleAmplitude * 1.4 * wobble,
        1.0 + fallingVisual.wobbleAmplitude * wobble,
      );
    }
  }

  void _createPerfectParticleEffect(
    vm.Vector3 position, {
    bool isRecovery = false,
  }) {
    final particles = isRecovery
        ? _blockThemeVisual.perfectRecoveryParticles
        : _blockThemeVisual.perfectParticles;
    _createTransientParticleEffect(
      position: position,
      particles: particles,
      color: _linearBlockColor(_movingBlockColorIndex, alpha: 0.9),
    );
  }

  void _createCutParticleEffect(vm.Vector3 position) {
    final particles = _blockThemeVisual.cutParticles;
    if (particles == null) return;

    _createTransientParticleEffect(
      position: position,
      particles: particles,
      color: _linearBlockColor(_movingBlockColorIndex, alpha: 0.95),
    );
  }

  void _createTransientParticleEffect({
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
    _transientParticleEffects.add(
      _TransientParticleEffect(
        effectNode,
        particles.effectDuration.inMicroseconds /
            Duration.microsecondsPerSecond,
      ),
    );
  }

  void _removeExpiredTransientParticleEffects(double deltaSeconds) {
    var removedEffect = false;
    _transientParticleEffects.removeWhere((effect) {
      effect.remainingSeconds -= deltaSeconds;
      if (effect.remainingSeconds > 0.0) return false;

      _scene.remove(effect.node);
      removedEffect = true;
      return true;
    });

    if (removedEffect && mounted) setState(() {});
  }

  void _playPerfectWobble(Node block) {
    final wobble = _blockThemeVisual.perfectWobble;
    if (wobble.duration == Duration.zero) return;

    _perfectWobbles.add(
      _PerfectWobble(
        node: block,
        basePosition: block.position,
        baseRotation: block.rotation,
      ),
    );
  }

  void _updatePerfectWobbles(double deltaSeconds) {
    final visual = _blockThemeVisual.perfectWobble;
    if (_perfectWobbles.isEmpty) return;

    final duration =
        visual.duration.inMicroseconds / Duration.microsecondsPerSecond;
    var completedEffect = false;
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

      effect.node.position = effect.basePosition;
      effect.node.rotation = effect.baseRotation;
      completedEffect = true;
      return true;
    });

    if (completedEffect && mounted) setState(() {});
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
    final impact = _blockThemeVisual.placementImpact;
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
    final recoveryProgress =
        easedProgress +
        _blockThemeVisual.recoveryGrowthOvershoot *
            math.sin(math.pi * progress);
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
              _perfectWobbles.isNotEmpty ||
              _transientParticleEffects.isNotEmpty,
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
              _updatePerfectWobbles(deltaSeconds);
              _updateFallingPieceVisuals(deltaSeconds);
              _removeFallenPieces();
              _removeExpiredTransientParticleEffects(deltaSeconds);
            },
          ),
        );
      },
    );
  }
}

class _TransientParticleEffect {
  _TransientParticleEffect(this.node, this.remainingSeconds);

  final Node node;
  double remainingSeconds;
}

class _PerfectWobble {
  _PerfectWobble({
    required this.node,
    required this.basePosition,
    required this.baseRotation,
  });

  final Node node;
  final vm.Vector3 basePosition;
  final vm.Quaternion baseRotation;
  double elapsedSeconds = 0.0;
}

class _FallingPiece {
  _FallingPiece(this.node);

  final Node node;
  double elapsedSeconds = 0.0;
}
