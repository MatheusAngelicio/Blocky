import 'dart:async';

import 'package:flutter/services.dart';

enum GameHapticEvent { placement, perfect, perfectRecovery, gameOver }

/// Mantém os padrões hápticos do jogo consistentes e independentes da cena.
abstract final class GameHaptics {
  static void trigger(GameHapticEvent event) {
    final feedback = switch (event) {
      GameHapticEvent.placement => HapticFeedback.selectionClick(),
      GameHapticEvent.perfect => HapticFeedback.lightImpact(),
      GameHapticEvent.perfectRecovery => HapticFeedback.mediumImpact(),
      GameHapticEvent.gameOver => HapticFeedback.heavyImpact(),
    };

    // Não bloqueia o ciclo de renderização enquanto o sistema executa o gesto.
    unawaited(feedback);
  }
}
