import 'package:blocky/game/block_theme.dart';
import 'package:blocky/game/game_settings.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Textos da interface do Blocky para os idiomas atualmente suportados.
class BlockyLocalizations {
  const BlockyLocalizations(this.locale);

  static const supportedLocales = [Locale('en'), Locale('pt')];
  static const delegate = _BlockyLocalizationsDelegate();

  final Locale locale;

  bool get _isPortuguese => locale.languageCode == 'pt';

  String get tagline => _isPortuguese ? 'EMPILHE BLOCOS' : 'STACK IT UP';
  String get blockyCoins => 'BLOCKY COINS';
  String get best => _isPortuguese ? 'RECORDE' : 'BEST';
  String get currentSet => _isPortuguese ? 'TEMA ATUAL' : 'CURRENT SET';
  String get play => _isPortuguese ? 'JOGAR' : 'PLAY';
  String get blockTheme => _isPortuguese ? 'TEMA DOS BLOCOS' : 'BLOCK THEME';
  String get settings => _isPortuguese ? 'CONFIGURAÇÕES' : 'SETTINGS';
  String get chooseBlockTheme =>
      _isPortuguese ? 'ESCOLHA O TEMA' : 'CHOOSE BLOCK THEME';
  String get selected => _isPortuguese ? 'SELECIONADO' : 'SELECTED';
  String get available => _isPortuguese ? 'DISPONÍVEL' : 'AVAILABLE';
  String get locked => _isPortuguese ? 'BLOQUEADO' : 'LOCKED';
  String get unlockTheme => _isPortuguese ? 'DESBLOQUEAR' : 'UNLOCK';
  String get notEnoughCoins =>
      _isPortuguese ? 'COINS INSUFICIENTES' : 'NOT ENOUGH COINS';
  String get themeUnlocked =>
      _isPortuguese ? 'TEMA DESBLOQUEADO!' : 'THEME UNLOCKED!';
  String get soundVolume => _isPortuguese ? 'VOLUME DO SOM' : 'SOUND VOLUME';
  String get vibration => _isPortuguese ? 'VIBRAÇÃO' : 'VIBRATION';
  String get language => _isPortuguese ? 'IDIOMA' : 'LANGUAGE';
  String get cameraPreview =>
      _isPortuguese ? 'ÂNGULO DA CÂMERA' : 'CAMERA ANGLE';
  String get configureCamera =>
      _isPortuguese ? 'CONFIGURAR CÂMERA' : 'CONFIGURE CAMERA';
  String get dragCamera =>
      _isPortuguese ? 'ARRASTE PARA MOVER A CÂMERA' : 'DRAG TO MOVE CAMERA';
  String get confirmCamera =>
      _isPortuguese ? 'CONFIRMAR CÂMERA' : 'CONFIRM CAMERA';
  String get defaultCamera =>
      _isPortuguese ? 'CÂMERA PADRÃO' : 'DEFAULT CAMERA';
  String get automatic => _isPortuguese ? 'AUTOMÁTICO' : 'AUTOMATIC';
  String get on => _isPortuguese ? 'LIGADA' : 'ON';
  String get off => _isPortuguese ? 'DESLIGADA' : 'OFF';
  String get done => _isPortuguese ? 'CONCLUÍDO' : 'DONE';
  String get back => _isPortuguese ? 'Voltar' : 'Back';
  String get score => 'SCORE';
  String get gameOver => _isPortuguese ? 'FIM DE JOGO' : 'GAME OVER';
  String get playAgain => _isPortuguese ? 'JOGAR NOVAMENTE' : 'PLAY AGAIN';
  String get home => 'HOME';

  String unlockThemeForCoins(int price) => '$unlockTheme · $price BLOCKY COINS';

  String perfectFeedback({required int streak, required bool isRecovery}) {
    if (isRecovery) {
      return _isPortuguese ? 'RECUPERAÇÃO PERFEITA!' : 'PERFECT RECOVERY!';
    }
    final suffix = streak > 1 ? ' x$streak' : '';
    return _isPortuguese ? 'PERFEITO!$suffix' : 'PERFECT!$suffix';
  }

  String themeName(BlockTheme theme) => switch (theme) {
    BlockTheme.classic => _isPortuguese ? 'Clássico' : 'Classic',
    BlockTheme.jelly => 'Jelly',
    BlockTheme.chocolate => 'Chocolate',
    BlockTheme.cheese => _isPortuguese ? 'Queijo' : 'Cheese',
    BlockTheme.neon => 'Neon',
    BlockTheme.lego => 'Lego',
    BlockTheme.ruby => _isPortuguese ? 'Rubi' : 'Ruby',
  };

  String rarityName(BlockThemeRarity rarity) => switch (rarity) {
    BlockThemeRarity.common => _isPortuguese ? 'Comum' : 'Common',
    BlockThemeRarity.rare => _isPortuguese ? 'Rara' : 'Rare',
    BlockThemeRarity.epic => _isPortuguese ? 'Épica' : 'Epic',
    BlockThemeRarity.legendary => _isPortuguese ? 'Lendária' : 'Legendary',
  };

  String languageName(AppLanguage language) => switch (language) {
    AppLanguage.system => automatic,
    AppLanguage.english => 'English',
    AppLanguage.portuguese => 'Português',
  };

  static BlockyLocalizations of(BuildContext context) {
    return Localizations.of<BlockyLocalizations>(
          context,
          BlockyLocalizations,
        ) ??
        const BlockyLocalizations(Locale('en'));
  }
}

extension BlockyLocalizationsContext on BuildContext {
  BlockyLocalizations get l10n => BlockyLocalizations.of(this);
}

class _BlockyLocalizationsDelegate
    extends LocalizationsDelegate<BlockyLocalizations> {
  const _BlockyLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => BlockyLocalizations.supportedLocales.any(
    (supported) => supported.languageCode == locale.languageCode,
  );

  @override
  Future<BlockyLocalizations> load(Locale locale) =>
      SynchronousFuture(BlockyLocalizations(locale));

  @override
  bool shouldReload(_BlockyLocalizationsDelegate old) => false;
}
