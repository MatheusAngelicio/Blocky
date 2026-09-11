import 'dart:ui';

import 'package:blocky/app/arcade_colors.dart';
import 'package:blocky/app/arcade_design_system.dart';
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
  });

  final BlockTheme selectedTheme;
  final Set<BlockTheme> unlockedThemes;
  final int blockyCoins;
  final BlockyCoinStorage blockyCoinStorage;
  final BlockThemeUnlockStorage unlockStorage;

  @override
  State<ThemeSelectionScreen> createState() => _ThemeSelectionScreenState();
}

class _ThemeSelectionScreenState extends State<ThemeSelectionScreen> {
  late final Set<BlockTheme> _unlockedThemes = {...widget.unlockedThemes};
  late int _blockyCoins = widget.blockyCoins;
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
                    const SizedBox(height: 20),
                    Expanded(
                      child: GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 14,
                              mainAxisSpacing: 14,
                              childAspectRatio: 0.82,
                            ),
                        itemCount: BlockTheme.values.length,
                        itemBuilder: (context, index) {
                          final theme = BlockTheme.values[index];
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
    final paint = Paint()..isAntiAlias = false;
    final background = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(2),
    );
    canvas.drawRRect(background, paint..color = accent.withValues(alpha: 0.12));

    final centerX = size.width / 2;
    for (var index = 0; index < 3; index++) {
      final width = size.width * (0.74 - index * 0.14);
      final height = size.height * 0.18;
      final top = size.height * (0.62 - index * 0.16);
      final rect = Rect.fromLTWH(centerX - width / 2, top, width, height);
      canvas.drawRect(rect, paint..color = colors[index % colors.length]);
      canvas.drawRect(
        Rect.fromLTWH(
          rect.left,
          rect.bottom - height * 0.24,
          rect.width,
          height * 0.24,
        ),
        paint..color = accent.withValues(alpha: 0.28),
      );
    }

    if (theme == BlockTheme.lego) {
      paint.color = ArcadeColors.white.withValues(alpha: 0.45);
      for (
        var x = size.width * 0.28;
        x < size.width * 0.75;
        x += size.width * 0.16
      ) {
        canvas.drawCircle(
          Offset(x, size.height * 0.42),
          size.width * 0.045,
          paint,
        );
      }
    } else if (theme == BlockTheme.cheese) {
      paint.color = ArcadeColors.shadow.withValues(alpha: 0.28);
      canvas.drawCircle(
        Offset(size.width * 0.42, size.height * 0.5),
        size.width * 0.06,
        paint,
      );
      canvas.drawCircle(
        Offset(size.width * 0.62, size.height * 0.66),
        size.width * 0.04,
        paint,
      );
    } else if (theme == BlockTheme.neon) {
      paint
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = BlockyColors.neonAccent;
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset(centerX, size.height * 0.49),
          width: size.width * 0.55,
          height: size.height * 0.25,
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_ThemeCardPreviewPainter oldDelegate) =>
      oldDelegate.theme != theme;
}
