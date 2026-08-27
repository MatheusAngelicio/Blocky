import 'package:flutter/painting.dart';

abstract final class BlockColorPalette {
  static const _hueStep = 18.0;
  static const _saturation = 0.82;
  static const _value = 0.95;

  static Color colorForBlock(int index, {double initialHue = 0.0}) {
    final hue = (initialHue + index * _hueStep) % 360;

    return HSVColor.fromAHSV(1.0, hue, _saturation, _value).toColor();
  }
}
