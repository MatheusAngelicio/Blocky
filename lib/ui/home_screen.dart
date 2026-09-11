import 'dart:math' as math;
import 'package:blocky/design_system/arcade_colors.dart';
import 'package:blocky/design_system/design_system.dart';
import 'package:blocky/app/blocky_colors.dart';
import 'package:blocky/app/blocky_localizations.dart';
import 'package:blocky/game/best_score_storage.dart';
import 'package:blocky/game/blocky_coin_storage.dart';
import 'package:blocky/game/block_theme.dart';
import 'package:blocky/game/block_theme_storage.dart';
import 'package:blocky/game/block_theme_unlock_storage.dart';
import 'package:blocky/game/game_settings.dart';
import 'package:blocky/game/game_settings_storage.dart';
import 'package:blocky/ui/game_screen.dart';
import 'package:blocky/ui/settings_screen.dart';
import 'package:blocky/ui/theme_selection_screen.dart';
import 'package:flutter/material.dart';

/// Tela inicial da partida e seleção visual do tema de bloco.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.onSettingsChanged});

  final ValueChanged<GameSettings>? onSettingsChanged;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final BestScoreStorage _bestScoreStorage = BestScoreStorage();
  final BlockyCoinStorage _blockyCoinStorage = BlockyCoinStorage();
  final BlockThemeStorage _blockThemeStorage = BlockThemeStorage();
  final BlockThemeUnlockStorage _blockThemeUnlockStorage =
      BlockThemeUnlockStorage();
  final GameSettingsStorage _gameSettingsStorage = GameSettingsStorage();
  BlockTheme _selectedTheme = BlockTheme.classic;
  Set<BlockTheme> _unlockedThemes = {BlockTheme.classic};
  GameSettings _gameSettings = const GameSettings();
  int _bestScore = 0;
  int _blockyCoins = 0;

  @override
  void initState() {
    super.initState();
    _loadInitialState();
  }

  Future<void> _loadInitialState() async {
    final results = await Future.wait<Object>([
      _bestScoreStorage.load(),
      _blockyCoinStorage.load(),
      _blockThemeStorage.load(),
      _blockThemeUnlockStorage.load(),
      _gameSettingsStorage.load(),
    ]);
    final savedTheme = results[2] as BlockTheme;
    final unlockedThemes = results[3] as Set<BlockTheme>;
    final selectedTheme = unlockedThemes.contains(savedTheme)
        ? savedTheme
        : BlockTheme.classic;
    if (selectedTheme != savedTheme) {
      await _blockThemeStorage.save(selectedTheme);
    }
    if (!mounted) return;

    setState(() {
      _bestScore = results[0] as int;
      _blockyCoins = results[1] as int;
      _selectedTheme = selectedTheme;
      _unlockedThemes = unlockedThemes;
      _gameSettings = results[4] as GameSettings;
    });
    widget.onSettingsChanged?.call(_gameSettings);
  }

  Future<void> _refreshGameStats() async {
    final results = await Future.wait<int>([
      _bestScoreStorage.load(),
      _blockyCoinStorage.load(),
    ]);
    if (!mounted) return;

    setState(() {
      _bestScore = results[0];
      _blockyCoins = results[1];
    });
  }

  Future<void> _startGame() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            GameScreen(blockTheme: _selectedTheme, settings: _gameSettings),
      ),
    );
    if (mounted) _refreshGameStats();
  }

  Future<void> _showThemeSelector() async {
    final selectedTheme = await Navigator.of(context).push<BlockTheme>(
      MaterialPageRoute<BlockTheme>(
        builder: (_) => ThemeSelectionScreen(
          selectedTheme: _selectedTheme,
          unlockedThemes: _unlockedThemes,
          blockyCoins: _blockyCoins,
          blockyCoinStorage: _blockyCoinStorage,
          unlockStorage: _blockThemeUnlockStorage,
        ),
      ),
    );
    await _refreshThemeCollection();
    if (selectedTheme == null || !mounted) return;

    setState(() => _selectedTheme = selectedTheme);
    await _blockThemeStorage.save(selectedTheme);
  }

  Future<void> _refreshThemeCollection() async {
    final results = await Future.wait<Object>([
      _blockyCoinStorage.load(),
      _blockThemeUnlockStorage.load(),
    ]);
    if (!mounted) return;

    setState(() {
      _blockyCoins = results[0] as int;
      _unlockedThemes = results[1] as Set<BlockTheme>;
    });
  }

  Future<void> _showSettings() async {
    final settings = await Navigator.of(context).push<GameSettings>(
      MaterialPageRoute<GameSettings>(
        builder: (_) => SettingsScreen(
          initialSettings: _gameSettings,
          settingsStorage: _gameSettingsStorage,
          onSettingsChanged: widget.onSettingsChanged,
          previewTheme: _selectedTheme,
        ),
      ),
    );
    if (settings == null || !mounted) return;

    setState(() => _gameSettings = settings);
    widget.onSettingsChanged?.call(settings);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ArcadeColors.canvas,
      body: ArcadeBackdrop(
        child: SafeArea(
          child: _HomeContent(
            selectedTheme: _selectedTheme,
            bestScore: _bestScore,
            blockyCoins: _blockyCoins,
            onPlay: _startGame,
            onChooseTheme: _showThemeSelector,
            onOpenSettings: _showSettings,
          ),
        ),
      ),
    );
  }
}

