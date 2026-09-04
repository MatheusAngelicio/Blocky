import 'package:blocky/game/block_theme.dart';
import 'package:flutter/material.dart';

/// Cores que pertencem exclusivamente aos blocos e à apresentação do Blocky.
///
/// Os tokens compartilhados da coleção ficam em [ArcadeColors].
abstract final class BlockyColors {
  static const initialSky = Color(0xFF70C88B);
  static const perfectText = Color(0xFFB7F7D5);

  static const classicAccent = Color(0xFFFFD65C);
  static const jellyAccent = Color(0xFF8EE8C5);
  static const chocolateAccent = Color(0xFFC77A3C);
  static const cheeseAccent = Color(0xFFFFD85A);
  static const neonAccent = Color(0xFF22E6F5);

  static const classicPreviewTower = <Color>[
    Color(0xFFE65C75),
    Color(0xFFF28C52),
    Color(0xFFFFC85C),
    Color(0xFFA5D86E),
    Color(0xFF6FCF97),
  ];
  static const jellyPreviewTower = <Color>[
    Color(0xFFC59EE8),
    Color(0xFFF0A2C8),
    Color(0xFFFFC59B),
    Color(0xFFE9E58B),
    Color(0xFF9CE5C0),
  ];
  static const chocolatePreviewTower = <Color>[
    Color(0xFF4E2116),
    Color(0xFF6C321D),
    Color(0xFF89502D),
    Color(0xFFAD7040),
    Color(0xFFD29A5E),
  ];
  static const cheesePreviewTower = <Color>[
    Color(0xFFE7A832),
    Color(0xFFF3BA38),
    Color(0xFFFFCD4E),
    Color(0xFFFFDA67),
    Color(0xFFFFE481),
  ];
  static const neonPreviewTower = <Color>[
    Color(0xFF15233D),
    Color(0xFF1B2948),
    Color(0xFF26335B),
    Color(0xFF3A2A62),
    Color(0xFF4B1E65),
  ];

  static Color themeAccent(BlockTheme theme) => switch (theme) {
    BlockTheme.classic => classicAccent,
    BlockTheme.jelly => jellyAccent,
    BlockTheme.chocolate => chocolateAccent,
    BlockTheme.cheese => cheeseAccent,
    BlockTheme.neon => neonAccent,
  };

  static List<Color> themePreviewTower(BlockTheme theme) => switch (theme) {
    BlockTheme.classic => classicPreviewTower,
    BlockTheme.jelly => jellyPreviewTower,
    BlockTheme.chocolate => chocolatePreviewTower,
    BlockTheme.cheese => cheesePreviewTower,
    BlockTheme.neon => neonPreviewTower,
  };
}
