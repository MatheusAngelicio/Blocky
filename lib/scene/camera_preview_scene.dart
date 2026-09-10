import 'dart:math' as math;

import 'package:blocky/game/block_theme.dart';
import 'package:blocky/game/game_config.dart';
import 'package:blocky/scene/block_theme_scene_renderer.dart';
import 'package:blocky/scene/block_theme_visual.dart';
import 'package:blocky/scene/scene_block_factory.dart';
import 'package:blocky/scene/sky_progression.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_scene/scene.dart';
import 'package:vector_math/vector_math.dart' as vm;

/// Cena estática para testar a órbita da câmera sem iniciar uma partida.
class CameraPreviewScene extends StatefulWidget {
  const CameraPreviewScene({
    super.key,
    required this.cameraAngle,
    required this.blockTheme,
  });

  final double cameraAngle;
  final BlockTheme blockTheme;

  @override
  State<CameraPreviewScene> createState() => _CameraPreviewSceneState();
}

class _CameraPreviewSceneState extends State<CameraPreviewScene> {
  static const _initialHue = 210.0;

  final Scene _scene = Scene();
  final PerspectiveCamera _camera = PerspectiveCamera(
    position: vm.Vector3(
      GameConfig.cameraInitialPositionX,
      GameConfig.cameraInitialPositionY,
      GameConfig.cameraInitialPositionZ,
    ),
    target: vm.Vector3(0.0, GameConfig.cameraInitialTargetY, 0.0),
  );
  final math.Random _random = math.Random(12);
  late final BlockThemeVisual _visual;
  late final SceneBlockFactory _blockFactory;
  var _isReady = false;

  @override
  void initState() {
    super.initState();
    _visual = BlockThemeVisual.forTheme(widget.blockTheme);
    _blockFactory = SceneBlockFactory(
      themeRenderer: BlockThemeSceneRenderer(
        visual: _visual,
        colorForIndex: _colorForIndex,
        random: _random,
      ),
      colorForIndex: _colorForIndex,
    );
    _initialize();
  }

  @override
  void didUpdateWidget(CameraPreviewScene oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.cameraAngle != widget.cameraAngle) _updateCamera();
  }

  @override
  void dispose() {
    _blockFactory.clear();
    _scene.removeAll();
    super.dispose();
  }

  Future<void> _initialize() async {
    await Scene.initializeStaticResources();
    if (!mounted) return;

    final sky = GradientSkySource(
      sunDirection: vm.Vector3(-0.45, 0.75, -0.5),
      sunSharpness: 1200.0,
    );
    SkyProgression.applyTo(sky, 0, theme: widget.blockTheme);
    _scene.skybox = Skybox(sky);
    _scene.directionalLight = DirectionalLight(
      direction: vm.Vector3(-0.45, -1.0, -0.5),
      intensity: 2.1,
      castsShadow: true,
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
    _createPreviewTower();
    _updateCamera();
    setState(() => _isReady = true);
  }

  vm.Vector4 _colorForIndex(int colorIndex) {
    return _visual.blockColor(colorIndex, initialHue: _initialHue);
  }

  void _createPreviewTower() {
    final foundationTopY = -GameConfig.blockHeight / 2;
    _scene.add(
      _blockFactory.createFoundationGlow(
        topY: foundationTopY,
        color: _colorForIndex(0),
      ),
    );
    final foundation =
        _blockFactory.createBlock(
            width: GameConfig.foundationWidth,
            depth: GameConfig.foundationDepth,
            height: GameConfig.foundationHeight,
            colorIndex: 0,
            material: _visual.createBlockMaterial(
              colorIndex: 0,
              initialHue: _initialHue,
            ),
          )
          ..position = vm.Vector3(
            0.0,
            foundationTopY - GameConfig.foundationHeight / 2,
            0.0,
          );
    _scene.add(foundation);

    for (var index = 0; index < 5; index++) {
      final offset = index * 0.08;
      final block =
          _blockFactory.createBlock(
              width: GameConfig.blockWidth - index * 0.14,
              depth: GameConfig.blockDepth - index * 0.12,
              colorIndex: index,
              material: _visual.createBlockMaterial(
                colorIndex: index,
                initialHue: _initialHue,
              ),
            )
            ..position = vm.Vector3(
              index.isEven ? offset : -offset,
              index * GameConfig.blockVerticalStep,
              index.isEven ? -offset : offset,
            );
      _scene.add(block);
    }
  }

  void _updateCamera() {
    _camera.position = vm.Vector3(
      GameConfig.cameraPositionXForAngle(widget.cameraAngle),
      GameConfig.cameraInitialPositionY,
      GameConfig.cameraPositionZForAngle(widget.cameraAngle),
    );
    _camera.target = vm.Vector3(0.0, GameConfig.blockHeight * 1.25, 0.0);
  }

  @override
  Widget build(BuildContext context) {
    if (!_isReady) return const SizedBox.expand();

    return SceneView(_scene, camera: _camera, autoTick: true);
  }
}
