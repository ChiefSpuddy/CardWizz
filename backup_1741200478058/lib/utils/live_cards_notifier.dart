import 'package:flutter/foundation.dart';
import '../models/tcg_card.dart';

class LiveCardsNotifier extends ChangeNotifier {
  final List<TcgCard> _cards = [];
  
  List<TcgCard> get cards => List.unmodifiable(_cards);
  
  void update(List<TcgCard> newCards) {
    _cards.clear();
    _cards.addAll(newCards);
    notifyListeners();
  }
  
  void add(TcgCard card) {
    if (!_cards.any((c) => c.id == card.id)) {
      _cards.add(card);
      notifyListeners();
    }
  }
  
  void remove(String cardId) {
    _cards.removeWhere((card) => card.id == cardId);
    notifyListeners();
  }
  
  void clear() {
    _cards.clear();
    notifyListeners();
  }
}
