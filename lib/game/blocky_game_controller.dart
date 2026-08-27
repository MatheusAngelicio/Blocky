import 'package:flutter/foundation.dart';

enum MovingBlockAxis { x, z }

class BlockyGameController extends ChangeNotifier {
  bool _isMoving = true;
  MovingBlockAxis _movingAxis = MovingBlockAxis.x;

  bool get isMoving => _isMoving;
  MovingBlockAxis get movingAxis => _movingAxis;

  void stopMovingBlock() {
    if (!_isMoving) return;

    _isMoving = false;
    notifyListeners();
  }

  void startNextBlock() {
    _movingAxis = switch (_movingAxis) {
      MovingBlockAxis.x => MovingBlockAxis.z,
      MovingBlockAxis.z => MovingBlockAxis.x,
    };
    _isMoving = true;
    notifyListeners();
  }
}
