import 'dart:math' as math;
import 'dart:typed_data';

import 'package:blocky/scene/block_theme_visual.dart';
import 'package:flutter_scene/scene.dart';
import 'package:vector_math/vector_math.dart' as vm;

/// Renderiza detalhes 3D próprios de um tema, sem conhecer regras do jogo.
///
/// O retorno permite que a Scene descarte os Nodes decorativos quando um bloco
/// é cortado ou removido, sem que o renderer controle o ciclo da partida.
class BlockThemeSceneRenderer {
  BlockThemeSceneRenderer({
    required BlockThemeVisual visual,
    required BlockThemeColorResolver colorForIndex,
    required math.Random random,
  }) : _visual = visual,
       _colorForIndex = colorForIndex,
       _random = random;

  final BlockThemeVisual _visual;
  final BlockThemeColorResolver _colorForIndex;
  final math.Random _random;
  final Map<Node, List<Node>> _detailsByBlock = {};
  final Map<Node, int> _detailSeeds = {};
  late final SphereGeometry _cheeseHoleGeometry = SphereGeometry(
    radius: 1.0,
    segments: 12,
    rings: 8,
  );
  late final CuboidGeometry _unitCube = CuboidGeometry(vm.Vector3.all(1.0));

  void updateDetails({
    required Node block,
    required double width,
    required double depth,
    required double height,
    required int colorIndex,
  }) {
    // Preserva a sequência aleatória anterior: cada bloco recebe uma semente
    // na criação, mesmo quando o tema atual não usa detalhes randômicos.
    _detailSeeds[block] ??= _random.nextInt(0x7fffffff);
    final previousDetails = _detailsByBlock.remove(block);
    if (previousDetails != null) {
      for (final detail in previousDetails) {
        block.remove(detail);
      }
    }

    final details = switch (_visual.surfaceDetail) {
      BlockSurfaceDetail.none => <Node>[],
      BlockSurfaceDetail.classicTopSheen => _createClassicDetails(
        block: block,
        width: width,
        depth: depth,
        height: height,
        colorIndex: colorIndex,
      ),
      BlockSurfaceDetail.jellyTopHighlight => _createJellyDetails(
        block: block,
        width: width,
        depth: depth,
        height: height,
        colorIndex: colorIndex,
      ),
      BlockSurfaceDetail.cheeseHoles => _createCheeseDetails(
        block: block,
        width: width,
        depth: depth,
        height: height,
        colorIndex: colorIndex,
      ),
      BlockSurfaceDetail.chocolateSegments => _createChocolateDetails(
        block: block,
        width: width,
        depth: depth,
        height: height,
        colorIndex: colorIndex,
      ),
    };
    if (details.isNotEmpty) _detailsByBlock[block] = details;
  }

  void forget(Node block) {
    _detailsByBlock.remove(block);
    _detailSeeds.remove(block);
  }

  void clear() {
    _detailsByBlock.clear();
    _detailSeeds.clear();
  }

