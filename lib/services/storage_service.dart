import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/business_card_model.dart';

class StorageService {
  static const String _cardsKey = 'business_cards';
  final SharedPreferences _prefs;

  StorageService(this._prefs);

  static Future<StorageService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return StorageService(prefs);
  }

  Future<List<BusinessCard>> getCards() async {
    final String? cardsJson = _prefs.getString(_cardsKey);
    if (cardsJson == null) return [];

    final List<dynamic> decoded = json.decode(cardsJson);
    return decoded.map((json) => BusinessCard.fromJson(json)).toList();
  }

  Future<void> saveCard(BusinessCard card) async {
    final cards = await getCards();
    cards.add(card);
    await _saveCards(cards);
  }

  Future<void> _saveCards(List<BusinessCard> cards) async {
    final String encoded = json.encode(cards.map((c) => c.toJson()).toList());
    await _prefs.setString(_cardsKey, encoded);
  }
}
