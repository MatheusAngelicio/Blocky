import 'package:flutter/foundation.dart';

enum MovingBlockAxis { x, z }

class BlockyGameController extends ChangeNotifier {
  bool _isMoving = true;
  MovingBlockAxis _movingAxis = MovingBlockAxis.x;
  int _score = 0;

  bool get isMoving => _isMoving;
  MovingBlockAxis get movingAxis => _movingAxis;
  int get score => _score;

  void stopMovingBlock() {
    if (!_isMoving) return;

    _isMoving = false;
    notifyListeners();
  }

  void startNextBlock() {
    _score++;
    _movingAxis = switch (_movingAxis) {
      MovingBlockAxis.x => MovingBlockAxis.z,
      MovingBlockAxis.z => MovingBlockAxis.x,
    };
    _isMoving = true;
    notifyListeners();
  }
}
