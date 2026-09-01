import 'dart:math' as math;

import 'package:blocky/game/block_overlap.dart';
import 'package:blocky/game/game_config.dart';
import 'package:blocky/scene/block_theme_visual.dart';
import 'package:blocky/scene/scene_block_factory.dart';
import 'package:blocky/scene/scene_effect_models.dart';
import 'package:flutter_scene/physics.dart';
import 'package:flutter_scene/scene.dart';
import 'package:vector_math/vector_math.dart' as vm;

/// Controla exclusivamente os pedaços físicos removidos durante um corte.
class SceneFallingPieceManager {
  SceneFallingPieceManager({
    required Scene scene,
    required SceneBlockFactory blockFactory,
    required BlockFallingVisual fallingVisual,
  }) : _scene = scene,
       _blockFactory = blockFactory,
       _fallingVisual = fallingVisual;

  final Scene _scene;
  final SceneBlockFactory _blockFactory;
  final BlockFallingVisual _fallingVisual;
  final List<SceneFallingPiece> _pieces = [];

  bool get hasActivePieces => _pieces.isNotEmpty;

  /// Cria a sobra do corte e retorna sua posição para efeitos visuais.
  vm.Vector3? createCutPiece({
    required bool movesOnX,
    required BlockAxisRange current,
    required BlockOverlap overlap,
    required vm.Vector3 blockPosition,
    required double towerWidth,
    required double towerDepth,
    required int colorIndex,
    required PhysicallyBasedMaterial material,
  }) {
    final cutRange = calculateCutOffRange(current: current, overlap: overlap);
    if (cutRange == null) return null;

    final width = movesOnX ? cutRange.length : towerWidth;
    final depth = movesOnX ? towerDepth : cutRange.length;
    final piecePosition = movesOnX
        ? vm.Vector3(cutRange.center, blockPosition.y, blockPosition.z)
        : vm.Vector3(blockPosition.x, blockPosition.y, cutRange.center);
    final movesTowardsPositiveAxis = cutRange.center > overlap.center;
    final outwardDirection = movesTowardsPositiveAxis ? 1.0 : -1.0;
    final linearVelocity = movesOnX
        ? vm.Vector3(
            outwardDirection * GameConfig.fallingPieceOutwardSpeed,
            0.0,
            0.0,
          )
        : vm.Vector3(
            0.0,
            0.0,
            outwardDirection * GameConfig.fallingPieceOutwardSpeed,
          );
    final angularVelocity = movesOnX
        ? vm.Vector3(
            0.0,
            0.0,
            outwardDirection * GameConfig.fallingPieceAngularSpeed,
          )
        : vm.Vector3(
            outwardDirection * GameConfig.fallingPieceAngularSpeed,
            0.0,
            0.0,
          );
    final piece =
        _blockFactory.createBlock(
            width: width,
            depth: depth,
            colorIndex: colorIndex,
            material: material,
          )
          ..position = piecePosition
          ..addComponent(
            RigidBody(
              mass: GameConfig.fallingPieceMass,
              linearVelocity: linearVelocity,
              angularVelocity: angularVelocity,
            ),
          )
          ..addComponent(
            Collider(
              shape: BoxShape(
                halfExtents: vm.Vector3(
                  width / 2,
                  GameConfig.blockHeight / 2,
                  depth / 2,
                ),
              ),
              collisionLayer: SceneBlockFactory.fallingPieceCollisionLayer,
              collisionMask: SceneBlockFactory.towerCollisionLayer,
            ),
          );

    _scene.add(piece);
    _pieces.add(SceneFallingPiece(piece));
    return piecePosition;
  }

  /// Atualiza o feedback visual e remove peças suficientemente abaixo da torre.
  /// Retorna `true` quando o conjunto de peças ativas mudou.
  bool update(double deltaSeconds, {required double towerTopY}) {
    _updateVisuals(deltaSeconds);
    return _removeFallenPieces(towerTopY);
  }

  void clear() {
    for (final piece in _pieces) {
      _scene.remove(piece.node);
      _blockFactory.forget(piece.node);
    }
    _pieces.clear();
  }

  void _updateVisuals(double deltaSeconds) {
    if (_fallingVisual.wobbleAmplitude == 0.0) return;

    for (final piece in _pieces) {
      piece.elapsedSeconds += deltaSeconds;
      final wobble = math.sin(
        piece.elapsedSeconds * _fallingVisual.wobbleFrequency,
      );
      piece.node.scale = vm.Vector3(
        1.0 + _fallingVisual.wobbleAmplitude * wobble,
        1.0 - _fallingVisual.wobbleAmplitude * 1.4 * wobble,
        1.0 + _fallingVisual.wobbleAmplitude * wobble,
      );
    }
  }

  bool _removeFallenPieces(double towerTopY) {
    final removalY = towerTopY - GameConfig.fallingPieceCleanupDistance;
    var removedPiece = false;
    _pieces.removeWhere((piece) {
      if (piece.node.position.y > removalY) return false;

      _scene.remove(piece.node);
      _blockFactory.forget(piece.node);
      removedPiece = true;
      return true;
    });
    return removedPiece;
  }
}
