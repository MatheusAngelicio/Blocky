import 'package:blocky/app/arcade_colors.dart';
import 'package:flutter/material.dart';

/// Tipografia pixel da coleção. Os estilos são semânticos para que cada jogo
/// use a mesma linguagem visual sem depender de nomes ou regras do Blocky.
abstract final class ArcadeTypography {
  static const fontFamily = 'ArcadePixel';

  static const logo = TextStyle(
    color: ArcadeColors.primary,
    fontFamily: fontFamily,
    fontSize: 38,
    fontWeight: FontWeight.w900,
    letterSpacing: 3.2,
    height: 1.18,
    shadows: [Shadow(color: ArcadeColors.titleShadow, offset: Offset(3, 4))],
  );

  static const heading = TextStyle(
    color: ArcadeColors.white,
    fontFamily: fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w900,
    letterSpacing: 1.2,
    height: 1.45,
  );

  static const tagline = TextStyle(
    color: ArcadeColors.softText,
    fontFamily: fontFamily,
    fontSize: 10,
    fontWeight: FontWeight.w800,
    letterSpacing: 1.1,
    height: 1.45,
  );

  static const label = TextStyle(
    color: ArcadeColors.muted,
    fontFamily: fontFamily,
    fontSize: 9,
    fontWeight: FontWeight.w800,
    letterSpacing: 0.75,
    height: 1.45,
  );

  static const button = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w900,
    letterSpacing: 0.65,
    height: 1.35,
  );

  static const value = TextStyle(
    color: ArcadeColors.white,
    fontFamily: fontFamily,
    fontSize: 25,
    fontWeight: FontWeight.w900,
    letterSpacing: 0.75,
    height: 1.28,
  );

  static final textTheme = const TextTheme(
    displayLarge: logo,
    headlineMedium: heading,
    bodyMedium: tagline,
    labelLarge: button,
    labelMedium: label,
  );
}

/// Tema Material que fornece uma base consistente para os jogos da coleção.
abstract final class ArcadeTheme {
  static ThemeData dark() {
    const colorScheme = ColorScheme.dark(
      primary: ArcadeColors.primary,
      secondary: ArcadeColors.secondary,
      surface: ArcadeColors.elevatedSurface,
      onPrimary: ArcadeColors.ink,
      onSecondary: ArcadeColors.ink,
      onSurface: ArcadeColors.white,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: ArcadeTypography.fontFamily,
      textTheme: ArcadeTypography.textTheme,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: ArcadeColors.canvas,
      splashColor: ArcadeColors.white.withValues(alpha: 0.08),
      highlightColor: ArcadeColors.transparent,
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: ArcadeColors.elevatedSurface,
        modalBackgroundColor: ArcadeColors.elevatedSurface,
        shape: RoundedRectangleBorder(),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: const RoundedRectangleBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: ArcadeTypography.button,
        ),
      ),
    );
  }
}

/// Fundo de interface compartilhado, com grade sutil de CRT e scanlines.
/// A renderização 3D de cada jogo continua responsável pelo próprio cenário.
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
          colors: [ArcadeColors.canvasTop, ArcadeColors.canvas],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          const IgnorePointer(
            child: RepaintBoundary(
              child: CustomPaint(painter: _ArcadeGridPainter()),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _ArcadeGridPainter extends CustomPainter {
  const _ArcadeGridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = ArcadeColors.white.withValues(alpha: 0.035)
      ..strokeWidth = 1
      ..isAntiAlias = false;
    const gridSize = 26.0;
    for (var x = 0.0; x < size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (var y = 0.0; y < size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final scanlinePaint = Paint()
      ..color = ArcadeColors.shadow.withValues(alpha: 0.10)
      ..strokeWidth = 1
      ..isAntiAlias = false;
    for (var y = 2.0; y < size.height; y += 4) {
      canvas.drawLine(
        Offset.zero.translate(0, y),
        Offset(size.width, y),
        scanlinePaint,
      );
    }
  }

  @override
  bool shouldRepaint(_ArcadeGridPainter oldDelegate) => false;
}

/// Painel de bordas retas e sombra dura, inspirado em gabinetes de arcade.
class ArcadePanel extends StatelessWidget {
  const ArcadePanel({
    super.key,
    required this.child,
    this.accent = ArcadeColors.outline,
    this.padding = const EdgeInsets.all(16),
    this.backgroundColor = ArcadeColors.surface,
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
          BoxShadow(color: ArcadeColors.shadow, offset: shadowOffset),
        ],
      ),
      child: child,
    );
  }
}

/// Botão tátil com aparência de controle físico e feedback de pressão.
class ArcadeButton extends StatefulWidget {
  const ArcadeButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.color = ArcadeColors.primary,
    this.foregroundColor = ArcadeColors.ink,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final Color color;
  final Color foregroundColor;
  final bool expand;

  @override
  State<ArcadeButton> createState() => _ArcadeButtonState();
}

class _ArcadeButtonState extends State<ArcadeButton> {
  var _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final pressed = enabled && _isPressed;
    final button = Semantics(
      button: true,
      enabled: enabled,
      label: widget.label,
      child: Transform.translate(
        offset: pressed ? const Offset(3, 4) : Offset.zero,
        child: Material(
          color: ArcadeColors.transparent,
          child: InkWell(
            onTap: widget.onPressed,
            onHighlightChanged: (isPressed) {
              if (enabled && mounted) setState(() => _isPressed = isPressed);
            },
            child: Ink(
              decoration: BoxDecoration(
                color: enabled ? widget.color : ArcadeColors.disabled,
                border: Border.all(color: ArcadeColors.ink, width: 2),
                boxShadow: pressed
                    ? const []
                    : const [
                        BoxShadow(
                          color: ArcadeColors.shadow,
                          offset: Offset(4, 5),
                        ),
                      ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 16,
                ),
                child: Center(
                  child: Text(
                    widget.label,
                    style: ArcadeTypography.button.copyWith(
                      color: widget.foregroundColor,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    return widget.expand
        ? SizedBox(width: double.infinity, child: button)
        : button;
  }
}

/// Pequeno painel numérico reutilizável em HUDs, Home e resultados.
class ArcadeStat extends StatelessWidget {
  const ArcadeStat({
    super.key,
    required this.label,
    required this.value,
    this.accent = ArcadeColors.outline,
    this.valueStyle = ArcadeTypography.value,
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
            style: ArcadeTypography.label,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(value, style: valueStyle, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
