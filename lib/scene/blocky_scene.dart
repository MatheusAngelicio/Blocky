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
  final Scene _scene = Scene();
  late final Node _movingBlock;
  late final PhysicallyBasedMaterial _blockMaterial;
  final PerspectiveCamera _camera = PerspectiveCamera(
    // Aumente o módulo de Z para afastar a câmera; diminua para aproximá-la.
    // Ajuste position.y para alterar a altura física da câmera.
    // Ajuste target.y para o enquadramento vertical: aumente-o para fazer os
    // blocos aparecerem mais abaixo na tela; diminua-o para fazê-los subir.
    position: vm.Vector3(0.0, 9.8, -17.0),
    target: vm.Vector3(0.0, 2.0, 0.0),
  );

  bool _isReady = false;
  bool _hasResolvedPlacement = false;
  double _movingDirection = 1.0;

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

    final geometry = CuboidGeometry(
      vm.Vector3(
        GameConfig.blockWidth,
        GameConfig.blockHeight,
        GameConfig.blockDepth,
      ),
    );
    _blockMaterial = PhysicallyBasedMaterial()
      ..baseColorFactor = vm.Vector4(0.08, 0.5, 0.95, 1.0)
      ..metallicFactor = 0.05
      ..roughnessFactor = 0.65;

    _scene.directionalLight = DirectionalLight(
      direction: vm.Vector3(-0.5, -1.0, -0.35),
      intensity: 1.6,
    );
    _scene.add(Node(mesh: Mesh(geometry, _blockMaterial)));
    _movingBlock = Node(mesh: Mesh(geometry, _blockMaterial))
      ..position = vm.Vector3(0.0, GameConfig.movingBlockCenterY, 0.0);
    _scene.add(_movingBlock);

    _isReady = true;
    if (!widget.gameController.isMoving) {
      _resolveMovingBlockPlacement();
    }

    if (mounted) {
      setState(() {});
    }
  }

  void _resolveMovingBlockPlacement() {
    if (_hasResolvedPlacement) return;

    _hasResolvedPlacement = true;
    final overlap = calculateBlockOverlap(
      below: const BlockFootprint(centerX: 0.0, width: GameConfig.blockWidth),
      current: BlockFootprint(
        centerX: _movingBlock.position.x,
        width: GameConfig.blockWidth,
      ),
    );

    if (!overlap.hasOverlap) {
      _movingBlock.visible = false;
      return;
    }

    _movingBlock.position = vm.Vector3(
      overlap.centerX,
      GameConfig.movingBlockCenterY,
      0.0,
    );
    _movingBlock.mesh = Mesh(
      CuboidGeometry(
        vm.Vector3(
          overlap.width,
          GameConfig.blockHeight,
          GameConfig.blockDepth,
        ),
      ),
      _blockMaterial,
    );
  }

  double _movementLimit(Size viewport) {
    final viewDirection = (_camera.target - _camera.position)..normalize();
    final blockPosition = vm.Vector3(0.0, GameConfig.movingBlockCenterY, 0.0);
    final depth = (blockPosition - _camera.position).dot(viewDirection);
    final halfFovX = math.atan(
      math.tan(_camera.fovRadiansY / 2) * viewport.aspectRatio,
    );
    final visibleHalfWidth = depth * math.tan(halfFovX);

    return math.max(0.0, visibleHalfWidth - GameConfig.blockWidth / 2);
  }

  void _moveBlock(double deltaSeconds, double limit) {
    if (!widget.gameController.isMoving || limit == 0.0) return;

    final nextX =
        _movingBlock.position.x +
        _movingDirection * GameConfig.movingBlockSpeed * deltaSeconds;
    if (nextX >= limit || nextX <= -limit) {
      _movingDirection = -_movingDirection;
    }

    _movingBlock.position = vm.Vector3(
      nextX.clamp(-limit, limit),
      GameConfig.movingBlockCenterY,
      0.0,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isReady) {
      return const SizedBox.expand();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final limit = _movementLimit(constraints.biggest);

        return SceneView(
          _scene,
          camera: _camera,
          autoTick: widget.gameController.isMoving,
          onTick: (_, deltaSeconds) => _moveBlock(deltaSeconds, limit),
        );
      },
    );
  }
}
