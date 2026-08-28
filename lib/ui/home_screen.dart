import 'package:blocky/game/best_score_storage.dart';
import 'package:blocky/game/block_theme.dart';
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
  BlockTheme _selectedTheme = BlockTheme.jelly;
  int _bestScore = 0;

  @override
  void initState() {
    super.initState();
    _loadBestScore();
  }

  Future<void> _loadBestScore() async {
    final bestScore = await _bestScoreStorage.load();
    if (!mounted) return;

    setState(() => _bestScore = bestScore);
  }

  Future<void> _startGame() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => GameScreen(blockTheme: _selectedTheme),
      ),
    );
    if (mounted) _loadBestScore();
  }

  Future<void> _showThemeSelector() async {
    final selectedTheme = await showModalBottomSheet<BlockTheme>(
      context: context,
      backgroundColor: const Color(0xFF211D32),
      shape: const RoundedRectangleBorder(),
      builder: (context) => _ThemeSelector(selectedTheme: _selectedTheme),
    );
    if (selectedTheme == null || !mounted) return;

    setState(() => _selectedTheme = selectedTheme);
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = _themeAccent(_selectedTheme);

    return Scaffold(
      backgroundColor: const Color(0xFF151225),
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
                      color: Color(0xFFFFD65C),
                      fontSize: 44,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 4,
                      shadows: [
                        Shadow(color: Color(0xFF6E4A1C), offset: Offset(3, 4)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'STACK IT UP',
                    style: TextStyle(
                      color: Color(0xFFBDB5D7),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 26),
                  Row(
                    children: [
                      Expanded(
                        child: _ArcadeStat(label: 'COINS', value: '0'),
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
                      color: const Color(0xFF282341),
                      border: Border.all(color: themeColor, width: 3),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0xFF080611),
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
                    color: const Color(0xFF8D82BB),
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
        color: const Color(0xFF282341),
        border: Border.all(color: const Color(0xFF655B84), width: 2),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFFBDB5D7),
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
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
          foregroundColor: const Color(0xFF171323),
          side: const BorderSide(color: Color(0xFF171323), width: 2),
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
                color: Colors.white,
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
    final color = _themeAccent(theme);
    return Material(
      color: selected ? color.withValues(alpha: 0.2) : Colors.transparent,
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
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
              if (selected)
                const Text(
                  'SELECTED',
                  style: TextStyle(
                    color: Colors.white70,
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
    final colors = _towerColors(theme);
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

Color _themeAccent(BlockTheme theme) => switch (theme) {
  BlockTheme.classic => const Color(0xFFFFD65C),
  BlockTheme.jelly => const Color(0xFF8EE8C5),
  BlockTheme.chocolate => const Color(0xFFC77A3C),
};

List<Color> _towerColors(BlockTheme theme) => switch (theme) {
  BlockTheme.classic => const [
    Color(0xFFE65C75),
    Color(0xFFF28C52),
    Color(0xFFFFC85C),
    Color(0xFFA5D86E),
    Color(0xFF6FCF97),
  ],
  BlockTheme.jelly => const [
    Color(0xFFC59EE8),
    Color(0xFFF0A2C8),
    Color(0xFFFFC59B),
    Color(0xFFE9E58B),
    Color(0xFF9CE5C0),
  ],
  BlockTheme.chocolate => const [
    Color(0xFF4E2116),
    Color(0xFF6C321D),
    Color(0xFF89502D),
    Color(0xFFAD7040),
    Color(0xFFD29A5E),
  ],
};

Color _lighten(Color color, double amount) {
  return Color.lerp(color, Colors.white, amount)!;
}

Color _darken(Color color, double amount) {
  return Color.lerp(color, Colors.black, amount)!;
}
