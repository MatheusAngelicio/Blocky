import 'dart:math' as math;

import 'package:blocky/app/arcade_colors.dart';
import 'package:blocky/app/arcade_design_system.dart';
import 'package:blocky/app/blocky_colors.dart';
import 'package:blocky/game/best_score_storage.dart';
import 'package:blocky/game/blocky_coin_storage.dart';
import 'package:blocky/game/block_theme.dart';
import 'package:blocky/game/block_theme_storage.dart';
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
      isScrollControlled: true,
      backgroundColor: ArcadeColors.elevatedSurface,
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
      backgroundColor: ArcadeColors.canvas,
      body: ArcadeBackdrop(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                child: Column(
                  children: [
                    const Text('BLOCKY', style: ArcadeTypography.logo),
                    const SizedBox(height: 8),
                    const Text('STACK IT UP', style: ArcadeTypography.tagline),
                    const SizedBox(height: 26),
                    Row(
                      children: [
                        Expanded(
                          child: ArcadeStat(
                            label: 'BLOCKY COINS',
                            value: '$_blockyCoins',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ArcadeStat(
                            label: 'BEST',
                            value: '$_bestScore',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ArcadePanel(
                        accent: themeColor,
                        borderWidth: 3,
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                        shadowOffset: const Offset(5, 6),
                        child: Column(
                          children: [
                            Text(
                              'CURRENT SET · ${_themeName(_selectedTheme).toUpperCase()}',
                              style: ArcadeTypography.label.copyWith(
                                color: themeColor,
                                fontSize: 12,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            SizedBox(
                              height: 205,
                              child: CustomPaint(
                                painter: _ThemeTowerPainter(_selectedTheme),
                                child: const SizedBox.expand(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    ArcadeButton(
                      label: 'PLAY',
                      color: themeColor,
                      onPressed: _startGame,
                    ),
                    const SizedBox(height: 14),
                    ArcadeButton(
                      label: 'BLOCK THEME',
                      color: ArcadeColors.strongOutline,
                      onPressed: _showThemeSelector,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ThemeSelector extends StatelessWidget {
  const _ThemeSelector({required this.selectedTheme});

  final BlockTheme selectedTheme;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SafeArea(
        child: SizedBox(
          height: constraints.maxHeight * 0.78,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'CHOOSE BLOCK THEME',
                  textAlign: TextAlign.center,
                  style: ArcadeTypography.heading,
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: ListView.separated(
                    itemCount: BlockTheme.values.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final theme = BlockTheme.values[index];
                      return _ThemeOption(
                        theme: theme,
                        selected: theme == selectedTheme,
                        onTap: () => Navigator.of(context).pop(theme),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
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
      color: selected ? color.withValues(alpha: 0.2) : ArcadeColors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            border: Border.all(color: color, width: selected ? 3 : 1),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 42,
                height: 34,
                child: CustomPaint(painter: _ThemeSwatchPainter(theme)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _themeName(theme).toUpperCase(),
                  style: ArcadeTypography.button.copyWith(
                    color: ArcadeColors.white,
                  ),
                ),
              ),
              if (selected)
                Text(
                  'SELECTED',
                  style: ArcadeTypography.label.copyWith(fontSize: 8),
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
    final centerX = size.width / 2;
    final accent = BlockyColors.themeAccent(theme);

    final backdrop = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(4),
    );
    canvas.drawRRect(backdrop, Paint()..color = accent.withValues(alpha: 0.08));
    canvas.drawCircle(
      Offset(size.width * 0.78, size.height * 0.22),
      size.width * 0.16,
      Paint()..color = accent.withValues(alpha: 0.09),
    );

    final foundationWidth = size.width * 0.78;
    _drawPreviewBlock(
      canvas,
      theme: theme,
      color: _darken(colors.first, 0.12),
      x: centerX - foundationWidth / 2,
      y: size.height - 34,
      width: foundationWidth,
      depth: foundationWidth * 0.17,
      height: 15,
      details: false,
    );

    for (var index = 0; index < colors.length; index++) {
      final progress = index / (colors.length - 1);
      final width = size.width * (0.7 - progress * 0.26);
      _drawPreviewBlock(
        canvas,
        theme: theme,
        color: colors[index],
        x: centerX - width / 2 + progress * 7,
        y: size.height - 50 - index * 25,
        width: width,
        depth: width * 0.17,
        height: 20,
      );
    }

    // Um bloco deslocado deixa claro, mesmo na Home, que este é o tema usado
    // durante uma partida e não apenas uma paleta de cores.
    final movingWidth = size.width * 0.46;
    _drawPreviewBlock(
      canvas,
      theme: theme,
      color: colors.last,
      x: centerX + size.width * 0.04,
      y: size.height - 50 - colors.length * 25 - 9,
      width: movingWidth,
      depth: movingWidth * 0.17,
      height: 20,
    );
  }

  @override
  bool shouldRepaint(_ThemeTowerPainter oldDelegate) =>
      oldDelegate.theme != theme;
}

class _ThemeSwatchPainter extends CustomPainter {
  const _ThemeSwatchPainter(this.theme);

  final BlockTheme theme;

  @override
  void paint(Canvas canvas, Size size) {
    final color = BlockyColors.themePreviewTower(theme).elementAt(2);
    _drawPreviewBlock(
      canvas,
      theme: theme,
      color: color,
      x: 1,
      y: 4,
      width: size.width - 6,
      depth: 7,
      height: 12,
    );
  }

  @override
  bool shouldRepaint(_ThemeSwatchPainter oldDelegate) =>
      oldDelegate.theme != theme;
}

void _drawPreviewBlock(
  Canvas canvas, {
  required BlockTheme theme,
  required Color color,
  required double x,
  required double y,
  required double width,
  required double depth,
  required double height,
  bool details = true,
}) {
  final top = Path()
    ..moveTo(x, y + depth)
    ..lineTo(x + width * 0.5, y)
    ..lineTo(x + width, y + depth)
    ..lineTo(x + width * 0.5, y + depth * 2)
    ..close();
  final right = Path()
    ..moveTo(x + width, y + depth)
    ..lineTo(x + width * 0.5, y + depth * 2)
    ..lineTo(x + width * 0.5, y + depth * 2 + height)
    ..lineTo(x + width, y + depth + height)
    ..close();
  final front = Path()
    ..moveTo(x, y + depth)
    ..lineTo(x + width * 0.5, y + depth * 2)
    ..lineTo(x + width * 0.5, y + depth * 2 + height)
    ..lineTo(x, y + depth + height)
    ..close();

  canvas.drawPath(top, Paint()..color = _lighten(color, 0.2));
  canvas.drawPath(right, Paint()..color = _darken(color, 0.25));
  canvas.drawPath(front, Paint()..color = color);

  if (!details) return;

  switch (theme) {
    case BlockTheme.classic:
      canvas.drawPath(
        Path()
          ..moveTo(x + width * 0.13, y + depth * 1.08)
          ..lineTo(x + width * 0.48, y + depth * 0.38)
          ..lineTo(x + width * 0.59, y + depth * 0.48)
          ..lineTo(x + width * 0.24, y + depth * 1.18)
          ..close(),
        Paint()..color = ArcadeColors.white.withValues(alpha: 0.13),
      );
    case BlockTheme.jelly:
      canvas.drawLine(
        Offset(x + width * 0.12, y + depth + height * 0.28),
        Offset(x + width * 0.48, y + depth * 1.72 + height * 0.28),
        Paint()
          ..color = ArcadeColors.white.withValues(alpha: 0.23)
          ..strokeWidth = 1.4,
      );
    case BlockTheme.chocolate:
      final groove = Paint()
        ..color = _darken(color, 0.48).withValues(alpha: 0.72)
        ..strokeWidth = math.max(1, width * 0.018);
      for (final fraction in const [0.34, 0.66]) {
        canvas.drawLine(
          Offset(x + width * fraction, y + depth * (1 - fraction)),
          Offset(x + width * fraction, y + depth * (2 - fraction)),
          groove,
        );
      }
      canvas.drawLine(
        Offset(x + width * 0.2, y + depth),
        Offset(x + width * 0.8, y + depth),
        groove,
      );
    case BlockTheme.cheese:
      final hole = Paint()..color = _darken(color, 0.38);
      for (final point in const [Offset(0.37, 0.72), Offset(0.61, 0.91)]) {
        canvas.drawCircle(
          Offset(x + width * point.dx, y + depth * point.dy),
          math.max(1.5, width * 0.04),
          hole,
        );
      }
      canvas.drawCircle(
        Offset(x + width * 0.22, y + depth + height * 0.45),
        math.max(1.2, width * 0.028),
        hole,
      );
    case BlockTheme.neon:
      final pink = const Color(0xFFFF38B7);
      final cyan = const Color(0xFF22E6F5);
      final topEdges = [
        Offset(x, y + depth),
        Offset(x + width * 0.5, y),
        Offset(x + width, y + depth),
        Offset(x + width * 0.5, y + depth * 2),
        Offset(x, y + depth),
      ];
      _drawNeonPreviewLine(canvas, topEdges, pink, width * 0.028);
      _drawNeonPreviewLine(
        canvas,
        [
          Offset(x + width * 0.04, y + depth + height * 0.8),
          Offset(x + width * 0.48, y + depth * 1.75 + height * 0.8),
        ],
        cyan,
        width * 0.024,
      );
      _drawNeonPreviewLine(
        canvas,
        [
          Offset(x + width * 0.13, y + depth + height * 0.42),
          Offset(x + width * 0.29, y + depth * 1.3 + height * 0.42),
          Offset(x + width * 0.43, y + depth * 1.16 + height * 0.42),
        ],
        pink,
        width * 0.016,
      );
  }
}

void _drawNeonPreviewLine(
  Canvas canvas,
  List<Offset> points,
  Color color,
  double strokeWidth,
) {
  final path = Path()..addPolygon(points, false);
  canvas.drawPath(
    path,
    Paint()
      ..color = color.withValues(alpha: 0.48)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth * 2.8
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, strokeWidth * 1.7),
  );
  canvas.drawPath(
    path,
    Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.0, strokeWidth),
  );
}

String _themeName(BlockTheme theme) => switch (theme) {
  BlockTheme.classic => 'Classic',
  BlockTheme.jelly => 'Jelly',
  BlockTheme.chocolate => 'Chocolate',
  BlockTheme.cheese => 'Cheese',
  BlockTheme.neon => 'Neon',
};

Color _lighten(Color color, double amount) {
  return Color.lerp(color, ArcadeColors.white, amount)!;
}

Color _darken(Color color, double amount) {
  return Color.lerp(color, ArcadeColors.black, amount)!;
}
