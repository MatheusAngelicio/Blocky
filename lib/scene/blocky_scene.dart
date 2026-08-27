import 'package:flutter/widgets.dart';
import 'package:flutter_scene/scene.dart';
import 'package:vector_math/vector_math.dart' as vm;

class BlockyScene extends StatefulWidget {
  const BlockyScene({super.key});

  @override
  State<BlockyScene> createState() => _BlockySceneState();
}

class _BlockySceneState extends State<BlockyScene> {
  final Scene _scene = Scene();
  final PerspectiveCamera _camera = PerspectiveCamera(
    position: vm.Vector3(4.5, 3.2, -5.5),
    target: vm.Vector3.zero(),
  );

  bool _isReady = false;

  @override
  void initState() {
    super.initState();
    _initializeScene();
  }

  Future<void> _initializeScene() async {
    await Scene.initializeStaticResources();

    final material = PhysicallyBasedMaterial()
      ..baseColorFactor = vm.Vector4(0.08, 0.5, 0.95, 1.0)
      ..metallicFactor = 0.05
      ..roughnessFactor = 0.65;

    _scene.directionalLight = DirectionalLight(
      direction: vm.Vector3(-0.5, -1.0, -0.35),
      intensity: 1.6,
    );
    _scene.add(
      Node(mesh: Mesh(CuboidGeometry(vm.Vector3(3.6, 0.6, 3.6)), material)),
    );

    if (mounted) {
      setState(() => _isReady = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isReady) {
      return const SizedBox.expand();
    }

    return SceneView(_scene, camera: _camera, autoTick: false);
  }
}
