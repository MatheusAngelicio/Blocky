import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:blocky/game/game_sound.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Caminhos dos efeitos sonoros incluídos no bundle do aplicativo.
abstract final class GameSoundAssets {
  static const _paths = <GameSound, String>{
    GameSound.placement: 'audio/block_placed.wav',
    GameSound.cut: 'audio/block_cut.wav',
    GameSound.perfect: 'audio/perfect.wav',
    GameSound.perfectRecovery: 'audio/perfect_recovery.wav',
    GameSound.gameOver: 'audio/game_over.wav',
  };

  static String pathFor(GameSound sound) => _paths[sound]!;
}

/// Reproduz os sons do jogo quando os assets estiverem disponíveis.
///
/// Enquanto um asset ainda não existir, o som correspondente é ignorado sem
/// interromper a partida e não volta a ser procurado nesta execução.
class AssetGameSoundPlayer implements GameSoundPlayer {
  final Map<GameSound, AudioPlayer> _players = {
    for (final sound in GameSound.values) sound: AudioPlayer(),
  };
  final Set<GameSound> _availableSounds = {};
  final Set<GameSound> _unavailableSounds = {};
  bool _isDisposed = false;

  @override
  void play(GameSound sound) {
    if (_isDisposed || _unavailableSounds.contains(sound)) return;

    unawaited(_play(sound));
  }

  Future<void> _play(GameSound sound) async {
    if (!_availableSounds.contains(sound)) {
      final assetPath = GameSoundAssets.pathFor(sound);
      try {
        await rootBundle.load('assets/$assetPath');
        _availableSounds.add(sound);
      } on FlutterError {
        _unavailableSounds.add(sound);
        return;
      }
    }

    try {
      await _players[sound]!.play(AssetSource(GameSoundAssets.pathFor(sound)));
    } on AudioPlayerException {
      // A ausência ou falha de um efeito não deve interromper a partida.
    }
  }

  @override
  void dispose() {
    if (_isDisposed) return;

    _isDisposed = true;
    for (final player in _players.values) {
      unawaited(player.dispose());
    }
  }
}
