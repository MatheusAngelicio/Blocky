import 'package:blocky/app/blocky_colors.dart';
import 'package:blocky/game/best_score_storage.dart';
import 'package:blocky/game/blocky_coin_storage.dart';
import 'package:blocky/game/block_theme.dart';
import 'package:blocky/game/block_theme_storage.dart';
import 'package:blocky/scene/sky_progression.dart';
import 'package:blocky/ui/game_screen.dart';
import 'package:flutter/material.dart';

/// Tela inicial da partida e seleção visual do tema de bloco.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final BestScoreStorage _bestScoreStorage = BestScoreStorage();
  final BlockyCoinStorage _blockyCoinStorage = BlockyCoinStorage();
  final BlockThemeStorage _blockThemeStorage = BlockThemeStorage();
  BlockTheme _selectedTheme = BlockTheme.jelly;
  int _bestScore = 0;
  int _blockyCoins = 0;

  @override
  void initState() {
    super.initState();
    _loadBestScore();
    _loadBlockyCoins();
    _loadSelectedTheme();
  }

  Future<void> _loadBestScore() async {
    final bestScore = await _bestScoreStorage.load();
    if (!mounted) return;

    setState(() => _bestScore = bestScore);
  }

  Future<void> _loadBlockyCoins() async {
    final blockyCoins = await _blockyCoinStorage.load();
    if (!mounted) return;

    setState(() => _blockyCoins = blockyCoins);
  }

  Future<void> _loadSelectedTheme() async {
    final selectedTheme = await _blockThemeStorage.load();
    if (!mounted) return;

    setState(() => _selectedTheme = selectedTheme);
  }

  Future<void> _startGame() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => GameScreen(blockTheme: _selectedTheme),
      ),
    );
    if (mounted) {
      _loadBestScore();
      _loadBlockyCoins();
    }
  }

  Future<void> _showThemeSelector() async {
    final selectedTheme = await showModalBottomSheet<BlockTheme>(
      context: context,
      backgroundColor: BlockyColors.modalSurface,
      shape: const RoundedRectangleBorder(),
      builder: (context) => _ThemeSelector(selectedTheme: _selectedTheme),
    );
    if (selectedTheme == null || !mounted) return;

    setState(() => _selectedTheme = selectedTheme);
    await _blockThemeStorage.save(selectedTheme);
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = BlockyColors.themeAccent(_selectedTheme);

    return Scaffold(
      backgroundColor: SkyProgression.homeBackgroundColor,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
              child: Column(
                children: [
                  const Text(
                    'BLOCKY',
                    style: TextStyle(
                      color: BlockyColors.primary,
                      fontSize: 44,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 4,
                      shadows: [
                        Shadow(
                          color: BlockyColors.titleShadow,
                          offset: Offset(3, 4),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'STACK IT UP',
                    style: TextStyle(
                      color: BlockyColors.frame,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 26),
                  Row(
                    children: [
                      Expanded(
                        child: _ArcadeStat(
                          label: 'BLOCKY COINS',
                          value: '$_blockyCoins',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ArcadeStat(label: 'BEST', value: '$_bestScore'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                    decoration: BoxDecoration(
                      color: BlockyColors.panelSurface,
                      border: Border.all(color: themeColor, width: 3),
                      boxShadow: const [
                        BoxShadow(
                          color: BlockyColors.shadow,
                          offset: Offset(5, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          '${_themeName(_selectedTheme).toUpperCase()} BLOCKS',
                          style: TextStyle(
                            color: themeColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        SizedBox(
                          height: 190,
                          child: CustomPaint(
                            painter: _ThemeTowerPainter(_selectedTheme),
                            child: const SizedBox.expand(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  _ArcadeButton(
                    label: 'PLAY',
                    color: themeColor,
                    onPressed: _startGame,
                  ),
                  const SizedBox(height: 14),
                  _ArcadeButton(
                    label: 'BLOCK THEME',
                    color: BlockyColors.secondaryBorder,
                    onPressed: _showThemeSelector,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ArcadeStat extends StatelessWidget {
  const _ArcadeStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: BlockyColors.panelSurface,
        border: Border.all(color: BlockyColors.panelBorder, width: 2),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: BlockyColors.muted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: const TextStyle(
              color: BlockyColors.white,
              fontSize: 25,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _ArcadeButton extends StatelessWidget {
  const _ArcadeButton({
    required this.label,
    required this.color,
    required this.onPressed,
  });

  final String label;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: color,
          foregroundColor: BlockyColors.frame,
          side: const BorderSide(color: BlockyColors.frame, width: 2),
        ),
        onPressed: onPressed,
        child: Text(label),
      ),
    );
  }
}

class _ThemeSelector extends StatelessWidget {
  const _ThemeSelector({required this.selectedTheme});

  final BlockTheme selectedTheme;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'CHOOSE BLOCK THEME',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: BlockyColors.white,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.3,
              ),
            ),
            const SizedBox(height: 20),
            for (final theme in BlockTheme.values) ...[
              _ThemeOption(
                theme: theme,
                selected: theme == selectedTheme,
                onTap: () => Navigator.of(context).pop(theme),
              ),
              const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.theme,
    required this.selected,
    required this.onTap,
  });

  final BlockTheme theme;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = BlockyColors.themeAccent(theme);
    return Material(
      color: selected ? color.withValues(alpha: 0.2) : BlockyColors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            border: Border.all(color: color, width: selected ? 3 : 1),
          ),
          child: Row(
            children: [
              Container(width: 18, height: 18, color: color),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  _themeName(theme).toUpperCase(),
                  style: const TextStyle(
                    color: BlockyColors.white,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
              if (selected)
                const Text(
                  'SELECTED',
                  style: TextStyle(
                    color: BlockyColors.muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemeTowerPainter extends CustomPainter {
  const _ThemeTowerPainter(this.theme);

  final BlockTheme theme;

  @override
  void paint(Canvas canvas, Size size) {
    final colors = BlockyColors.themePreviewTower(theme);
    const blockHeight = 25.0;
    final centerX = size.width / 2;

    for (var index = 0; index < colors.length; index++) {
      final progress = index / (colors.length - 1);
      final width = size.width * (0.86 - progress * 0.32);
      final x = centerX - width / 2 + progress * 8;
      final y = size.height - 42 - index * 28;
      final depth = width * 0.16;
      final top = Path()
        ..moveTo(x, y + depth)
        ..lineTo(x + width * 0.5, y)
        ..lineTo(x + width, y + depth)
        ..lineTo(x + width * 0.5, y + depth * 2)
        ..close();
      final right = Path()
        ..moveTo(x + width, y + depth)
        ..lineTo(x + width * 0.5, y + depth * 2)
        ..lineTo(x + width * 0.5, y + depth * 2 + blockHeight)
        ..lineTo(x + width, y + depth + blockHeight)
        ..close();
      final front = Path()
        ..moveTo(x, y + depth)
        ..lineTo(x + width * 0.5, y + depth * 2)
        ..lineTo(x + width * 0.5, y + depth * 2 + blockHeight)
        ..lineTo(x, y + depth + blockHeight)
        ..close();

      canvas.drawPath(top, Paint()..color = _lighten(colors[index], 0.17));
      canvas.drawPath(right, Paint()..color = _darken(colors[index], 0.2));
      canvas.drawPath(front, Paint()..color = colors[index]);
    }
  }

  @override
  bool shouldRepaint(_ThemeTowerPainter oldDelegate) =>
      oldDelegate.theme != theme;
}

String _themeName(BlockTheme theme) => switch (theme) {
  BlockTheme.classic => 'Classic',
  BlockTheme.jelly => 'Jelly',
  BlockTheme.chocolate => 'Chocolate',
};

Color _lighten(Color color, double amount) {
  return Color.lerp(color, BlockyColors.white, amount)!;
}

Color _darken(Color color, double amount) {
  return Color.lerp(color, BlockyColors.black, amount)!;
}
