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

    // A chamada nativa não pode atrasar o ciclo de renderização nem falhar a
    // partida em plataformas que não oferecem feedback tátil.
    unawaited(_ignorePlatformFailure(feedback));
  }

  static Future<void> _ignorePlatformFailure(Future<void> feedback) async {
    try {
      await feedback;
    } catch (_) {
      // Haptics é um aprimoramento opcional da experiência.
    }
  }
}
