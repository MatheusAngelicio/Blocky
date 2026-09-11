import 'package:blocky/design_system/arcade_colors.dart';
import 'package:blocky/design_system/arcade_panel.dart';
import 'package:blocky/design_system/arcade_typography.dart';
import 'package:flutter/material.dart';

class ArcadeStat extends StatelessWidget {
  const ArcadeStat({
    super.key,
    required this.label,
    required this.value,
    this.accent = ArcadeColors.outline,
    this.valueStyle = ArcadeTypography.value,
    this.valueWidget,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
  });
  final String label;
  final String value;
  final Color accent;
  final TextStyle valueStyle;
  final Widget? valueWidget;
  final EdgeInsetsGeometry padding;
  @override
  Widget build(BuildContext context) => ArcadePanel(
    accent: accent,
    padding: padding,
    shadowOffset: const Offset(3, 4),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: ArcadeTypography.label, textAlign: TextAlign.center),
        const SizedBox(height: 6),
        valueWidget ??
            Text(value, style: valueStyle, textAlign: TextAlign.center),
      ],
    ),
  );
}
