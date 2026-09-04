import 'dart:math' as math;
import 'package:blocky/game/block_theme.dart';
import 'package:blocky/game/game_haptics.dart';
import 'package:blocky/game/block_tower.dart';
import 'package:blocky/game/blocky_game_controller.dart';
import 'package:blocky/game/game_config.dart';
import 'package:blocky/game/game_sound.dart';
import 'package:blocky/scene/block_theme_visual.dart';
import 'package:blocky/scene/block_theme_scene_renderer.dart';
import 'package:blocky/scene/scene_background_stars.dart';
import 'package:blocky/scene/scene_block_factory.dart';
import 'package:blocky/scene/scene_falling_piece_manager.dart';
import 'package:blocky/scene/scene_feedback_controller.dart';
import 'package:blocky/scene/scene_game_over_camera_reveal.dart';
import 'package:blocky/scene/sky_progression.dart';
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
  final BlockTower _tower = BlockTower();
  late final BlockThemeVisual _blockThemeVisual;
  late final SceneBlockFactory _blockFactory;
  late final SceneFallingPieceManager _fallingPieceManager;
  late final SceneFeedbackController _feedbackController;
  late final GradientSkySource _skySource;
  late SkyProgressionVariation _skyVariation;
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
  Size _viewportSize = Size.zero;
  final SceneGameOverCameraReveal _gameOverCameraReveal =
      SceneGameOverCameraReveal();
  double _movingDirection = 1.0;
  final math.Random _random = math.Random();
  late double _initialBlockHue;
  int _nextBlockColorIndex = 0;
  late int _movingBlockColorIndex;
  int _sceneRound = -1;
  late final SceneBackgroundStars _backgroundStars;

  @override
  void initState() {
    super.initState();
    _blockThemeVisual = BlockThemeVisual.forTheme(widget.blockTheme);
    final themeSceneRenderer = BlockThemeSceneRenderer(
      visual: _blockThemeVisual,
      colorForIndex: _linearBlockColor,
      random: _random,
    );
    _blockFactory = SceneBlockFactory(
      themeRenderer: themeSceneRenderer,
      colorForIndex: _linearBlockColor,
    );
    _fallingPieceManager = SceneFallingPieceManager(
      scene: _scene,
      blockFactory: _blockFactory,
      fallingVisual: _blockThemeVisual.fallingVisual,
    );
    _feedbackController = SceneFeedbackController(
      scene: _scene,
      visual: _blockThemeVisual,
      colorForIndex: _linearBlockColor,
    );
    _backgroundStars = SceneBackgroundStars(
      scene: _scene,
      random: _random,
      theme: widget.blockTheme,
    );
    widget.gameController.addListener(_onGameStateChanged);
    _initializeScene();
  }

  @override
  void dispose() {
    widget.gameController.removeListener(_onGameStateChanged);
    _feedbackController.clear();
    _fallingPieceManager.clear();
    _blockFactory.clear();
    _backgroundStars.clear();
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
    } else if (_isReady &&
        widget.gameController.status == GameStatus.playing &&
        !widget.gameController.isMoving) {
      _resolveMovingBlockPlacement();
    }

    if (_isReady && widget.gameController.isShowingGameOverPreview) {
      _beginGameOverCameraReveal();
    }

    if (_isReady) {
      SkyProgression.applyTo(
        _skySource,
        widget.gameController.score,
        theme: widget.blockTheme,
        variation: _skyVariation,
      );
    }

    if (mounted) setState(() {});
  }

  Future<void> _initializeScene() async {
    await Scene.initializeStaticResources();
    await RapierWorld.ensureInitialized();
    if (!mounted) return;

    _skySource = GradientSkySource(
      sunDirection: vm.Vector3(-0.45, 0.75, -0.5),
      sunSharpness: 1200.0,
    );
    SkyProgression.applyTo(
      _skySource,
      widget.gameController.score,
      theme: widget.blockTheme,
    );
    _scene.skybox = Skybox(_skySource);
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
    if (widget.gameController.status == GameStatus.playing &&
        !widget.gameController.isMoving) {
      _resolveMovingBlockPlacement();
    }
    if (widget.gameController.isShowingGameOverPreview) {
      _beginGameOverCameraReveal();
    }

    if (mounted) setState(() {});
  }

  void _resetRoundScene() {
    _feedbackController.clear();
    _fallingPieceManager.clear();
    _blockFactory.clear();
    _backgroundStars.clear();
    _scene.removeAll();
    _sceneRound = widget.gameController.round;
    _hasResolvedPlacement = false;
    _gameOverCameraReveal.reset();
    _movingDirection = 1.0;
    _tower.reset();
    _initialBlockHue = _random.nextDouble() * 360.0;
    _skyVariation = SkyProgression.randomVariation(_random);
    _nextBlockColorIndex = 0;
    _resetCamera();
    SkyProgression.applyTo(
      _skySource,
      widget.gameController.score,
      theme: widget.blockTheme,
      variation: _skyVariation,
    );
    _backgroundStars.create();

    final baseBlockColorIndex = _nextBlockColorIndex++;
    final foundationTopY = -GameConfig.blockHeight / 2;
    _scene.add(
      _blockFactory.createFoundationGlow(
        topY: foundationTopY,
        color: _linearBlockColor(baseBlockColorIndex),
      ),
    );
    final foundation =
        _blockFactory.createBlock(
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
          );
    _blockFactory.addTowerCollider(
      foundation,
      width: GameConfig.foundationWidth,
      depth: GameConfig.foundationDepth,
      height: GameConfig.foundationHeight,
    );
    _scene.add(foundation);

    final baseBlock = _blockFactory.createBlock(
      width: GameConfig.blockWidth,
      depth: GameConfig.blockDepth,
      colorIndex: baseBlockColorIndex,
      material: _blockThemeVisual.createBlockMaterial(
        colorIndex: baseBlockColorIndex,
        initialHue: _initialBlockHue,
      ),
    );
    _blockFactory.addTowerCollider(
      baseBlock,
      width: GameConfig.blockWidth,
      depth: GameConfig.blockDepth,
    );
    _scene.add(baseBlock);
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

  void _updateBackgroundStars(double deltaSeconds) {
    _backgroundStars.update(
      deltaSeconds: deltaSeconds,
      score: widget.gameController.score,
      cameraTargetY: _camera.target.y,
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
        _blockFactory.createBlock(
            width: _tower.width,
            depth: _tower.depth,
            colorIndex: _movingBlockColorIndex,
            material: _movingBlockMaterial,
          )
          ..position = vm.Vector3(
            _tower.centerX,
            _tower.topY + GameConfig.blockVerticalStep,
            _tower.centerZ,
          );
    _scene.add(_movingBlock);
  }

  void _resolveMovingBlockPlacement() {
    if (_hasResolvedPlacement) return;

    _hasResolvedPlacement = true;
    final position = _movingBlock.position;
    final movingAxis = widget.gameController.movingAxis;
    final placement = _tower.place(
      axis: movingAxis,
      currentCenter: movingAxis == MovingBlockAxis.x ? position.x : position.z,
      blockY: position.y,
    );

    if (!placement.hasOverlap) {
      _movingBlock.visible = false;
      widget.gameController.endGame();
      GameHaptics.trigger(GameHapticEvent.gameOver);
      widget.soundPlayer.play(_blockThemeVisual.sounds.gameOver);
      return;
    }

    if (placement.wasCut) {
      final cutPosition = _fallingPieceManager.createCutPiece(
        cutOff: placement.cutOff!,
        blockPosition: position,
        colorIndex: _movingBlockColorIndex,
        material: _movingBlockMaterial,
      );
      _feedbackController.playCutParticles(
        cutPosition,
        colorIndex: _movingBlockColorIndex,
      );
      widget.soundPlayer.play(_blockThemeVisual.sounds.cut);
    }

    _movingBlock.position = vm.Vector3(
      _tower.centerX,
      _tower.topY,
      _tower.centerZ,
    );
    if (placement.wasCut) {
      _blockFactory.updateBlock(
        block: _movingBlock,
        width: _tower.width,
        depth: _tower.depth,
        colorIndex: _movingBlockColorIndex,
        material: _movingBlockMaterial,
      );
    }
    if (widget.gameController.startNextBlock(isPerfect: placement.isPerfect)) {
      final recovered =
          widget.gameController.isPerfectRecoveryReady &&
          _applyPerfectRecovery();
      if (recovered) {
        widget.gameController.completePerfectRecovery();
        _feedbackController.playPerfectParticles(
          _movingBlock.position,
          colorIndex: _movingBlockColorIndex,
          isRecovery: true,
        );
      } else {
        _feedbackController.playPlacementImpact(_movingBlock);
      }
      if (placement.isPerfect) {
        _feedbackController.playPerfectLightPulse(
          _movingBlock,
          width: _tower.width,
          depth: _tower.depth,
          colorIndex: _movingBlockColorIndex,
        );
        _feedbackController.playPerfectWobble(_movingBlock);
      }
      GameHaptics.trigger(
        recovered
            ? GameHapticEvent.perfectRecovery
            : placement.isPerfect
            ? GameHapticEvent.perfect
            : GameHapticEvent.placement,
      );
      widget.soundPlayer.play(
        recovered
            ? _blockThemeVisual.sounds.perfectRecovery
            : placement.isPerfect
            ? _blockThemeVisual.sounds.perfect
            : _blockThemeVisual.sounds.placement,
      );
      _blockFactory.addTowerCollider(
        _movingBlock,
        width: _tower.width,
        depth: _tower.depth,
      );
      _createMovingBlock();
    }
  }

  bool _applyPerfectRecovery() {
    final recovery = _tower.recoverLastReducedAxis();
    if (recovery == null) return false;

    _blockFactory.updateBlock(
      block: _movingBlock,
      width: _tower.width,
      depth: _tower.depth,
      colorIndex: _movingBlockColorIndex,
      material: _movingBlockMaterial,
    );
    _feedbackController.playRecoveryGrowth(
      _movingBlock,
      axis: recovery.axis,
      initialScale: recovery.initialVisualScale,
    );
    return true;
  }

  double _movementLimit(Size viewport) {
    final viewDirection = (_camera.target - _camera.position)..normalize();
    final position = _movingBlock.position;
    final depth = (position - _camera.position).dot(viewDirection);
    final halfFovX = math.atan(
      math.tan(_camera.fovRadiansY / 2) * viewport.aspectRatio,
    );
    final visibleHalfWidth = depth * math.tan(halfFovX);
    final movingAxis = widget.gameController.movingAxis;
    final movingLength = _tower.lengthFor(movingAxis);
    final originalLength = _tower.maximumLengthFor(movingAxis);
    final travelScale = GameConfig.movingBlockTravelScale(
      currentLength: movingLength,
      originalLength: originalLength,
    );

    // Permite que o bloco percorra um pouco além da área enquadrada antes de
    // inverter. Conforme o bloco é cortado, o percurso no eixo reduzido fica
    // menor; a regra de overlap continua usando apenas a geometria da torre.
    final fullTravel =
        math.max(0.0, visibleHalfWidth - movingLength / 2) +
        GameConfig.movingBlockViewportOverscan;
    return fullTravel * travelScale;
  }

  void _moveBlock(double deltaSeconds, double limit) {
    if (!widget.gameController.isMoving || limit == 0.0) return;

    final position = _movingBlock.position;
    final movingAxis = widget.gameController.movingAxis;
    final movesOnX = movingAxis == MovingBlockAxis.x;
    final currentCoordinate = movesOnX ? position.x : position.z;
    final movementCenter = _tower.centerFor(movingAxis);
    final speed = widget.gameController.movingBlockSpeed;
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

  void _beginGameOverCameraReveal() {
    _gameOverCameraReveal.start(
      camera: _camera,
      viewportSize: _viewportSize,
      towerCenterX: _tower.centerX,
      towerCenterZ: _tower.centerZ,
      towerTopY: _tower.topY,
    );
  }

  void _updateGameOverCameraReveal(double deltaSeconds) {
    if (_gameOverCameraReveal.update(_camera, deltaSeconds)) {
      widget.gameController.completeGameOverPresentation();
    }
  }

  void _updateCamera(double deltaSeconds) {
    final verticalInterpolation =
        1 - math.exp(-GameConfig.cameraFollowSpeed * deltaSeconds);
    final horizontalInterpolation =
        1 - math.exp(-GameConfig.cameraHorizontalFollowSpeed * deltaSeconds);
    final desiredPositionX = _initialCameraPositionX + _tower.centerX;
    final desiredPositionY = _initialCameraPositionY + _tower.topY;
    final desiredPositionZ = _initialCameraPositionZ + _tower.centerZ;
    final desiredTargetX = _tower.centerX;
    final desiredTargetY = _initialCameraTargetY + _tower.topY;
    final desiredTargetZ = _tower.centerZ;
    final position = _camera.position;
    final target = _camera.target;

    _camera.position = vm.Vector3(
      position.x + (desiredPositionX - position.x) * horizontalInterpolation,
      position.y + (desiredPositionY - position.y) * verticalInterpolation,
      position.z + (desiredPositionZ - position.z) * horizontalInterpolation,
    );
    _camera.target = vm.Vector3(
      target.x + (desiredTargetX - target.x) * horizontalInterpolation,
      target.y + (desiredTargetY - target.y) * verticalInterpolation,
      target.z + (desiredTargetZ - target.z) * horizontalInterpolation,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isReady) return const SizedBox.expand();

    return LayoutBuilder(
      builder: (context, constraints) {
        _viewportSize = constraints.biggest;
        final limit = _movementLimit(constraints.biggest);

        return TickerMode(
          enabled:
              widget.gameController.isMoving ||
              _fallingPieceManager.hasActivePieces ||
              _feedbackController.isActive ||
              _gameOverCameraReveal.isActive,
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
              _updateGameOverCameraReveal(deltaSeconds);
              _updateBackgroundStars(deltaSeconds);
              final feedbackFinished = _feedbackController.update(deltaSeconds);
              final fallingPiecesChanged = _fallingPieceManager.update(
                deltaSeconds,
                towerTopY: _tower.topY,
              );
              if ((feedbackFinished || fallingPiecesChanged) && mounted) {
                setState(() {});
              }
            },
          ),
        );
      },
    );
  }
}
