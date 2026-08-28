import 'package:flutter/painting.dart';

abstract final class BlockColorPalette {
  static const defaultHueStep = 8.0;
  static const defaultSaturation = 0.72;
  static const defaultValue = 0.94;

  static Color colorForBlock(
    int index, {
    double initialHue = 0.0,
    double hueStep = defaultHueStep,
    double saturation = defaultSaturation,
    double value = defaultValue,
  }) {
    final hue = (initialHue + index * hueStep) % 360;

    return HSVColor.fromAHSV(1.0, hue, saturation, value).toColor();
  }
}
