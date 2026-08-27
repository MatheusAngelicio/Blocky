import 'dart:async';

import 'package:blocky/game/game_config.dart';
import 'package:flutter/foundation.dart';

enum MovingBlockAxis { x, z }

class BlockyGameController extends ChangeNotifier {
  BlockyGameController({
    Duration perfectFeedbackDuration = GameConfig.perfectFeedbackDuration,
  }) : _perfectFeedbackDuration = perfectFeedbackDuration;

  final Duration _perfectFeedbackDuration;
  bool _isMoving = true;
  MovingBlockAxis _movingAxis = MovingBlockAxis.x;
  int _score = 0;
  bool _isShowingPerfect = false;
  Timer? _perfectFeedbackTimer;

  bool get isMoving => _isMoving;
  MovingBlockAxis get movingAxis => _movingAxis;
  int get score => _score;
  bool get isShowingPerfect => _isShowingPerfect;

  void stopMovingBlock() {
    if (!_isMoving) return;

    _isMoving = false;
    notifyListeners();
  }

  void startNextBlock({bool isPerfect = false}) {
    _score++;
    if (isPerfect) {
      _showPerfectFeedback();
    }
    _movingAxis = switch (_movingAxis) {
      MovingBlockAxis.x => MovingBlockAxis.z,
      MovingBlockAxis.z => MovingBlockAxis.x,
    };
    _isMoving = true;
    notifyListeners();
  }

  void _showPerfectFeedback() {
    _perfectFeedbackTimer?.cancel();
    _isShowingPerfect = true;
    _perfectFeedbackTimer = Timer(_perfectFeedbackDuration, () {
      _isShowingPerfect = false;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _perfectFeedbackTimer?.cancel();
    super.dispose();
  }
}
