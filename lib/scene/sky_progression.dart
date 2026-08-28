import 'package:flutter/material.dart';
import 'package:flutter_scene/scene.dart';
import 'package:vector_math/vector_math.dart' as vm;

/// Paleta contínua que comunica a altura da torre sem criar cenários extras.
abstract final class SkyProgression {
  /// A Home usa a mesma base do primeiro céu para uma transição acolhedora.
  static const homeBackgroundColor = Color(0xFF70C88B);

  static const _scoreToReachNight = 80;

  static final _stops = <_SkyStop>[
    _SkyStop(
      0.0,
      SkyPalette(
        zenith: vm.Vector3(0.34, 0.73, 0.52),
        horizon: vm.Vector3(0.48, 0.80, 0.48),
        ground: vm.Vector3(0.62, 0.86, 0.36),
        sun: vm.Vector3(1.5, 1.4, 1.1),
      ),
    ),
    _SkyStop(
      0.22,
      SkyPalette(
        zenith: vm.Vector3(0.72, 0.50, 0.28),
        horizon: vm.Vector3(0.98, 0.69, 0.34),
        ground: vm.Vector3(0.74, 0.50, 0.25),
        sun: vm.Vector3(1.8, 1.15, 0.72),
      ),
    ),
    _SkyStop(
      0.45,
      SkyPalette(
        zenith: vm.Vector3(0.68, 0.22, 0.31),
        horizon: vm.Vector3(1.0, 0.40, 0.24),
        ground: vm.Vector3(0.42, 0.15, 0.19),
        sun: vm.Vector3(1.7, 0.56, 0.35),
      ),
    ),
    _SkyStop(
      0.65,
      SkyPalette(
        zenith: vm.Vector3(0.26, 0.10, 0.42),
        horizon: vm.Vector3(0.48, 0.20, 0.57),
        ground: vm.Vector3(0.18, 0.07, 0.27),
        sun: vm.Vector3(0.68, 0.34, 0.9),
      ),
    ),
    _SkyStop(
      0.82,
      SkyPalette(
        zenith: vm.Vector3(0.04, 0.09, 0.28),
        horizon: vm.Vector3(0.12, 0.20, 0.44),
        ground: vm.Vector3(0.03, 0.05, 0.13),
        sun: vm.Vector3(0.2, 0.32, 0.72),
      ),
    ),
    _SkyStop(
      1.0,
      SkyPalette(
        zenith: vm.Vector3(0.008, 0.015, 0.06),
        horizon: vm.Vector3(0.025, 0.045, 0.12),
        ground: vm.Vector3(0.005, 0.008, 0.02),
        sun: vm.Vector3(0.04, 0.06, 0.16),
      ),
    ),
  ];

  static SkyPalette paletteForScore(int score) {
    final progress = (score / _scoreToReachNight).clamp(0.0, 1.0).toDouble();
    final upperIndex = _stops.indexWhere((stop) => stop.progress >= progress);
    if (upperIndex <= 0) return _stops.first.palette;

    final from = _stops[upperIndex - 1];
    final to = _stops[upperIndex];
    final segmentProgress =
        ((progress - from.progress) / (to.progress - from.progress))
            .clamp(0.0, 1.0)
            .toDouble();
    return SkyPalette.lerp(from.palette, to.palette, segmentProgress);
  }

  static void applyTo(GradientSkySource sky, int score) {
    final palette = paletteForScore(score);
    sky.zenithColor = palette.zenith;
    sky.horizonColor = palette.horizon;
    sky.groundColor = palette.ground;
    sky.sunColor = palette.sun;
  }
}

class SkyPalette {
  const SkyPalette({
    required this.zenith,
    required this.horizon,
    required this.ground,
    required this.sun,
  });

  final vm.Vector3 zenith;
  final vm.Vector3 horizon;
  final vm.Vector3 ground;
  final vm.Vector3 sun;

  static SkyPalette lerp(SkyPalette from, SkyPalette to, double progress) {
    vm.Vector3 blend(vm.Vector3 start, vm.Vector3 end) =>
        start + (end - start) * progress;

    return SkyPalette(
      zenith: blend(from.zenith, to.zenith),
      horizon: blend(from.horizon, to.horizon),
      ground: blend(from.ground, to.ground),
      sun: blend(from.sun, to.sun),
    );
  }
}

class _SkyStop {
  const _SkyStop(this.progress, this.palette);

  final double progress;
  final SkyPalette palette;
}
