import 'dart:math' as math;
import 'dart:typed_data';

import 'package:blocky/game/game_config.dart';
import 'package:blocky/scene/block_theme_scene_renderer.dart';
import 'package:flutter_scene/physics.dart';
import 'package:flutter_scene/scene.dart';
import 'package:vector_math/vector_math.dart' as vm;

/// Cria e mantém a representação 3D comum dos blocos da partida.
///
/// A fábrica conhece geometria, materiais auxiliares, detalhes do tema e
/// colliders, mas não conhece overlap, score ou progressão da torre.
class SceneBlockFactory {
  SceneBlockFactory({
    required BlockThemeSceneRenderer themeRenderer,
    required BlockThemeColorResolver colorForIndex,
  }) : _themeRenderer = themeRenderer,
       _colorForIndex = colorForIndex;

  static const towerCollisionLayer = 0x1;
  static const fallingPieceCollisionLayer = 0x2;

  final BlockThemeSceneRenderer _themeRenderer;
  final BlockThemeColorResolver _colorForIndex;
  final Map<Node, Node> _topFaceShades = {};

  Node createFoundationGlow({required double topY, required vm.Vector4 color}) {
    return Node(
        mesh: Mesh(
          CuboidGeometry(
            vm.Vector3(
              GameConfig.foundationBaseGlowWidth,
              GameConfig.foundationBaseGlowHeight,
              GameConfig.foundationBaseGlowDepth,
            ),
          ),
          _createFoundationGlowMaterial(color),
        ),
      )
      ..position = vm.Vector3(
        0.0,
        topY -
            GameConfig.foundationHeight -
            GameConfig.foundationBaseGlowHeight / 2 -
            0.008,
        0.0,
      )
      ..castsShadows = false;
  }

  Node createBlock({
    required double width,
    required double depth,
    double height = GameConfig.blockHeight,
    required int colorIndex,
    required PhysicallyBasedMaterial material,
    bool includeThemeDetails = true,
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
          ..castsShadows = false;
    block.add(topFaceShade);
    _topFaceShades[block] = topFaceShade;
    if (includeThemeDetails) {
      _themeRenderer.updateDetails(
        block: block,
        width: width,
        depth: depth,
        height: height,
        colorIndex: colorIndex,
      );
    }
    return block;
  }

  void updateBlock({
    required Node block,
    required double width,
    required double depth,
    double height = GameConfig.blockHeight,
    required int colorIndex,
    required PhysicallyBasedMaterial material,
  }) {
    block.mesh = Mesh(
      _createBlockGeometry(width, depth, height: height),
      material,
    );
    final topFaceShade = _topFaceShades[block];
    if (topFaceShade != null) {
      topFaceShade
        ..mesh = Mesh(
          _createTopFaceShadeGeometry(width, depth),
          _createTopFaceShadeMaterial(colorIndex),
        )
        ..position = vm.Vector3(0.0, height / 2 + 0.003, 0.0);
    }
    _themeRenderer.updateDetails(
      block: block,
      width: width,
      depth: depth,
      height: height,
      colorIndex: colorIndex,
    );
  }

  void addTowerCollider(
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
          collisionLayer: towerCollisionLayer,
          collisionMask: fallingPieceCollisionLayer,
        ),
      );
  }

  void forget(Node block) {
    _topFaceShades.remove(block);
    _themeRenderer.forget(block);
  }

  void clear() {
    _topFaceShades.clear();
    _themeRenderer.clear();
  }

  MeshGeometry _createBlockGeometry(
    double width,
    double depth, {
    required double height,
  }) {
    return CuboidGeometry(vm.Vector3(width, height, depth));
  }

  PhysicallyBasedMaterial _createFoundationGlowMaterial(vm.Vector4 color) {
    return PhysicallyBasedMaterial()
      ..baseColorFactor = vm.Vector4(color.x, color.y, color.z, 0.48)
      ..emissiveFactor = vm.Vector4(color.x, color.y, color.z, 1.0)
      ..emissiveStrength = 1.1
      ..metallicFactor = 0.0
      ..roughnessFactor = 0.8
      ..alphaMode = AlphaMode.blend;
  }

  MeshGeometry _createTopFaceShadeGeometry(double width, double depth) {
    const inset = 0.006;
    final halfWidth = math.max(0.001, width / 2 - inset);
    final halfDepth = math.max(0.001, depth / 2 - inset);

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
      ..baseColorFactor = _colorForIndex(colorIndex)
      ..metallicFactor = 0.0
      ..roughnessFactor = 0.78
      ..vertexColorWeight = 1.0;
  }
}
