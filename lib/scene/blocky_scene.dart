import 'dart:math' as math;

import 'package:blocky/game/block_color_palette.dart';
import 'package:blocky/game/block_overlap.dart';
import 'package:blocky/game/blocky_game_controller.dart';
import 'package:blocky/game/game_config.dart';
import 'package:flutter/widgets.dart' hide BoxShape;
import 'package:flutter_scene/physics.dart';
import 'package:flutter_scene/scene.dart';
import 'package:flutter_scene_rapier/flutter_scene_rapier.dart';
import 'package:vector_math/vector_math.dart' as vm;

class BlockyScene extends StatefulWidget {
  const BlockyScene({super.key, required this.gameController});

  final BlockyGameController gameController;

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
  final math.Random _random = math.Random();
  late double _initialBlockHue;
  int _nextBlockColorIndex = 0;
  int _sceneRound = -1;
  final List<Node> _fallingPieces = [];

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
    _sceneRound = widget.gameController.round;
    _hasResolvedPlacement = false;
    _movingDirection = 1.0;
    _towerCenterX = 0.0;
    _towerCenterZ = 0.0;
    _towerTopY = 0.0;
    _towerWidth = GameConfig.blockWidth;
    _towerDepth = GameConfig.blockDepth;
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
    final color = BlockColorPalette.colorForBlock(
      colorIndex,
      initialHue: _initialBlockHue,
    );

    return PhysicallyBasedMaterial()
      ..baseColorFactor = vm.Vector4(
        _sRgbToLinear(color.r),
        _sRgbToLinear(color.g),
        _sRgbToLinear(color.b),
        1.0,
      )
      ..metallicFactor = 0.05
      ..roughnessFactor = 0.65;
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
    }

    if (isPerfect && movesOnX) {
      _towerCenterX = below.center;
    } else if (isPerfect) {
      _towerCenterZ = below.center;
    } else if (movesOnX) {
      _towerCenterX = overlap.center;
      _towerWidth = overlap.length;
    } else {
      _towerCenterZ = overlap.center;
      _towerDepth = overlap.length;
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
      _createMovingBlock();
    }
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
          enabled: widget.gameController.isMoving || _fallingPieces.isNotEmpty,
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
              _removeFallenPieces();
            },
          ),
        );
      },
    );
  }
}