  List<Node> _createClassicDetails({
    required Node block,
    required double width,
    required double depth,
    required double height,
    required int colorIndex,
  }) {
    final details = _createPreviewSideFaces(
      block: block,
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
    return details;
  }

  List<Node> _createJellyDetails({
    required Node block,
    required double width,
    required double depth,
    required double height,
    required int colorIndex,
  }) {
    final details = _createPreviewSideFaces(
      block: block,
      width: width,
      depth: depth,
      height: height,
      colorIndex: colorIndex,
    );
    final highlight =
        Node(
            mesh: Mesh(
              CuboidGeometry(vm.Vector3.all(1.0)),
              _createJellyTopHighlightMaterial(),
            ),
          )
          ..position = vm.Vector3(
            -width / 2 + width * 0.055,
            height / 2 + 0.007,
            -depth * 0.16,
          )
          ..scale = vm.Vector3(
            math.max(0.008, width * 0.009),
            0.005,
            depth * 0.5,
          )
          ..castsShadows = false;
    block.add(highlight);
    details.add(highlight);
    return details;
  }

  List<Node> _createCheeseDetails({
    required Node block,
    required double width,
    required double depth,
    required double height,
    required int colorIndex,
  }) {
    final baseRadius = math.min(0.22, math.min(width, depth) * 0.12);
    if (baseRadius < 0.045) return [];

    final seed = _detailSeeds[block] ??= _random.nextInt(0x7fffffff);
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
      _addCheeseHole(
        block,
        details,
        material: material,
        position: vm.Vector3(
          (-0.34 + random.nextDouble() * 0.68) * width,
          height / 2 - radius * 0.22 + 0.016,
          (-0.3 + random.nextDouble() * 0.62) * depth,
        ),
        scale: vm.Vector3(
          radius * (0.7 + random.nextDouble() * 0.64),
          radius * 0.22,
          radius * (0.7 + random.nextDouble() * 0.64),
        ),
      );
    }

    final sideHoleCount = topHoleCount > 2 ? 1 + random.nextInt(2) : 1;
    if (depth >= 0.65) {
      for (var index = 0; index < sideHoleCount; index++) {
        final radius = baseRadius * (0.45 + random.nextDouble() * 0.48);
        _addCheeseHole(
          block,
          details,
          material: material,
          position: vm.Vector3(
            -width / 2 + radius * 0.22 - 0.01,
            (-0.24 + random.nextDouble() * 0.5) * height,
            (-0.26 + random.nextDouble() * 0.52) * depth,
          ),
          scale: vm.Vector3(
            radius * 0.22,
            radius * 0.88,
            radius * (0.72 + random.nextDouble() * 0.58),
          ),
        );
      }
    }
    if (width >= 0.65) {
      for (var index = 0; index < sideHoleCount; index++) {
        final radius = baseRadius * (0.45 + random.nextDouble() * 0.48);
        _addCheeseHole(
          block,
          details,
          material: material,
          position: vm.Vector3(
            (-0.28 + random.nextDouble() * 0.56) * width,
            (-0.24 + random.nextDouble() * 0.5) * height,
            -depth / 2 + radius * 0.22 - 0.01,
          ),
          scale: vm.Vector3(
            radius * (0.72 + random.nextDouble() * 0.58),
            radius * 0.88,
            radius * 0.22,
          ),
        );
      }
    }
    return details;
  }

  List<Node> _createChocolateDetails({
    required Node block,
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
      _addCuboidDetail(
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
      _addCuboidDetail(
        block,
        details,
        material: material,
        position: vm.Vector3(x, 0.0, -depth / 2 - sideGrooveDepth / 2),
        scale: vm.Vector3(grooveThickness, height * 0.9, sideGrooveDepth),
      );
    }
    for (var row = 1; row < rows; row++) {
      final z = -depth / 2 + depth * row / rows;
      _addCuboidDetail(
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
      _addCuboidDetail(
        block,
        details,
        material: material,
        position: vm.Vector3(-width / 2 - sideGrooveDepth / 2, 0.0, z),
        scale: vm.Vector3(sideGrooveDepth, height * 0.9, grooveThickness),
      );
    }
    return details;
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
      ..castsShadows = false;
    block.add(hole);
    details.add(hole);
  }

  void _addCuboidDetail(
    Node block,
    List<Node> details, {
    required PhysicallyBasedMaterial material,
    required vm.Vector3 position,
    required vm.Vector3 scale,
  }) {
    final detail = Node(mesh: Mesh(_unitCube, material))
      ..position = position
      ..scale = scale
      ..castsShadows = true;
    block.add(detail);
    details.add(detail);
  }

  List<Node> _createPreviewSideFaces({
    required Node block,
    required double width,
    required double depth,
    required double height,
    required int colorIndex,
  }) {
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
    return [leftFace, rightFace];
  }

  MeshGeometry _createClassicTopSheenGeometry({
    required double width,
    required double depth,
    required double height,
  }) {
    final topY = height / 2 + 0.007;
    return MeshGeometry.fromArrays(
      positions: Float32List.fromList([
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

  UnlitMaterial _createClassicTopSheenMaterial(int colorIndex) {
    const whiteMix = 0.34;
    final color = _colorForIndex(colorIndex);
    return UnlitMaterial()
      ..baseColorFactor = vm.Vector4(
        color.x * (1 - whiteMix) + whiteMix,
        color.y * (1 - whiteMix) + whiteMix,
        color.z * (1 - whiteMix) + whiteMix,
        1.0,
      );
  }

  UnlitMaterial _createPreviewSideMaterial(
    int colorIndex, {
    required double brightness,
  }) {
    final color = _colorForIndex(colorIndex);
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

  PhysicallyBasedMaterial _createCheeseHoleMaterial(int colorIndex) {
    final color = _colorForIndex(colorIndex);
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

  PhysicallyBasedMaterial _createChocolateGrooveMaterial(int colorIndex) {
    final color = _colorForIndex(colorIndex);
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
}

typedef BlockThemeColorResolver = vm.Vector4 Function(int colorIndex);
