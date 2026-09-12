import 'package:blocky/design_system/design_system.dart';
import 'package:blocky/app/app_configuration.dart';
import 'package:blocky/app/blocky_localizations.dart';
import 'package:blocky/game/game_settings.dart';
import 'package:blocky/ui/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class BlockyApp extends StatefulWidget {
  const BlockyApp({
    super.key,
    this.unlockAllThemes = AppConfiguration.unlockAllThemes,
  });

  final bool unlockAllThemes;

  @override
  State<BlockyApp> createState() => _BlockyAppState();
}

class _BlockyAppState extends State<BlockyApp> {
  Locale? _locale;

  void _applyLanguage(GameSettings settings) {
    final locale = switch (settings.language) {
      AppLanguage.system => null,
      AppLanguage.english => const Locale('en'),
      AppLanguage.portuguese => const Locale('pt'),
    };
    if (_locale == locale) return;

    setState(() => _locale = locale);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Blocky',
      theme: ArcadeTheme.dark(),
      locale: _locale,
      supportedLocales: BlockyLocalizations.supportedLocales,
      localizationsDelegates: const [
        BlockyLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      localeListResolutionCallback: (locales, supportedLocales) {
        final deviceLocale = locales?.first;
        return supportedLocales.firstWhere(
          (supported) => supported.languageCode == deviceLocale?.languageCode,
          orElse: () => const Locale('en'),
        );
      },
      home: HomeScreen(
        onSettingsChanged: _applyLanguage,
        unlockAllThemes: widget.unlockAllThemes,
      ),
    );
  }
}
