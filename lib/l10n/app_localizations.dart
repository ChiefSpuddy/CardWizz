import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'totalCards': 'Total Cards',
      'collections': 'Collections',
      'value': 'Value',
      'settings': 'Settings',
      'language': 'Language',
      'darkMode': 'Dark Mode',
      'signOut': 'Sign Out',
      'notifications': 'Notifications',
      'backupCollection': 'Backup Collection',
      'currency': 'Currency',
      'editProfile': 'Edit Profile',
      'privacySettings': 'Privacy Settings',
      'account': 'Account',
      'selectLanguage': 'Select Language',
      'overview': 'Overview',
      'home': 'Home',
      'binders': 'Binders',
      'analytics': 'Analytics',
      'searchCards': 'Search cards...',
      'noCardsFound': 'No cards found',
      'tryAdjustingSearch': 'Try adjusting your search terms',
      'searchResults': 'Search Results',
      'signInToTrack': 'Sign in to track your collection value and stats',
      'popularCards': 'Popular Cards',
      'popularSearches': 'Popular Searches',
      'recentSets': 'Recent Sets',
      'recentSearches': 'Recent Searches',
      'clear': 'Clear',
      'sortBy': 'Sort By',
      'done': 'Done',
      'searching': 'Searching...',
    },
    'es': {
      'totalCards': 'Total de Cartas',
      'collections': 'Colecciones',
      'value': 'Valor',
      'settings': 'Configuración',
      'language': 'Idioma',
      'darkMode': 'Modo Oscuro',
      'signOut': 'Cerrar Sesión',
      'notifications': 'Notificaciones',
      'backupCollection': 'Copia de Seguridad',
      'currency': 'Moneda',
      'editProfile': 'Editar Perfil',
      'privacySettings': 'Privacidad',
      'account': 'Cuenta',
      'selectLanguage': 'Seleccionar Idioma',
      'overview': 'Resumen',
      'home': 'Inicio',
      'binders': 'Carpetas',
      'analytics': 'Análisis',
      'searchCards': 'Buscar cartas...',
      'noCardsFound': 'No se encontraron cartas',
      'tryAdjustingSearch': 'Intenta ajustar tu búsqueda',
      'searchResults': 'Resultados de búsqueda',
      'signInToTrack': 'Inicia sesión para seguir el valor de tu colección',
      'popularCards': 'Cartas Populares',
      'popularSearches': 'Búsquedas Populares',
      'recentSets': 'Sets Recientes',
      'recentSearches': 'Búsquedas Recientes',
      'clear': 'Borrar',
      'sortBy': 'Ordenar Por',
      'done': 'Listo',
      'searching': 'Buscando...',
    },
    'ja': {
      'totalCards': 'カード総数',
      'collections': 'コレクション',
      'value': '価値',
      'settings': '設定',
      'language': '言語',
      'darkMode': 'ダークモード',
      'signOut': 'サインアウト',
      'notifications': '通知',
      'backupCollection': 'バックアップ',
      'currency': '通貨',
      'editProfile': 'プロフィール編集',
      'privacySettings': 'プライバシー設定',
      'account': 'アカウント',
      'selectLanguage': '言語を選択',
      'overview': '概要',
      'home': 'ホーム',
      'binders': 'バインダー',
      'analytics': '分析',
      'searchCards': 'カードを検索...',
      'noCardsFound': 'カードが見つかりません',
      'tryAdjustingSearch': '検索条件を変更してみてください',
      'searchResults': '検索結果',
      'signInToTrack': 'サインインしてコレクションを管理',
      'popularCards': '人気のカード',
      'popularSearches': '人気の検索',
      'recentSets': '最新セット',
      'recentSearches': '最近の検索',
      'clear': 'クリア',
      'sortBy': '並び替え',
      'done': '完了',
      'searching': '検索中...',
    },
  };

  String translate(String key) => 
      _localizedValues[locale.languageCode]?[key] ?? 
      _localizedValues['en']?[key] ?? 
      key;
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'es', 'ja'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async => AppLocalizations(locale);

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}
