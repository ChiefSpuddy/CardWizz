import 'package:flutter/foundation.dart';
import '../models/card_language.dart';

class LanguageProvider extends ChangeNotifier {
  CardLanguage _currentLanguage = CardLanguage.english;
  
  CardLanguage get currentLanguage => _currentLanguage;
  
  void setLanguage(CardLanguage language) {
    if (_currentLanguage != language) {
      _currentLanguage = language;
      notifyListeners();
    }
  }
}
