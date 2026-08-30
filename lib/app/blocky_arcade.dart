import 'package:blocky/app/blocky_colors.dart';
import 'package:flutter/material.dart';

/// Tokens tipográficos e componentes Flutter compartilhados do visual arcade.
///
/// Eles ficam independentes da regra de jogo para poderem ser extraídos para
/// um pacote visual compartilhado futuramente, sem levar o gameplay junto.
abstract final class BlockyTypography {
  static const fontFamily = 'monospace';

  static const logo = TextStyle(
    color: BlockyColors.primary,
    fontFamily: fontFamily,
    fontSize: 44,
    fontWeight: FontWeight.w900,
    letterSpacing: 4.0,
    height: 0.95,
    shadows: [Shadow(color: BlockyColors.titleShadow, offset: Offset(3, 4))],
  );

  static const heading = TextStyle(
    color: BlockyColors.white,
    fontFamily: fontFamily,
    fontSize: 27,
    fontWeight: FontWeight.w900,
    letterSpacing: 2.2,
    height: 1.0,
  );

  static const label = TextStyle(
    color: BlockyColors.muted,
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w800,
    letterSpacing: 1.45,
    height: 1.1,
  );

  static const button = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w900,
    letterSpacing: 1.6,
  );

  static const value = TextStyle(
    color: BlockyColors.white,
    fontFamily: fontFamily,
    fontSize: 30,
    fontWeight: FontWeight.w900,
    letterSpacing: 1.2,
    height: 1.0,
  );
}

/// Fundo exclusivo das telas de interface. A Scene mantém seu próprio céu.
class ArcadeBackdrop extends StatelessWidget {
  const ArcadeBackdrop({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [BlockyColors.homeBackgroundTop, BlockyColors.homeBackground],
        ),
      ),
      child: child,
    );
  }
}

/// Painel de bordas retas e sombra dura, inspirado em gabinetes de arcade.
class ArcadePanel extends StatelessWidget {
  const ArcadePanel({
    super.key,
    required this.child,
    this.accent = BlockyColors.panelBorder,
    this.padding = const EdgeInsets.all(16),
    this.backgroundColor = BlockyColors.panelSurface,
    this.borderWidth = 2,
    this.shadowOffset = const Offset(4, 5),
  });

  final Widget child;
  final Color accent;
  final EdgeInsetsGeometry padding;
  final Color backgroundColor;
  final double borderWidth;
  final Offset shadowOffset;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(color: accent, width: borderWidth),
        boxShadow: [
          BoxShadow(color: BlockyColors.shadow, offset: shadowOffset),
        ],
      ),
      child: child,
    );
  }
}

/// Botão de toque com aparência de botão físico do gabinete.
class ArcadeButton extends StatelessWidget {
  const ArcadeButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.color = BlockyColors.primary,
    this.foregroundColor = BlockyColors.frame,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final Color color;
  final Color foregroundColor;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final button = Material(
      color: BlockyColors.transparent,
      child: InkWell(
        onTap: onPressed,
        child: Ink(
          decoration: BoxDecoration(
            color: onPressed == null ? BlockyColors.disabledButton : color,
            border: Border.all(color: BlockyColors.frame, width: 2),
            boxShadow: const [
              BoxShadow(color: BlockyColors.shadow, offset: Offset(4, 5)),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
            child: Center(
              child: Text(
                label,
                style: BlockyTypography.button.copyWith(color: foregroundColor),
              ),
            ),
          ),
        ),
      ),
    );

    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}

/// Pequeno painel numérico reutilizável em HUDs, Home e resultados.
class ArcadeStat extends StatelessWidget {
  const ArcadeStat({
    super.key,
    required this.label,
    required this.value,
    this.accent = BlockyColors.panelBorder,
    this.valueStyle = BlockyTypography.value,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
  });

  final String label;
  final String value;
  final Color accent;
  final TextStyle valueStyle;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return ArcadePanel(
      accent: accent,
      padding: padding,
      shadowOffset: const Offset(3, 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: BlockyTypography.label,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(value, style: valueStyle, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
