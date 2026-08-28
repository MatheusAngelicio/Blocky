enum GameSound { placement, cut, perfect, perfectRecovery, gameOver }

/// Contrato de áudio usado pelos eventos de jogo, sem depender de uma biblioteca.
abstract interface class GameSoundPlayer {
  void play(GameSound sound);

  void dispose();
}
