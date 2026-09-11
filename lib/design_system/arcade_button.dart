import 'package:blocky/design_system/arcade_colors.dart';
import 'package:blocky/design_system/arcade_typography.dart';
import 'package:flutter/material.dart';

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
