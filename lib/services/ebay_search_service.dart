import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/tcg_card.dart';

class EbaySearchService extends ChangeNotifier {
  static const String _baseUrl = 'https://www.ebay.com';
  
  // Get a properly formatted eBay search URL for MTG cards
  String getMtgSearchUrl(String cardName, {String? setName, String? number}) {
    final List<String> queryParts = [cardName, 'mtg', 'card'];
    
    if (setName != null && setName.isNotEmpty) {
      queryParts.add(setName);
    }
    
    if (number != null && number.isNotEmpty) {
      queryParts.add(number);
    }
    
    final queryString = queryParts.join(' ');
    return 'https://www.ebay.com/sch/i.html?_nkw=${Uri.encodeComponent(queryString)}&_sacat=2536';
  }
  
  // Get a properly formatted eBay search URL for Pokemon cards
  String getPokemonSearchUrl(String cardName, {String? setName, String? number}) {
    final List<String> queryParts = [cardName, 'pokemon', 'card'];
    
    if (setName != null && setName.isNotEmpty) {
      queryParts.add(setName);
    }
    
    if (number != null && number.isNotEmpty) {
      queryParts.add(number);
    }
    
    final queryString = queryParts.join(' ');
    return 'https://www.ebay.com/sch/i.html?_nkw=${Uri.encodeComponent(queryString)}&_sacat=183454';
  }
  
  // Generic method to handle both MTG and Pokemon cards
  String getCardSearchUrl(TcgCard card) {
    if (card.isMtgCard) {
      return getMtgSearchUrl(card.name, setName: card.setName, number: card.number);
    } else {
      return getPokemonSearchUrl(card.name, setName: card.setName, number: card.number);
    }
  }
  
  // Method to get search URL for complete sets
  String getSetSearchUrl(String setName, bool isMtg) {
    final List<String> queryParts = [
      '"$setName"',
      'complete set',
      isMtg ? 'mtg' : 'pokemon'
    ];
    
    final queryString = queryParts.join(' ');
    final categoryId = isMtg ? '2536' : '183454';
    return 'https://www.ebay.com/sch/i.html?_nkw=${Uri.encodeComponent(queryString)}&_sacat=$categoryId';
  }
}
