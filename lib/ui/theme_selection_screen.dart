import 'dart:ui';

import 'package:blocky/design_system/arcade_colors.dart';
import 'package:blocky/design_system/design_system.dart';
import 'package:blocky/app/blocky_colors.dart';
import 'package:blocky/app/blocky_localizations.dart';
import 'package:blocky/game/block_theme.dart';
import 'package:blocky/game/block_theme_unlock_storage.dart';
import 'package:blocky/game/blocky_coin_storage.dart';
import 'package:blocky/game/game_config.dart';
import 'package:flutter/material.dart';

/// Catálogo de temas, compras locais e seleção do visual da próxima partida.
class ThemeSelectionScreen extends StatefulWidget {
  const ThemeSelectionScreen({
    super.key,
    required this.selectedTheme,
    required this.unlockedThemes,
    required this.blockyCoins,
    required this.blockyCoinStorage,
    required this.unlockStorage,
    this.unlockAllThemes = false,
  });

  final BlockTheme selectedTheme;
  final Set<BlockTheme> unlockedThemes;
  final int blockyCoins;
  final BlockyCoinStorage blockyCoinStorage;
  final BlockThemeUnlockStorage unlockStorage;
  final bool unlockAllThemes;

  @override
  State<ThemeSelectionScreen> createState() => _ThemeSelectionScreenState();
}

class _ThemeSelectionScreenState extends State<ThemeSelectionScreen> {
  late final Set<BlockTheme> _unlockedThemes = widget.unlockAllThemes
      ? BlockTheme.values.toSet()
      : {...widget.unlockedThemes};
  late int _blockyCoins = widget.blockyCoins;
  late BlockThemeRarity _selectedRarity = widget.selectedTheme.rarity;
  BlockTheme? _purchasingTheme;

  Future<void> _selectTheme(BlockTheme theme) async {
    if (!_unlockedThemes.contains(theme)) return;
    Navigator.of(context).pop(theme);
  }

