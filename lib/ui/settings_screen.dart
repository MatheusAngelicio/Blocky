import 'package:blocky/app/arcade_colors.dart';
import 'package:blocky/app/arcade_design_system.dart';
import 'package:blocky/game/game_settings.dart';
import 'package:blocky/game/game_settings_storage.dart';
import 'package:flutter/material.dart';

/// Configura preferências de apresentação que serão usadas na próxima partida.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.initialSettings,
    required this.settingsStorage,
  });

  final GameSettings initialSettings;
  final GameSettingsStorage settingsStorage;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late GameSettings _settings = widget.initialSettings;
  Future<void> _pendingSave = Future.value();
  var _isClosing = false;
  var _canPop = false;

  void _setSettings(GameSettings settings) {
    setState(() => _settings = settings);
  }

  void _saveSettings() {
    final settings = _settings;
    _pendingSave = _pendingSave.then(
      (_) => widget.settingsStorage.save(settings),
    );
  }

  Future<void> _close() async {
    if (_isClosing) return;

    _isClosing = true;
    _saveSettings();
    await _pendingSave;
    if (!mounted) return;

    setState(() => _canPop = true);
    await WidgetsBinding.instance.endOfFrame;
    if (mounted) Navigator.of(context).pop(_settings);
  }

  @override
  Widget build(BuildContext context) {
    final volumePercent = (_settings.soundVolume * 100).round();

    return PopScope<Object?>(
      canPop: _canPop,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _close();
      },
      child: Scaffold(
        backgroundColor: ArcadeColors.canvas,
        body: ArcadeBackdrop(
          child: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                          onPressed: _close,
                          color: ArcadeColors.white,
                          icon: const Icon(Icons.arrow_back),
                          tooltip: 'Back',
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'SETTINGS',
                        textAlign: TextAlign.center,
                        style: ArcadeTypography.heading,
                      ),
                      const SizedBox(height: 28),
                      ArcadePanel(
                        accent: ArcadeColors.primary,
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'SOUND VOLUME',
                              style: ArcadeTypography.button.copyWith(
                                color: ArcadeColors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '$volumePercent%',
                              style: ArcadeTypography.value.copyWith(
                                color: ArcadeColors.primary,
                              ),
                            ),
                            Slider(
                              value: _settings.soundVolume,
                              onChanged: (volume) => _setSettings(
                                _settings.copyWith(soundVolume: volume),
                              ),
                              onChangeEnd: (_) => _saveSettings(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      ArcadePanel(
                        accent: ArcadeColors.secondary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 10,
                        ),
                        child: Material(
                          color: ArcadeColors.transparent,
                          child: SwitchListTile.adaptive(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              'VIBRATION',
                              style: ArcadeTypography.button.copyWith(
                                color: ArcadeColors.white,
                              ),
                            ),
                            subtitle: Text(
                              _settings.hapticsEnabled ? 'ON' : 'OFF',
                              style: ArcadeTypography.label.copyWith(
                                color: _settings.hapticsEnabled
                                    ? ArcadeColors.secondary
                                    : ArcadeColors.muted,
                              ),
                            ),
                            value: _settings.hapticsEnabled,
                            onChanged: (enabled) {
                              _setSettings(
                                _settings.copyWith(hapticsEnabled: enabled),
                              );
                              _saveSettings();
                            },
                          ),
                        ),
                      ),
                      const Spacer(),
                      ArcadeButton(
                        label: 'DONE',
                        onPressed: _close,
                        color: ArcadeColors.primary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
