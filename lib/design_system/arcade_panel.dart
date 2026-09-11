import 'package:blocky/design_system/arcade_colors.dart';
import 'package:flutter/material.dart';

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
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: backgroundColor,
      border: Border.all(color: accent, width: borderWidth),
      boxShadow: [BoxShadow(color: ArcadeColors.shadow, offset: shadowOffset)],
    ),
    child: child,
  );
}
