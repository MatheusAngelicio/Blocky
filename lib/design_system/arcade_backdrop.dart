import 'package:blocky/design_system/arcade_colors.dart';
import 'package:flutter/material.dart';

class ArcadeBackdrop extends StatelessWidget {
  const ArcadeBackdrop({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
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
