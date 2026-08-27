import 'package:flutter/foundation.dart';

class BlockyGameController extends ChangeNotifier {
  bool _isMoving = true;

  bool get isMoving => _isMoving;

  void stopMovingBlock() {
    if (!_isMoving) return;

    _isMoving = false;
    notifyListeners();
  }
}
