import 'dart:math' as math;

import 'package:blocky/game/block_overlap.dart';
import 'package:blocky/game/blocky_game_controller.dart';
import 'package:blocky/game/game_config.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_scene/scene.dart';
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
  late final PhysicallyBasedMaterial _blockMaterial;
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

  @override
  void initState() {
    super.initState();
    widget.gameController.addListener(_onGameStateChanged);
    _initializeScene();
  }

  @override
  void dispose() {
    widget.gameController.removeListener(_onGameStateChanged);
    super.dispose();
  }

  void _onGameStateChanged() {
    if (_isReady && !widget.gameController.isMoving) {
      _resolveMovingBlockPlacement();
    }

    if (mounted) setState(() {});
  }

  Future<void> _initializeScene() async {
    await Scene.initializeStaticResources();

    _blockMaterial = PhysicallyBasedMaterial()
      ..baseColorFactor = vm.Vector4(0.08, 0.5, 0.95, 1.0)
      ..metallicFactor = 0.05
      ..roughnessFactor = 0.65;

    _scene.directionalLight = DirectionalLight(
      direction: vm.Vector3(-0.5, -1.0, -0.35),
      intensity: 1.6,
    );
    _scene.add(
      Node(
        mesh: Mesh(
          _createBlockGeometry(GameConfig.blockWidth, GameConfig.blockDepth),
          _blockMaterial,
        ),
      ),
    );

    _isReady = true;
    _createMovingBlock();
    if (!widget.gameController.isMoving) {
      _resolveMovingBlockPlacement();
    }

    if (mounted) setState(() {});
  }

  CuboidGeometry _createBlockGeometry(double width, double depth) {
    return CuboidGeometry(vm.Vector3(width, GameConfig.blockHeight, depth));
  }

  void _createMovingBlock() {
    _hasResolvedPlacement = false;
    _movingDirection = 1.0;
    _movingBlock =
        Node(
            mesh: Mesh(
              _createBlockGeometry(_towerWidth, _towerDepth),
              _blockMaterial,
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
    final overlap = calculateBlockOverlap(
      below: BlockAxisRange(
        center: movesOnX ? _towerCenterX : _towerCenterZ,
        length: movesOnX ? _towerWidth : _towerDepth,
      ),
      current: BlockAxisRange(
        center: movesOnX ? position.x : position.z,
        length: movesOnX ? _towerWidth : _towerDepth,
      ),
    );

    if (!overlap.hasOverlap) {
      _movingBlock.visible = false;
      return;
    }

    if (movesOnX) {
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
    _movingBlock.mesh = Mesh(
      _createBlockGeometry(_towerWidth, _towerDepth),
      _blockMaterial,
    );

    widget.gameController.startNextBlock();
    _createMovingBlock();
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
    final nextCoordinate =
        currentCoordinate +
        _movingDirection * GameConfig.movingBlockSpeed * deltaSeconds;
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

        return SceneView(
          _scene,
          camera: _camera,
          autoTick: widget.gameController.isMoving,
          onTick: (_, deltaSeconds) {
            _updateCamera(deltaSeconds);
            _moveBlock(deltaSeconds, limit);
          },
        );
      },
    );
  }
}
