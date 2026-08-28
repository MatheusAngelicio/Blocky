import 'dart:async';

import 'package:blocky/game/blocky_coin_storage.dart';
import 'package:blocky/game/best_score_storage.dart';
import 'package:blocky/game/game_config.dart';
import 'package:flutter/foundation.dart';

enum MovingBlockAxis { x, z }

enum GameStatus { playing, gameOverPreview, gameOver }

class BlockyGameController extends ChangeNotifier {
  BlockyGameController({
    Duration perfectFeedbackDuration = GameConfig.perfectFeedbackDuration,
    BestScoreStorage? bestScoreStorage,
    BlockyCoinStorage? blockyCoinStorage,
  }) : _perfectFeedbackDuration = perfectFeedbackDuration,
       _bestScoreStorage = bestScoreStorage ?? BestScoreStorage(),
       _blockyCoinStorage = blockyCoinStorage ?? BlockyCoinStorage();

  final Duration _perfectFeedbackDuration;
  final BestScoreStorage _bestScoreStorage;
  final BlockyCoinStorage _blockyCoinStorage;
  bool _isMoving = true;
  GameStatus _status = GameStatus.playing;
  MovingBlockAxis _movingAxis = MovingBlockAxis.x;
  int _score = 0;
  int _bestScore = 0;
  int _blockyCoins = 0;
  int _coinsEarnedThisGame = 0;
  int _pendingCoinCredits = 0;
  bool _hasLoadedBlockyCoins = false;
  Future<void> _coinSaveQueue = Future.value();
  int _round = 0;
  int _perfectStreak = 0;
  bool _isShowingPerfect = false;
  String _perfectFeedbackText = 'PERFECT!';
  Timer? _perfectFeedbackTimer;
  bool _isDisposed = false;

  bool get isMoving => _isMoving;
  GameStatus get status => _status;
  bool get isGameOver => _status == GameStatus.gameOver;
  bool get isShowingGameOverPreview => _status == GameStatus.gameOverPreview;
  MovingBlockAxis get movingAxis => _movingAxis;
  int get score => _score;
  int get bestScore => _bestScore;
  int get blockyCoins => _blockyCoins;
  int get coinsEarnedThisGame => _coinsEarnedThisGame;
  int get round => _round;
  int get perfectStreak => _perfectStreak;
  bool get isPerfectRecoveryReady =>
      _perfectStreak >= GameConfig.perfectStreakForRecovery;
  bool get isShowingPerfect => _isShowingPerfect;
  String get perfectFeedbackText => _perfectFeedbackText;

  Future<void> loadBestScore() async {
    final storedBestScore = await _bestScoreStorage.load();
    if (_isDisposed || storedBestScore <= _bestScore) return;

    _bestScore = storedBestScore;
    notifyListeners();
  }

  Future<void> loadBlockyCoins() async {
    final storedCoins = await _blockyCoinStorage.load();
    if (_isDisposed || _hasLoadedBlockyCoins) return;

    final pendingCoinCredits = _pendingCoinCredits;
    _blockyCoins = storedCoins + pendingCoinCredits;
    _pendingCoinCredits = 0;
    _hasLoadedBlockyCoins = true;
    if (pendingCoinCredits > 0) {
      _scheduleBlockyCoinSave();
    }
    notifyListeners();
  }

  void stopMovingBlock() {
    if (_status != GameStatus.playing || !_isMoving) return;

    _isMoving = false;
    notifyListeners();
  }

  bool startNextBlock({bool isPerfect = false}) {
    if (_status != GameStatus.playing) return false;

    _score++;
    if (_score % GameConfig.blocksPerBlockyCoin == 0) {
      _awardBlockyCoins(1);
    }
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

  void completePerfectRecovery() {
    _awardBlockyCoins(GameConfig.blockyCoinsPerPerfectRecovery);
    _showPerfectRecoveryFeedback();
    notifyListeners();
  }

  void endGame() {
    if (_status != GameStatus.playing) return;

    if (_score > _bestScore) {
      _bestScore = _score;
      unawaited(_persistBestScore(_bestScore));
    }
    _clearPerfectFeedback();
    _perfectStreak = 0;
    _isMoving = false;
    _status = GameStatus.gameOverPreview;
    notifyListeners();
  }

  void completeGameOverPresentation() {
    if (!isShowingGameOverPreview) return;

    _status = GameStatus.gameOver;
    notifyListeners();
  }

  void restartGame() {
    _clearPerfectFeedback();
    _score = 0;
    _coinsEarnedThisGame = 0;
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

  Future<void> _persistBestScore(int score) async {
    final persistedBestScore = await _bestScoreStorage.saveIfHigher(score);
    if (_isDisposed || persistedBestScore <= _bestScore) return;

    _bestScore = persistedBestScore;
    notifyListeners();
  }

  void _awardBlockyCoins(int amount) {
    _blockyCoins += amount;
    _coinsEarnedThisGame += amount;
    if (_hasLoadedBlockyCoins) {
      _scheduleBlockyCoinSave();
    } else {
      _pendingCoinCredits += amount;
    }
  }

  void _scheduleBlockyCoinSave() {
    final coinsToSave = _blockyCoins;
    _coinSaveQueue = _coinSaveQueue.then(
      (_) => _blockyCoinStorage.save(coinsToSave),
    );
  }

  @override
  void dispose() {
    _isDisposed = true;
    _clearPerfectFeedback();
    super.dispose();
  }
}
