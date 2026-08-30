import 'package:flutter_scene/scene.dart';
import 'package:vector_math/vector_math.dart' as vm;

/// Estado mutável mínimo dos efeitos visuais temporários da Scene.
///
/// Mantê-los fora do widget principal torna claro que eles não fazem parte do
/// estado da partida nem das regras de posicionamento.
class SceneTransientParticleEffect {
  SceneTransientParticleEffect(this.node, this.remainingSeconds);

  final Node node;
  double remainingSeconds;
}

class SceneBackgroundStar {
  SceneBackgroundStar({
    required this.node,
    required this.material,
    required this.horizontalOffset,
    required this.verticalOffset,
    required this.depth,
    required this.blinkSpeed,
    required this.blinkPhase,
  });

  final Node node;
  final PhysicallyBasedMaterial material;
  final double horizontalOffset;
  final double verticalOffset;
  final double depth;
  final double blinkSpeed;
  final double blinkPhase;
  double elapsedSeconds = 0.0;
}

class ScenePerfectLightPulse {
  ScenePerfectLightPulse({
    required this.node,
    required this.material,
    required this.color,
  });

  final Node node;
  final PhysicallyBasedMaterial material;
  final vm.Vector4 color;
  double elapsedSeconds = 0.0;
}

class ScenePerfectWobble {
  ScenePerfectWobble({
    required this.node,
    required this.basePosition,
    required this.baseRotation,
  });

  final Node node;
  final vm.Vector3 basePosition;
  final vm.Quaternion baseRotation;
  double elapsedSeconds = 0.0;
}

class SceneFallingPiece {
  SceneFallingPiece(this.node);

  final Node node;
  double elapsedSeconds = 0.0;
}
