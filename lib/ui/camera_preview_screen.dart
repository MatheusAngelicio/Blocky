import 'package:blocky/app/arcade_colors.dart';
import 'package:blocky/app/arcade_design_system.dart';
import 'package:blocky/app/blocky_localizations.dart';
import 'package:blocky/game/block_theme.dart';
import 'package:blocky/scene/camera_preview_scene.dart';
import 'package:flutter/material.dart';

/// Permite ajustar a órbita da câmera usando uma representação estática.
class CameraPreviewScreen extends StatefulWidget {
  const CameraPreviewScreen({
    super.key,
    required this.initialCameraAngle,
    required this.blockTheme,
  });

  final double initialCameraAngle;
  final BlockTheme blockTheme;

  @override
  State<CameraPreviewScreen> createState() => _CameraPreviewScreenState();
}

class _CameraPreviewScreenState extends State<CameraPreviewScreen> {
  late double _cameraAngle = widget.initialCameraAngle;

  void _updateCameraAngle(DragUpdateDetails details) {
    setState(() {
      _cameraAngle = (_cameraAngle + details.delta.dx / 180)
          .clamp(-1.0, 1.0)
          .toDouble();
    });
  }

  void _restoreDefaultCamera() => setState(() => _cameraAngle = 0.0);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragUpdate: _updateCameraAngle,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CameraPreviewScene(
              cameraAngle: _cameraAngle,
              blockTheme: widget.blockTheme,
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        color: ArcadeColors.white,
                        icon: const Icon(Icons.arrow_back),
                        tooltip: l10n.back,
                      ),
                    ),
                    Text(l10n.cameraPreview, style: ArcadeTypography.heading),
                    const Spacer(),
                    IgnorePointer(
                      child: ArcadePanel(
                        accent: ArcadeColors.strongOutline,
                        backgroundColor: ArcadeColors.hudSurface,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        child: Text(
                          l10n.dragCamera,
                          textAlign: TextAlign.center,
                          style: ArcadeTypography.label.copyWith(
                            color: ArcadeColors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ArcadeButton(
                      label: l10n.defaultCamera,
                      color: ArcadeColors.strongOutline,
                      onPressed: _restoreDefaultCamera,
                    ),
                    const SizedBox(height: 12),
                    ArcadeButton(
                      label: l10n.confirmCamera,
                      onPressed: () => Navigator.of(context).pop(_cameraAngle),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
