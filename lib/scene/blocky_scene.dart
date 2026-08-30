import 'dart:math' as math;
import 'dart:typed_data';

import 'package:blocky/game/block_theme.dart';
import 'package:blocky/game/game_haptics.dart';
import 'package:blocky/game/block_overlap.dart';
import 'package:blocky/game/blocky_game_controller.dart';
import 'package:blocky/game/game_config.dart';
import 'package:blocky/game/game_sound.dart';
import 'package:blocky/scene/block_theme_visual.dart';
import 'package:blocky/scene/scene_effect_models.dart';
import 'package:blocky/scene/scene_background_stars.dart';
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
  // Pedaços cortados só precisam colidir com a torre. Separá-los em camadas
  // evita que vários pedaços fora da tela fiquem simulando colisões entre si.
  static const _towerCollisionLayer = 0x1;
  static const _fallingPieceCollisionLayer = 0x2;

  static const _initialCameraPositionX = -7.0;
  static const _initialCameraPositionY = 9.4;
  static const _initialCameraPositionZ = -12.5;
  static const _initialCameraTargetY = 1.55;

  final Scene _scene = Scene();
  late final BlockThemeVisual _blockThemeVisual;
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
  final List<SceneFallingPiece> _fallingPieces = [];
  late final SceneBackgroundStars _backgroundStars;
  final List<SceneTransientParticleEffect> _transientParticleEffects = [];
  final List<ScenePerfectLightPulse> _perfectLightPulses = [];
  final List<ScenePerfectWobble> _perfectWobbles = [];
  final Map<Node, Node> _topFaceShades = {};
  final Map<Node, List<Node>> _surfaceDetails = {};
  final Map<Node, int> _surfaceDetailSeeds = {};
  late final SphereGeometry _cheeseHoleGeometry = SphereGeometry(
    radius: 1.0,
    segments: 12,
    rings: 8,
  );
  late final CuboidGeometry _surfaceDetailUnitCube = CuboidGeometry(
    vm.Vector3.all(1.0),
  );
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
    _backgroundStars = SceneBackgroundStars(scene: _scene, random: _random);
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
    SkyProgression.applyTo(_skySource, widget.gameController.score);
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
    _scene.removeAll();
    _fallingPieces.clear();
    _backgroundStars.clear();
    _transientParticleEffects.clear();
    _perfectLightPulses.clear();
    _perfectWobbles.clear();
    _topFaceShades.clear();
    _surfaceDetails.clear();
    _surfaceDetailSeeds.clear();
    _impactBlock = null;
    _impactElapsedSeconds = 0.0;
    _recoveryBlock = null;
    _recoveryAxis = null;
    _recoveryElapsedSeconds = 0.0;
    _sceneRound = widget.gameController.round;
    _hasResolvedPlacement = false;
    _gameOverCameraReveal.reset();
    _movingDirection = 1.0;
    _towerCenterX = 0.0;
    _towerCenterZ = 0.0;
    _towerTopY = 0.0;
    _towerWidth = GameConfig.blockWidth;
    _towerDepth = GameConfig.blockDepth;
    _lastReducedAxis = null;
    _initialBlockHue = _random.nextDouble() * 360.0;
    _skyVariation = SkyProgression.randomVariation(_random);
    _nextBlockColorIndex = 0;
    _resetCamera();
    SkyProgression.applyTo(
      _skySource,
      widget.gameController.score,
      variation: _skyVariation,
    );
    _backgroundStars.create();

    final baseBlockColorIndex = _nextBlockColorIndex++;
    final foundationTopY = -GameConfig.blockHeight / 2;
    _scene.add(
      Node(
          mesh: Mesh(
            CuboidGeometry(
              vm.Vector3(
                GameConfig.foundationBaseGlowWidth,
                GameConfig.foundationBaseGlowHeight,
                GameConfig.foundationBaseGlowDepth,
              ),
            ),
            _createFoundationBaseGlowMaterial(
              _linearBlockColor(baseBlockColorIndex),
            ),
          ),
        )
        ..position = vm.Vector3(
          0.0,
          foundationTopY -
              GameConfig.foundationHeight -
              GameConfig.foundationBaseGlowHeight / 2 -
              0.008,
          0.0,
        )
        ..castsShadows = false,
    );
    final foundation =
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
          );
    _addTowerCollider(
      foundation,
      width: GameConfig.foundationWidth,
      depth: GameConfig.foundationDepth,
      height: GameConfig.foundationHeight,
    );
    _scene.add(foundation);

    final baseBlock = _createBlockNode(
      width: GameConfig.blockWidth,
      depth: GameConfig.blockDepth,
      colorIndex: baseBlockColorIndex,
      material: _blockThemeVisual.createBlockMaterial(
        colorIndex: baseBlockColorIndex,
        initialHue: _initialBlockHue,
      ),
    );
    _addTowerCollider(
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

  MeshGeometry _createBlockGeometry(
    double width,
    double depth, {
    double height = GameConfig.blockHeight,
  }) {
    return CuboidGeometry(vm.Vector3(width, height, depth));
  }

  PhysicallyBasedMaterial _createFoundationBaseGlowMaterial(vm.Vector4 color) {
    return PhysicallyBasedMaterial()
      ..baseColorFactor = vm.Vector4(color.x, color.y, color.z, 0.48)
      ..emissiveFactor = vm.Vector4(color.x, color.y, color.z, 1.0)
      ..emissiveStrength = 1.1
      ..metallicFactor = 0.0
      ..roughnessFactor = 0.8
      ..alphaMode = AlphaMode.blend;
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
    _surfaceDetailSeeds[block] = _random.nextInt(0x7fffffff);
    _updateBlockSurfaceDetails(
      block,
      width: width,
      depth: depth,
      height: height,
      colorIndex: colorIndex,
    );
    return block;
  }

  void _updateBlockSurfaceDetails(
    Node block, {
    required double width,
    required double depth,
    required double height,
    required int colorIndex,
  }) {
    final existingDetails = _surfaceDetails.remove(block);
    if (existingDetails != null) {
      for (final detail in existingDetails) {
        block.remove(detail);
      }
    }

    switch (_blockThemeVisual.surfaceDetail) {
      case BlockSurfaceDetail.none:
        return;
      case BlockSurfaceDetail.classicTopSheen:
        _addClassicTopSheen(
          block,
          width: width,
          depth: depth,
          height: height,
          colorIndex: colorIndex,
        );
      case BlockSurfaceDetail.jellyTopHighlight:
        _addJellyTopHighlight(
          block,
          width: width,
          depth: depth,
          height: height,
          colorIndex: colorIndex,
        );
      case BlockSurfaceDetail.cheeseHoles:
        _addCheeseHoleDetails(
          block,
          width: width,
          depth: depth,
          height: height,
          colorIndex: colorIndex,
        );
      case BlockSurfaceDetail.chocolateSegments:
        _addChocolateSegmentDetails(
          block,
          width: width,
          depth: depth,
          height: height,
          colorIndex: colorIndex,
        );
    }
  }

  void _addCheeseHoleDetails(
    Node block, {
    required double width,
    required double depth,
    required double height,
    required int colorIndex,
  }) {
    final baseRadius = math.min(0.22, math.min(width, depth) * 0.12);
    if (baseRadius < 0.045) return;

    // Cada bloco recebe sua própria semente, mas ela é reutilizada quando a
    // geometria é recalculada após o corte. O padrão fica variado e estável.
    final seed = _surfaceDetailSeeds[block] ??= _random.nextInt(0x7fffffff);
    final random = math.Random(seed);
    final maximumTopHoleCount = width * depth < 0.85
        ? 1
        : width < 1.1 || depth < 1.1
        ? 2
        : 6;
    final topHoleCount = maximumTopHoleCount < 3
        ? maximumTopHoleCount
        : maximumTopHoleCount - 1 + random.nextInt(2);
    final material = _createCheeseHoleMaterial(colorIndex);
    final details = <Node>[];
    for (var index = 0; index < topHoleCount; index++) {
      final radius = baseRadius * (0.42 + random.nextDouble() * 0.72);
      final xFactor = -0.34 + random.nextDouble() * 0.68;
      final zFactor = -0.3 + random.nextDouble() * 0.62;
      final xStretch = 0.7 + random.nextDouble() * 0.64;
      final zStretch = 0.7 + random.nextDouble() * 0.64;
      _addCheeseHole(
        block,
        details,
        material: material,
        position: vm.Vector3(
          xFactor * width,
          height / 2 - radius * 0.22 + 0.016,
          zFactor * depth,
        ),
        scale: vm.Vector3(radius * xStretch, radius * 0.22, radius * zStretch),
      );
    }

    final sideHoleCount = topHoleCount > 2 ? 1 + random.nextInt(2) : 1;
    if (depth >= 0.65) {
      for (var index = 0; index < sideHoleCount; index++) {
        final radius = baseRadius * (0.45 + random.nextDouble() * 0.48);
        final yFactor = -0.24 + random.nextDouble() * 0.5;
        final zFactor = -0.26 + random.nextDouble() * 0.52;
        final zStretch = 0.72 + random.nextDouble() * 0.58;
        _addCheeseHole(
          block,
          details,
          material: material,
          position: vm.Vector3(
            -width / 2 + radius * 0.22 - 0.01,
            yFactor * height,
            zFactor * depth,
          ),
          scale: vm.Vector3(radius * 0.22, radius * 0.88, radius * zStretch),
        );
      }
    }
    if (width >= 0.65) {
      for (var index = 0; index < sideHoleCount; index++) {
        final radius = baseRadius * (0.45 + random.nextDouble() * 0.48);
        final xFactor = -0.28 + random.nextDouble() * 0.56;
        final yFactor = -0.24 + random.nextDouble() * 0.5;
        final xStretch = 0.72 + random.nextDouble() * 0.58;
        _addCheeseHole(
          block,
          details,
          material: material,
          position: vm.Vector3(
            xFactor * width,
            yFactor * height,
            -depth / 2 + radius * 0.22 - 0.01,
          ),
          scale: vm.Vector3(radius * xStretch, radius * 0.88, radius * 0.22),
        );
      }
    }
    _surfaceDetails[block] = details;
  }

  void _addCheeseHole(
    Node block,
    List<Node> details, {
    required PhysicallyBasedMaterial material,
    required vm.Vector3 position,
    required vm.Vector3 scale,
  }) {
    final hole = Node(mesh: Mesh(_cheeseHoleGeometry, material))
      ..position = position
      ..scale = scale
      // As cavidades usam a própria iluminação da cena, mas não precisam
      // atualizar o shadow map para parecerem profundas.
      ..castsShadows = false;
    block.add(hole);
    details.add(hole);
  }

  PhysicallyBasedMaterial _createCheeseHoleMaterial(int colorIndex) {
    final color = _linearBlockColor(colorIndex);
    return PhysicallyBasedMaterial()
      ..baseColorFactor = vm.Vector4(
        color.x * 0.48,
        color.y * 0.38,
        color.z * 0.12,
        1.0,
      )
      ..metallicFactor = 0.0
      ..roughnessFactor = 0.94;
  }

  void _addClassicTopSheen(
    Node block, {
    required double width,
    required double depth,
    required double height,
    required int colorIndex,
  }) {
    // O mesmo reflexo diagonal da miniatura da Home, mas em uma única malha
    // plana sobre o topo. Ele não altera a caixa lógica do bloco.
    final details = <Node>[];
    _addPreviewSideFaces(
      block,
      details,
      width: width,
      depth: depth,
      height: height,
      colorIndex: colorIndex,
    );
    final sheen = Node(
      mesh: Mesh(
        _createClassicTopSheenGeometry(
          width: width,
          depth: depth,
          height: height,
        ),
        _createClassicTopSheenMaterial(colorIndex),
      ),
    )..castsShadows = false;
    block.add(sheen);
    details.add(sheen);
    _surfaceDetails[block] = details;
  }

  MeshGeometry _createClassicTopSheenGeometry({
    required double width,
    required double depth,
    required double height,
  }) {
    final topY = height / 2 + 0.007;
    return MeshGeometry.fromArrays(
      positions: Float32List.fromList([
        // Retângulo largo e translúcido. Pela câmera isométrica ele assume
        // exatamente a forma de paralelogramo do preview da Home.
        -width * 0.42,
        topY,
        -depth * 0.2,
        width * 0.06,
        topY,
        -depth * 0.2,
        width * 0.06,
        topY,
        depth * 0.08,
        -width * 0.42,
        topY,
        depth * 0.08,
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
      indices: [0, 1, 2, 0, 2, 3],
    );
  }

  UnlitMaterial _createClassicTopSheenMaterial(int colorIndex) {
    // O passe translúcido da Scene pode ser ocultado pela camada de sombra do
    // topo. Pré-mesclar a cor reproduz a transparência visual em uma malha
    // opaca, que permanece nítida em qualquer ordem de renderização.
    const whiteMix = 0.34;
    final color = _linearBlockColor(colorIndex);
    return UnlitMaterial()
      ..baseColorFactor = vm.Vector4(
        color.x * (1 - whiteMix) + whiteMix,
        color.y * (1 - whiteMix) + whiteMix,
        color.z * (1 - whiteMix) + whiteMix,
        1.0,
      );
  }

  void _addJellyTopHighlight(
    Node block, {
    required double width,
    required double depth,
    required double height,
    required int colorIndex,
  }) {
    // O risco claro fica próximo da borda frontal da face superior. É um
    // detalhe visual independente da caixa lógica e acompanha cortes/restart.
    final details = <Node>[];
    _addPreviewSideFaces(
      block,
      details,
      width: width,
      depth: depth,
      height: height,
      colorIndex: colorIndex,
    );
    final highlight =
        Node(
            mesh: Mesh(
              _surfaceDetailUnitCube,
              _createJellyTopHighlightMaterial(),
            ),
          )
          ..position = vm.Vector3(
            // O highlight acompanha a lateral esquerda da face superior, e
            // não a borda frontal do bloco.
            -width / 2 + width * 0.055,
            height / 2 + 0.007,
            // Puxa o detalhe para a ponta frontal da lateral, deixando-o
            // visualmente mais baixo no enquadramento isométrico.
            -depth * 0.16,
          )
          ..scale = vm.Vector3(
            math.max(0.008, width * 0.009),
            0.005,
            // Não alcança a ponta inferior da lateral: fica uma margem que
            // evita a aparência de um contorno colado na borda.
            depth * 0.5,
          )
          ..castsShadows = false;
    block.add(highlight);
    details.add(highlight);
    _surfaceDetails[block] = details;
  }

  void _addPreviewSideFaces(
    Node block,
    List<Node> details, {
    required double width,
    required double depth,
    required double height,
    required int colorIndex,
  }) {
    // A câmera enxerga as faces -X (à esquerda) e -Z (à direita). Mantê-las
    // sem luz dinâmica reproduz o contraste deliberado do preview da Home:
    // esquerda clara e direita escura, em qualquer cor do tema.
    final leftFace = Node(
      mesh: Mesh(
        _createPreviewSideGeometry(
          width: width,
          depth: depth,
          height: height,
          leftSide: true,
        ),
        _createPreviewSideMaterial(colorIndex, brightness: 1.0),
      ),
    )..castsShadows = false;
    final rightFace = Node(
      mesh: Mesh(
        _createPreviewSideGeometry(
          width: width,
          depth: depth,
          height: height,
          leftSide: false,
        ),
        _createPreviewSideMaterial(colorIndex, brightness: 0.75),
      ),
    )..castsShadows = false;
    block
      ..add(leftFace)
      ..add(rightFace);
    details
      ..add(leftFace)
      ..add(rightFace);
  }

  MeshGeometry _createPreviewSideGeometry({
    required double width,
    required double depth,
    required double height,
    required bool leftSide,
  }) {
    const faceOffset = 0.005;
    final halfWidth = width / 2;
    final halfDepth = depth / 2;
    final halfHeight = height / 2;
    if (leftSide) {
      return MeshGeometry.fromArrays(
        positions: Float32List.fromList([
          -halfWidth - faceOffset,
          -halfHeight,
          halfDepth,
          -halfWidth - faceOffset,
          -halfHeight,
          -halfDepth,
          -halfWidth - faceOffset,
          halfHeight,
          halfDepth,
          -halfWidth - faceOffset,
          halfHeight,
          -halfDepth,
        ]),
        normals: Float32List.fromList([
          -1.0,
          0.0,
          0.0,
          -1.0,
          0.0,
          0.0,
          -1.0,
          0.0,
          0.0,
          -1.0,
          0.0,
          0.0,
        ]),
        indices: [0, 2, 1, 1, 2, 3],
      );
    }

    return MeshGeometry.fromArrays(
      positions: Float32List.fromList([
        -halfWidth,
        -halfHeight,
        -halfDepth - faceOffset,
        halfWidth,
        -halfHeight,
        -halfDepth - faceOffset,
        -halfWidth,
        halfHeight,
        -halfDepth - faceOffset,
        halfWidth,
        halfHeight,
        -halfDepth - faceOffset,
      ]),
      normals: Float32List.fromList([
        0.0,
        0.0,
        -1.0,
        0.0,
        0.0,
        -1.0,
        0.0,
        0.0,
        -1.0,
        0.0,
        0.0,
        -1.0,
      ]),
      indices: [0, 2, 1, 1, 2, 3],
    );
  }

  UnlitMaterial _createPreviewSideMaterial(
    int colorIndex, {
    required double brightness,
  }) {
    final color = _linearBlockColor(colorIndex);
    return UnlitMaterial()
      ..baseColorFactor = vm.Vector4(
        color.x * brightness,
        color.y * brightness,
        color.z * brightness,
        1.0,
      );
  }

  PhysicallyBasedMaterial _createJellyTopHighlightMaterial() {
    return PhysicallyBasedMaterial()
      ..baseColorFactor = vm.Vector4(1.0, 1.0, 0.99, 0.28)
      ..emissiveFactor = vm.Vector4(1.0, 1.0, 0.97, 1.0)
      ..emissiveStrength = 0.04
      ..metallicFactor = 0.0
      ..roughnessFactor = 0.48
      ..alphaMode = AlphaMode.blend;
  }

  void _addChocolateSegmentDetails(
    Node block, {
    required double width,
    required double depth,
    required double height,
    required int colorIndex,
  }) {
    const grooveThickness = 0.035;
    const grooveHeight = 0.016;
    const sideGrooveDepth = 0.014;
    const inset = 0.07;
    final columns = width >= 2.6
        ? 4
        : width >= 1.45
        ? 3
        : width >= 0.5
        ? 2
        : 1;
    final rows = depth >= 2.6
        ? 4
        : depth >= 1.45
        ? 3
        : depth >= 0.5
        ? 2
        : 1;
    final material = _createChocolateGrooveMaterial(colorIndex);
    final details = <Node>[];

    for (var column = 1; column < columns; column++) {
      final x = -width / 2 + width * column / columns;
      _addSurfaceDetail(
        block,
        details,
        material: material,
        position: vm.Vector3(x, height / 2 + grooveHeight / 2 + 0.004, 0.0),
        scale: vm.Vector3(
          grooveThickness,
          grooveHeight,
          math.max(0.01, depth - inset * 2),
        ),
      );
      // Sulco correspondente na face voltada para a câmera.
      _addSurfaceDetail(
        block,
        details,
        material: material,
        position: vm.Vector3(x, 0.0, -depth / 2 - sideGrooveDepth / 2),
        scale: vm.Vector3(grooveThickness, height * 0.9, sideGrooveDepth),
      );
    }

    for (var row = 1; row < rows; row++) {
      final z = -depth / 2 + depth * row / rows;
      _addSurfaceDetail(
        block,
        details,
        material: material,
        position: vm.Vector3(0.0, height / 2 + grooveHeight / 2 + 0.004, z),
        scale: vm.Vector3(
          math.max(0.01, width - inset * 2),
          grooveHeight,
          grooveThickness,
        ),
      );
      _addSurfaceDetail(
        block,
        details,
        material: material,
        position: vm.Vector3(-width / 2 - sideGrooveDepth / 2, 0.0, z),
        scale: vm.Vector3(sideGrooveDepth, height * 0.9, grooveThickness),
      );
    }
    _surfaceDetails[block] = details;
  }

  PhysicallyBasedMaterial _createChocolateGrooveMaterial(int colorIndex) {
    final color = _linearBlockColor(colorIndex);
    return PhysicallyBasedMaterial()
      ..baseColorFactor = vm.Vector4(
        color.x * 0.62,
        color.y * 0.48,
        color.z * 0.33,
        1.0,
      )
      ..metallicFactor = 0.0
      ..roughnessFactor = 0.6;
  }

  void _addSurfaceDetail(
    Node block,
    List<Node> details, {
    required PhysicallyBasedMaterial material,
    required vm.Vector3 position,
    required vm.Vector3 scale,
  }) {
    final detail = Node(mesh: Mesh(_surfaceDetailUnitCube, material))
      ..position = position
      ..scale = scale
      // Um relevo muito baixo, mas que ainda projeta uma sombra de contato,
      // faz os traços parecerem ranhuras do tablete sem escurecer o material.
      ..castsShadows = true;
    block.add(detail);
    details.add(detail);
  }

  void _addTowerCollider(
    Node block, {
    required double width,
    required double depth,
    double height = GameConfig.blockHeight,
  }) {
    block
      ..addComponent(RigidBody(type: BodyType.fixed))
      ..addComponent(
        Collider(
          shape: BoxShape(
            halfExtents: vm.Vector3(width / 2, height / 2, depth / 2),
          ),
          collisionLayer: _towerCollisionLayer,
          collisionMask: _fallingPieceCollisionLayer,
        ),
      );
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
    _updateBlockSurfaceDetails(
      block,
      width: width,
      depth: depth,
      height: GameConfig.blockHeight,
      colorIndex: colorIndex,
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
          widget.gameController.isPerfectRecoveryReady &&
          _applyPerfectRecovery();
      if (recovered) {
        widget.gameController.completePerfectRecovery();
        _createPerfectParticleEffect(_movingBlock.position, isRecovery: true);
      } else {
        _playPlacementImpact(_movingBlock);
      }
      if (isPerfect) {
        _createPerfectLightPulse(_movingBlock);
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
      _addTowerCollider(_movingBlock, width: _towerWidth, depth: _towerDepth);
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
          // As sobras colidem com a torre, mas não entre si: isso mantém o
          // efeito convincente sem deixar objetos fora da tela se acumularem.
          ..addComponent(
            Collider(
              shape: BoxShape(
                halfExtents: vm.Vector3(
                  width / 2,
                  GameConfig.blockHeight / 2,
                  depth / 2,
                ),
              ),
              collisionLayer: _fallingPieceCollisionLayer,
              collisionMask: _towerCollisionLayer,
            ),
          );

    _scene.add(piece);
    _fallingPieces.add(SceneFallingPiece(piece));
  }

  void _removeFallenPieces() {
    final removalY = _towerTopY - GameConfig.fallingPieceCleanupDistance;
    var removedPiece = false;
    _fallingPieces.removeWhere((piece) {
      if (piece.node.position.y > removalY) return false;

      _scene.remove(piece.node);
      _topFaceShades.remove(piece.node);
      _surfaceDetails.remove(piece.node);
      _surfaceDetailSeeds.remove(piece.node);
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

  void _createPerfectLightPulse(Node block) {
    final color = _linearBlockColor(_movingBlockColorIndex);
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
                vm.Vector3(
                  _towerWidth,
                  GameConfig.perfectLightPulseHeight,
                  _towerDepth,
                ),
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
    _perfectLightPulses.add(
      ScenePerfectLightPulse(node: pulse, material: material, color: color),
    );
  }

  void _updatePerfectLightPulses(double deltaSeconds) {
    if (_perfectLightPulses.isEmpty) return;

    final duration =
        GameConfig.perfectLightPulseDuration.inMicroseconds /
        Duration.microsecondsPerSecond;
    var completedEffect = false;
    _perfectLightPulses.removeWhere((pulse) {
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
      completedEffect = true;
      return true;
    });

    if (completedEffect && mounted) setState(() {});
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
      SceneTransientParticleEffect(
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
      ScenePerfectWobble(
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
    final originalLength = widget.gameController.movingAxis == MovingBlockAxis.x
        ? GameConfig.blockWidth
        : GameConfig.blockDepth;
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
    final movesOnX = widget.gameController.movingAxis == MovingBlockAxis.x;
    final currentCoordinate = movesOnX ? position.x : position.z;
    final movementCenter = movesOnX ? _towerCenterX : _towerCenterZ;
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
      towerCenterX: _towerCenterX,
      towerCenterZ: _towerCenterZ,
      towerTopY: _towerTopY,
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
    final desiredPositionX = _initialCameraPositionX + _towerCenterX;
    final desiredPositionY = _initialCameraPositionY + _towerTopY;
    final desiredPositionZ = _initialCameraPositionZ + _towerCenterZ;
    final desiredTargetX = _towerCenterX;
    final desiredTargetY = _initialCameraTargetY + _towerTopY;
    final desiredTargetZ = _towerCenterZ;
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
              _fallingPieces.isNotEmpty ||
              _impactBlock != null ||
              _recoveryBlock != null ||
              _gameOverCameraReveal.isActive ||
              _perfectWobbles.isNotEmpty ||
              _perfectLightPulses.isNotEmpty ||
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
              _updateGameOverCameraReveal(deltaSeconds);
              _updateBackgroundStars(deltaSeconds);
              _updatePlacementImpact(deltaSeconds);
              _updatePerfectRecoveryGrowth(deltaSeconds);
              _updatePerfectWobbles(deltaSeconds);
              _updatePerfectLightPulses(deltaSeconds);
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
