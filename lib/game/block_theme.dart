/// Identifica o estilo visual aplicado aos blocos durante uma partida.
enum BlockTheme { classic, jelly, chocolate, cheese, neon, lego }

/// Agrupa os temas exibidos no catálogo por raridade.
enum BlockThemeRarity { common, rare, epic, legendary }

extension BlockThemeRarityX on BlockTheme {
  BlockThemeRarity get rarity => switch (this) {
    BlockTheme.classic => BlockThemeRarity.common,
    BlockTheme.jelly => BlockThemeRarity.common,
    BlockTheme.chocolate => BlockThemeRarity.common,
    BlockTheme.cheese => BlockThemeRarity.rare,
    BlockTheme.neon => BlockThemeRarity.epic,
    BlockTheme.lego => BlockThemeRarity.legendary,
  };
}