  Future<void> _unlockTheme(BlockTheme theme) async {
    if (_unlockedThemes.contains(theme) || _purchasingTheme != null) return;

    final price = GameConfig.blockThemePrice(theme);
    if (_blockyCoins < price) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.notEnoughCoins)));
      return;
    }

    setState(() => _purchasingTheme = theme);
    final unlockedThemes = {..._unlockedThemes, theme};
    final remainingCoins = _blockyCoins - price;
    await Future.wait([
      widget.blockyCoinStorage.save(remainingCoins),
      widget.unlockStorage.save(unlockedThemes),
    ]);
    if (!mounted) return;

    setState(() {
      _unlockedThemes
        ..clear()
        ..addAll(unlockedThemes);
      _blockyCoins = remainingCoins;
      _purchasingTheme = null;
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.l10n.themeUnlocked)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final themes = BlockTheme.values
        .where((theme) => theme.rarity == _selectedRarity)
        .toList(growable: false);

    return Scaffold(
      backgroundColor: ArcadeColors.canvas,
      body: ArcadeBackdrop(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        color: ArcadeColors.white,
                        icon: const Icon(Icons.arrow_back),
                        tooltip: l10n.back,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l10n.chooseBlockTheme,
                      textAlign: TextAlign.center,
                      style: ArcadeTypography.heading,
                    ),
                    const SizedBox(height: 18),
                    ArcadePanel(
                      accent: ArcadeColors.primary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(l10n.blockyCoins, style: ArcadeTypography.label),
                          ArcadeCoinAmount(amount: '$_blockyCoins'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 42,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: BlockThemeRarity.values.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 10),
                        itemBuilder: (context, index) {
                          final rarity = BlockThemeRarity.values[index];
                          return _ThemeRarityTab(
                            label: l10n.rarityName(rarity),
                            rarity: rarity,
                            selected: rarity == _selectedRarity,
                            onTap: () {
                              setState(() {
                                _selectedRarity = rarity;
                              });
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 14,
                              mainAxisSpacing: 14,
                              childAspectRatio: 0.82,
                            ),
                        itemCount: themes.length,
                        itemBuilder: (context, index) {
                          final theme = themes[index];
                          final unlocked = _unlockedThemes.contains(theme);
                          return _ThemeShopCard(
                            theme: theme,
                            selected: theme == widget.selectedTheme,
                            unlocked: unlocked,
                            purchasing: _purchasingTheme == theme,
                            onTap: unlocked
                                ? () => _selectTheme(theme)
                                : () => _unlockTheme(theme),
                          );
                        },
                      ),
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

class _ThemeRarityTab extends StatelessWidget {
  const _ThemeRarityTab({
    required this.label,
    required this.rarity,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final BlockThemeRarity rarity;
  final bool selected;
  final VoidCallback onTap;

  Color get _color => switch (rarity) {
    BlockThemeRarity.common => ArcadeColors.primary,
    BlockThemeRarity.rare => ArcadeColors.secondary,
    BlockThemeRarity.epic => ArcadeColors.strongOutline,
    BlockThemeRarity.legendary => const Color(0xFFFF9D3F),
  };

  @override
  Widget build(BuildContext context) {
    final color = _color;
    return Material(
      color: ArcadeColors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: selected
                ? color.withValues(alpha: 0.2)
                : ArcadeColors.surface,
            border: Border.all(
              color: selected ? color : ArcadeColors.outline,
              width: selected ? 2 : 1,
            ),
          ),
          child: Text(
            label.toUpperCase(),
            style: ArcadeTypography.label.copyWith(
              color: selected ? color : ArcadeColors.muted,
            ),
          ),
        ),
      ),
    );
  }
}

class _ThemeShopCard extends StatelessWidget {
  const _ThemeShopCard({
    required this.theme,
    required this.selected,
    required this.unlocked,
    required this.purchasing,
    required this.onTap,
  });

  final BlockTheme theme;
  final bool selected;
  final bool unlocked;
  final bool purchasing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = BlockyColors.themeAccent(theme);
    final l10n = context.l10n;
    final price = GameConfig.blockThemePrice(theme);
    final preview = _ThemeCardPreview(theme: theme);
    return Semantics(
      button: true,
      label: unlocked ? l10n.themeName(theme) : l10n.unlockThemeForCoins(price),
      child: Material(
        color: ArcadeColors.transparent,
        child: InkWell(
          onTap: purchasing ? null : onTap,
          child: ArcadePanel(
            accent: selected && unlocked ? color : ArcadeColors.outline,
            borderWidth: selected && unlocked ? 3 : 2,
            padding: const EdgeInsets.all(12),
            shadowOffset: const Offset(3, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      unlocked
                          ? preview
                          : Stack(
                              fit: StackFit.expand,
                              children: [
                                ImageFiltered(
                                  imageFilter: ImageFilter.blur(
                                    sigmaX: 4,
                                    sigmaY: 4,
                                  ),
                                  child: preview,
                                ),
                                Center(
                                  child: Icon(
                                    Icons.lock,
                                    color: color,
                                    size: 36,
                                    shadows: const [
                                      Shadow(
                                        color: ArcadeColors.shadow,
                                        offset: Offset(2, 3),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: ArcadeColors.hudSurface,
                            border: Border.all(color: color),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 3,
                            ),
                            child: ArcadeCoinAmount(
                              amount: '$price',
                              color: color,
                              iconSize: 13,
                              gap: 3,
                              textStyle: ArcadeTypography.label.copyWith(
                                fontSize: 8,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  l10n.themeName(theme).toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: ArcadeTypography.button.copyWith(
                    color: ArcadeColors.white,
                    fontSize: 9,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  purchasing
                      ? '...'
                      : unlocked
                      ? selected
                            ? l10n.selected
                            : l10n.available
                      : l10n.unlockTheme,
                  textAlign: TextAlign.center,
                  style: ArcadeTypography.label.copyWith(
                    color: selected && unlocked ? color : ArcadeColors.softText,
                    fontSize: 7,
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

class _ThemeCardPreview extends StatelessWidget {
  const _ThemeCardPreview({required this.theme});

  final BlockTheme theme;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _ThemeCardPreviewPainter(theme),
      child: const SizedBox.expand(),
    );
  }
}

class _ThemeCardPreviewPainter extends CustomPainter {
  const _ThemeCardPreviewPainter(this.theme);

  final BlockTheme theme;

  @override
  void paint(Canvas canvas, Size size) {
    final accent = BlockyColors.themeAccent(theme);
    final colors = BlockyColors.themePreviewTower(theme);
    final background = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(2),
    );
    canvas.drawRRect(
      background,
      Paint()
        ..color = accent.withValues(alpha: 0.12)
        ..isAntiAlias = false,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.52, size.height * 0.86),
        width: size.width * 0.78,
        height: size.height * 0.13,
      ),
      Paint()
        ..color = ArcadeColors.shadow.withValues(alpha: 0.42)
        ..isAntiAlias = false,
    );
    final centerX = size.width / 2;
    final foundationWidth = size.width * 0.82;
    _drawBlock(
      canvas,
      color: _darken(colors.first, 0.14),
      x: centerX - foundationWidth / 2,
      y: size.height * 0.72,
      width: foundationWidth,
      depth: foundationWidth * 0.075,
      height: size.height * 0.08,
      details: false,
    );

    for (var index = 0; index < 3; index++) {
      final progress = index / 3;
      final blockWidth = size.width * (0.72 - progress * 0.14);
      _drawBlock(
        canvas,
        color: colors[index],
        x: centerX - blockWidth / 2 + progress * size.width * 0.035,
        y: size.height * (0.58 - index * 0.16),
        width: blockWidth,
        depth: blockWidth * 0.085,
        height: size.height * 0.105,
      );
    }
    final movingWidth = size.width * 0.46;
    final movingColor = theme == BlockTheme.lego ? colors[4] : colors.last;
    _drawBlock(
      canvas,
      color: movingColor,
      x: centerX + size.width * 0.015,
      y: size.height * 0.08,
      width: movingWidth,
      depth: movingWidth * 0.085,
      height: size.height * 0.105,
    );
  }

  void _drawBlock(
    Canvas canvas, {
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
    final side = Path()
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
      front.shift(Offset(0, height * 0.15)),
      Paint()
        ..color = ArcadeColors.shadow.withValues(alpha: 0.24)
        ..isAntiAlias = false,
    );
    canvas.drawPath(top, Paint()..color = _lighten(color, 0.2));
    canvas.drawPath(side, Paint()..color = _darken(color, 0.25));
    canvas.drawPath(front, Paint()..color = color);
    if (!details) return;

    switch (theme) {
      case BlockTheme.classic:
        canvas.drawPath(
          Path()
            ..moveTo(x + width * 0.12, y + depth * 1.1)
            ..lineTo(x + width * 0.45, y + depth * 0.44)
            ..lineTo(x + width * 0.56, y + depth * 0.54)
            ..lineTo(x + width * 0.23, y + depth * 1.2)
            ..close(),
          Paint()..color = ArcadeColors.white.withValues(alpha: 0.16),
        );
      case BlockTheme.jelly:
        canvas.drawLine(
          Offset(x + width * 0.12, y + depth + height * 0.28),
          Offset(x + width * 0.47, y + depth * 1.7 + height * 0.28),
          Paint()
            ..color = ArcadeColors.white.withValues(alpha: 0.26)
            ..strokeWidth = 1.2,
        );
      case BlockTheme.chocolate:
        final groove = Paint()
          ..color = _darken(color, 0.48).withValues(alpha: 0.76)
          ..strokeWidth = 1.1;
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
            width * 0.04,
            hole,
          );
        }
        canvas.drawCircle(
          Offset(x + width * 0.22, y + depth + height * 0.45),
          width * 0.028,
          hole,
        );
      case BlockTheme.neon:
        final pink = const Color(0xFFFF38B7);
        final cyan = const Color(0xFF22E6F5);
        _drawNeonLine(
          canvas,
          [
            Offset(x, y + depth),
            Offset(x + width * 0.5, y),
            Offset(x + width, y + depth),
            Offset(x + width * 0.5, y + depth * 2),
            Offset(x, y + depth),
          ],
          pink,
          1.1,
        );
        _drawNeonLine(
          canvas,
          [
            Offset(x + width * 0.08, y + depth + height * 0.76),
            Offset(x + width * 0.45, y + depth * 1.7 + height * 0.76),
          ],
          cyan,
          1.0,
        );
      case BlockTheme.lego:
        final seam = Paint()
          ..color = _darken(color, 0.45).withValues(alpha: 0.7)
          ..strokeWidth = 0.9;
        for (final fraction in const [0.34, 0.67]) {
          final point = Offset(
            x + width * fraction * 0.5,
            y + depth * (1 + fraction),
          );
          canvas.drawLine(point, point + Offset(0, height * 0.76), seam);
        }
        final radius = width * 0.032;
        final studShadow = Paint()..color = _darken(color, 0.36);
        final stud = Paint()..color = _lighten(color, 0.14);
        final glint = Paint()
          ..color = ArcadeColors.white.withValues(alpha: 0.42);
        canvas.save();
        canvas.clipPath(top);
        for (var row = 0; row < 2; row++) {
          for (var column = 0; column < 4; column++) {
            final u = 0.18 + column * 0.215;
            final v = 0.27 + row * 0.42;
            final center = Offset(
              x + width * 0.5 * (u + v),
              y + depth * (1 - u + v),
            );
            canvas.drawOval(
              Rect.fromCenter(
                center: center + Offset(0, radius * 0.42),
                width: radius * 2.1,
                height: radius * 1.22,
              ),
              studShadow,
            );
            canvas.drawOval(
              Rect.fromCenter(
                center: center,
                width: radius * 2.0,
                height: radius * 1.16,
              ),
              stud,
            );
            canvas.drawCircle(
              center - Offset(radius * 0.32, radius * 0.18),
              radius * 0.26,
              glint,
            );
          }
        }
        canvas.restore();
    }
  }

  void _drawNeonLine(
    Canvas canvas,
    List<Offset> points,
    Color color,
    double strokeWidth,
  ) {
    final path = Path()..addPolygon(points, false);
    canvas.drawPath(
      path,
      Paint()
        ..color = color.withValues(alpha: 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth * 2.6
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, strokeWidth * 1.5),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );
  }

  Color _lighten(Color color, double amount) =>
      Color.lerp(color, ArcadeColors.white, amount)!;

  Color _darken(Color color, double amount) =>
      Color.lerp(color, ArcadeColors.black, amount)!;

  @override
  bool shouldRepaint(_ThemeCardPreviewPainter oldDelegate) =>
      oldDelegate.theme != theme;
}
