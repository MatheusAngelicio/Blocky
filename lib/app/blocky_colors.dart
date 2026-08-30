import 'package:blocky/game/block_theme.dart';
import 'package:flutter/material.dart';

/// Paleta compartilhada dos widgets Flutter do Blocky.
abstract final class BlockyColors {
  static const initialSky = Color(0xFF70C88B);
  static const homeBackgroundTop = Color(0xFF3C2A63);
  static const homeBackground = Color(0xFF171323);
  static const primary = Color(0xFFFFD65C);
  static const secondary = Color(0xFF7CE5A2);
  static const panelSurface = Color(0xFF282341);
  static const modalSurface = Color(0xFF211D32);
  static const frame = Color(0xFF171323);
  static const shadow = Color(0xFF080611);
  static const muted = Color(0xFFBDB5D7);
  static const softText = Color(0xFFCEC5E7);
  static const panelBorder = Color(0xFF655B84);
  static const secondaryBorder = Color(0xFF8D82BB);
  static const perfectBorder = Color(0xFF8EE8C5);
  static const perfectText = Color(0xFFB7F7D5);
  static const titleShadow = Color(0xFF6E4A1C);
  static const white = Colors.white;
  static const black = Colors.black;
  static const transparent = Colors.transparent;
  static const scorePanel = Color(0xE8282341);
  static const gameOverOverlay = Color(0xD6151225);
  static const translucentShadow = Color(0x99080611);
  static const disabledButton = Color(0xFF615C72);

  static const classicAccent = Color(0xFFFFD65C);
  static const jellyAccent = Color(0xFF8EE8C5);
  static const chocolateAccent = Color(0xFFC77A3C);
  static const cheeseAccent = Color(0xFFFFD85A);

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

  static Color themeAccent(BlockTheme theme) => switch (theme) {
    BlockTheme.classic => classicAccent,
    BlockTheme.jelly => jellyAccent,
    BlockTheme.chocolate => chocolateAccent,
    BlockTheme.cheese => cheeseAccent,
  };

  static List<Color> themePreviewTower(BlockTheme theme) => switch (theme) {
    BlockTheme.classic => classicPreviewTower,
    BlockTheme.jelly => jellyPreviewTower,
    BlockTheme.chocolate => chocolatePreviewTower,
    BlockTheme.cheese => cheesePreviewTower,
  };
}
