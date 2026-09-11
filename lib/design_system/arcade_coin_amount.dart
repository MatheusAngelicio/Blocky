import 'package:blocky/design_system/arcade_colors.dart';
import 'package:flutter/material.dart';

import 'arcade_typography.dart';

class ArcadeCoinAmount extends StatelessWidget {
  const ArcadeCoinAmount({
    super.key,
    required this.amount,
    this.color = ArcadeColors.primary,
    this.textStyle = ArcadeTypography.value,
    this.iconSize = 20,
    this.gap = 5,
  });
  final String amount;
  final Color color;
  final TextStyle textStyle;
  final double iconSize;
  final double gap;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      PixelCoinIcon(size: iconSize),
      SizedBox(width: gap),
      Text(amount, style: textStyle.copyWith(color: color)),
    ],
  );
}

class PixelCoinIcon extends StatelessWidget {
  const PixelCoinIcon({super.key, this.size = 20});
  final double size;
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: CustomPaint(
      size: Size.square(size),
      painter: const _PixelCoinPainter(),
    ),
  );
}

class _PixelCoinPainter extends CustomPainter {
  const _PixelCoinPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final unit = size.shortestSide / 8;
    final outline = Paint()
      ..color = const Color(0xFF8D5D16)
      ..isAntiAlias = false;
    final coin = Paint()
      ..color = ArcadeColors.primary
      ..isAntiAlias = false;
    final shade = Paint()
      ..color = const Color(0xFFD99828)
      ..isAntiAlias = false;
    final shine = Paint()
      ..color = const Color(0xFFFFF0A6)
      ..isAntiAlias = false;
    void pixelRect(int x, int y, int width, int height, Paint paint) {
      canvas.drawRect(
        Rect.fromLTWH(x * unit, y * unit, width * unit, height * unit),
        paint,
      );
    }

    pixelRect(2, 0, 4, 1, outline);
    pixelRect(1, 1, 6, 6, outline);
    pixelRect(2, 7, 4, 1, outline);
    pixelRect(2, 1, 4, 1, coin);
    pixelRect(1, 2, 6, 4, coin);
    pixelRect(2, 6, 4, 1, shade);
    pixelRect(6, 2, 1, 4, shade);
    pixelRect(2, 2, 1, 1, shine);
    pixelRect(3, 2, 2, 1, shine);
    pixelRect(3, 4, 2, 1, shade);
  }

  @override
  bool shouldRepaint(_PixelCoinPainter oldDelegate) => false;
}
