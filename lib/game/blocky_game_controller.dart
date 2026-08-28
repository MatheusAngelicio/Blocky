import 'dart:async';

import 'package:blocky/game/game_config.dart';
import 'package:flutter/foundation.dart';

enum MovingBlockAxis { x, z }

enum GameStatus { playing, gameOver }

class BlockyGameController extends ChangeNotifier {
  BlockyGameController({
    Duration perfectFeedbackDuration = GameConfig.perfectFeedbackDuration,
  }) : _perfectFeedbackDuration = perfectFeedbackDuration;

  final Duration _perfectFeedbackDuration;
  bool _isMoving = true;
  GameStatus _status = GameStatus.playing;
  MovingBlockAxis _movingAxis = MovingBlockAxis.x;
  int _score = 0;
  int _round = 0;
  int _perfectStreak = 0;
  bool _isShowingPerfect = false;
  String _perfectFeedbackText = 'PERFECT!';
  Timer? _perfectFeedbackTimer;

  bool get isMoving => _isMoving;
  GameStatus get status => _status;
  bool get isGameOver => _status == GameStatus.gameOver;
  MovingBlockAxis get movingAxis => _movingAxis;
  int get score => _score;
  int get round => _round;
  int get perfectStreak => _perfectStreak;
  bool get isShowingPerfect => _isShowingPerfect;
  String get perfectFeedbackText => _perfectFeedbackText;

  void stopMovingBlock() {
    if (isGameOver || !_isMoving) return;

    _isMoving = false;
    notifyListeners();
  }

  bool startNextBlock({bool isPerfect = false}) {
    if (isGameOver) return false;

    _score++;
    if (isPerfect) {
      _perfectStreak++;
      _showPerfectFeedback();
    } else {
      _perfectStreak = 0;
      _clearPerfectFeedback();
    }
    _movingAxis = switch (_movingAxis) {
      MovingBlockAxis.x => MovingBlockAxis.z,
      MovingBlockAxis.z => MovingBlockAxis.x,
    };
    _isMoving = true;
    notifyListeners();
    return true;
  }

  bool consumePerfectRecovery() {
    if (_perfectStreak != GameConfig.perfectStreakForRecovery) return false;

    _perfectStreak = 0;
    _showPerfectRecoveryFeedback();
    notifyListeners();
    return true;
  }

  void endGame() {
    if (isGameOver) return;

    _clearPerfectFeedback();
    _perfectStreak = 0;
    _isMoving = false;
    _status = GameStatus.gameOver;
    notifyListeners();
  }

  void restartGame() {
    _clearPerfectFeedback();
    _score = 0;
    _perfectStreak = 0;
    _movingAxis = MovingBlockAxis.x;
    _status = GameStatus.playing;
    _isMoving = true;
    _round++;
    notifyListeners();
  }

  void _showPerfectFeedback() {
    _perfectFeedbackTimer?.cancel();
    _perfectFeedbackText = _perfectStreak > 1
        ? 'PERFECT! x$_perfectStreak'
        : 'PERFECT!';
    _isShowingPerfect = true;
    _perfectFeedbackTimer = Timer(_perfectFeedbackDuration, () {
      _isShowingPerfect = false;
      _perfectFeedbackTimer = null;
      notifyListeners();
    });
  }

  void _showPerfectRecoveryFeedback() {
    _perfectFeedbackTimer?.cancel();
    _perfectFeedbackText = 'PERFECT RECOVERY!';
    _isShowingPerfect = true;
    _perfectFeedbackTimer = Timer(
      GameConfig.perfectRecoveryFeedbackDuration,
      () {
        _isShowingPerfect = false;
        _perfectFeedbackTimer = null;
        notifyListeners();
      },
    );
  }

  void _clearPerfectFeedback() {
    _perfectFeedbackTimer?.cancel();
    _perfectFeedbackTimer = null;
    _isShowingPerfect = false;
  }

  @override
  void dispose() {
    _clearPerfectFeedback();
    super.dispose();
  }
}