/// Conteúdo puro da Home, separado do carregamento e navegação da tela.
class _HomeContent extends StatelessWidget {
  const _HomeContent({
    required this.selectedTheme,
    required this.bestScore,
    required this.blockyCoins,
    required this.onPlay,
    required this.onChooseTheme,
    required this.onOpenSettings,
  });

  final BlockTheme selectedTheme;
  final int bestScore;
  final int blockyCoins;
  final VoidCallback onPlay;
  final VoidCallback onChooseTheme;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final themeColor = BlockyColors.themeAccent(selectedTheme);
    final l10n = context.l10n;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: Column(
            children: [
              const Text('BLOCKY', style: ArcadeTypography.logo),
              const SizedBox(height: 8),
              Text(l10n.tagline, style: ArcadeTypography.tagline),
              const SizedBox(height: 26),
              _HomeStats(blockyCoins: blockyCoins, bestScore: bestScore),
              const SizedBox(height: 24),
              _ThemePreview(theme: selectedTheme, accent: themeColor),
              const SizedBox(height: 28),
              ArcadeButton(
                label: l10n.play,
                color: themeColor,
                onPressed: onPlay,
              ),
              const SizedBox(height: 14),
              ArcadeButton(
                label: l10n.blockTheme,
                color: ArcadeColors.strongOutline,
                onPressed: onChooseTheme,
              ),
              const SizedBox(height: 14),
              ArcadeButton(
                label: l10n.settings,
                color: ArcadeColors.outline,
                onPressed: onOpenSettings,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeStats extends StatelessWidget {
  const _HomeStats({required this.blockyCoins, required this.bestScore});

  final int blockyCoins;
  final int bestScore;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Row(
      children: [
        Expanded(
          child: ArcadeStat(
            label: l10n.blockyCoins,
            value: '$blockyCoins',
            valueWidget: ArcadeCoinAmount(amount: '$blockyCoins'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ArcadeStat(label: l10n.best, value: '$bestScore'),
        ),
      ],
    );
  }
}

class _ThemePreview extends StatelessWidget {
  const _ThemePreview({required this.theme, required this.accent});

  final BlockTheme theme;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SizedBox(
      width: double.infinity,
      child: ArcadePanel(
        accent: accent,
        borderWidth: 3,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        shadowOffset: const Offset(5, 6),
        child: Column(
          children: [
            Text(
              '${l10n.currentSet} · ${l10n.themeName(theme).toUpperCase()}',
              style: ArcadeTypography.label.copyWith(
                color: accent,
                fontSize: 12,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              height: 205,
              child: CustomPaint(
                painter: _ThemeTowerPainter(theme),
                child: const SizedBox.expand(),
              ),
            ),
          ],
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
    if (theme == BlockTheme.lego) {
      _drawLegoThemeTowerPreview(canvas, size);
      return;
    }

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

void _drawLegoThemeTowerPreview(Canvas canvas, Size size) {
  final colors = BlockyColors.legoPreviewTower;
  final panel = RRect.fromRectAndRadius(
    Rect.fromLTWH(7, 7, size.width - 14, size.height - 14),
    const Radius.circular(5),
  );
  canvas.drawRRect(panel, Paint()..color = const Color(0xFF172759));
  canvas.drawRRect(
    panel,
    Paint()
      ..color = const Color(0xFF4A87E8).withValues(alpha: 0.48)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4,
  );
  canvas.drawCircle(
    Offset(size.width * 0.76, size.height * 0.27),
    size.width * 0.16,
    Paint()..color = const Color(0xFF728CE3).withValues(alpha: 0.13),
  );
  canvas.drawOval(
    Rect.fromCenter(
      center: Offset(size.width * 0.52, size.height - 28),
      width: size.width * 0.8,
      height: 18,
    ),
    Paint()..color = const Color(0xFF07122F).withValues(alpha: 0.58),
  );

  final centerX = size.width / 2;
  for (var index = 0; index < 5; index++) {
    final progress = index / 5;
    final width = size.width * (0.77 - progress * 0.22);
    _drawLegoPreviewBlock(
      canvas,
      color: colors[index],
      x: centerX - width / 2 + progress * 7,
      y: size.height - 47 - index * 24,
      width: width,
      depth: width * 0.17,
      height: 19,
    );
  }

  final movingWidth = size.width * 0.48;
  _drawLegoPreviewBlock(
    canvas,
    color: colors.last,
    x: centerX + size.width * 0.015,
    y: size.height - 47 - 5 * 24 - 8,
    width: movingWidth,
    depth: movingWidth * 0.17,
    height: 19,
  );
}

void _drawLegoPreviewBlock(
  Canvas canvas, {
  required Color color,
  required double x,
  required double y,
  required double width,
  required double depth,
  required double height,
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

  canvas.drawPath(
    front.shift(const Offset(0, 2.5)),
    Paint()..color = const Color(0xFF07122F).withValues(alpha: 0.35),
  );
  canvas.drawPath(top, Paint()..color = _lighten(color, 0.2));
  canvas.drawPath(right, Paint()..color = _darken(color, 0.27));
  canvas.drawPath(front, Paint()..color = color);
  canvas.drawPath(
    top,
    Paint()
      ..color = ArcadeColors.white.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0,
  );

  final seamPaint = Paint()
    ..color = _darken(color, 0.45).withValues(alpha: 0.7)
    ..strokeWidth = math.max(0.8, width * 0.012);
  for (final fraction in const [0.34, 0.67]) {
    final topPoint = Offset(
      x + width * fraction * 0.5,
      y + depth * (1 + fraction),
    );
    canvas.drawLine(topPoint, topPoint + Offset(0, height * 0.82), seamPaint);
  }

  final radius = math.max(1.6, math.min(width * 0.045, depth * 0.24));
  final studShadow = Paint()..color = _darken(color, 0.38);
  final stud = Paint()..color = _lighten(color, 0.13);
  final glint = Paint()..color = ArcadeColors.white.withValues(alpha: 0.42);
  for (var row = 0; row < 2; row++) {
    for (var column = 0; column < 4; column++) {
      final u = 0.18 + column * 0.215;
      final v = 0.27 + row * 0.42;
      final center = Offset(x + width * 0.5 * (u + v), y + depth * (1 - u + v));
      canvas.drawOval(
        Rect.fromCenter(
          center: center + Offset(0, radius * 0.45),
          width: radius * 2.1,
          height: radius * 1.25,
        ),
        studShadow,
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: center,
          width: radius * 2.0,
          height: radius * 1.18,
        ),
        stud,
      );
      canvas.drawCircle(
        center - Offset(radius * 0.34, radius * 0.2),
        radius * 0.28,
        glint,
      );
    }
  }
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
    case BlockTheme.lego:
      final studShadow = Paint()..color = _darken(color, 0.34);
      final stud = Paint()..color = _lighten(color, 0.14);
      final glint = Paint()..color = ArcadeColors.white.withValues(alpha: 0.38);
      final radius = math.max(1.5, width * 0.043);
      for (var row = 0; row < 2; row++) {
        for (var column = 0; column < 4; column++) {
          final center = Offset(
            x + width * (0.23 + column * 0.135 + row * 0.11),
            y + depth * (0.72 + column * 0.125 + row * 0.36),
          );
          canvas.drawCircle(
            center + Offset(0, radius * 0.34),
            radius,
            studShadow,
          );
          canvas.drawCircle(center, radius, stud);
          canvas.drawCircle(
            center - Offset(radius * 0.26, radius * 0.26),
            radius * 0.3,
            glint,
          );
        }
      }
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

Color _lighten(Color color, double amount) {
  return Color.lerp(color, ArcadeColors.white, amount)!;
}

Color _darken(Color color, double amount) {
  return Color.lerp(color, ArcadeColors.black, amount)!;
}
