import '../models/tcg_card.dart';
import 'storage_service.dart';

class DexCollectionService {
  final StorageService _storage;

  DexCollectionService(this._storage);

  Future<Map<String, dynamic>> getDexStats(String setName) async {
    try {
      final cards = await _storage.getCards();
      final setCards = cards.where((card) => card.setName == setName).toList();

      return {
        'cardCount': setCards.length,
        'totalValue': setCards.fold<double>(
          0,
          (sum, card) => sum + (card.price ?? 0),
        ),
        'variants': setCards.map((card) => card.number).toSet().length,
        'cards': setCards,
      };
    } catch (e) {
      print('Error getting dex stats: $e');
      return {
        'cardCount': 0,
        'totalValue': 0.0,
        'variants': 0,
        'cards': <TcgCard>[],
      };
    }
  }

  Future<Map<String, dynamic>> getPokemonStats(String pokemonName) async {
    try {
      final cards = await _storage.getCards();
      final pokemonCards = cards.where((card) => 
        card.name.toLowerCase().contains(pokemonName.toLowerCase())
      ).toList();

      return {
        'isCollected': pokemonCards.isNotEmpty,
        'cardCount': pokemonCards.length,
        'totalValue': pokemonCards.fold<double>(
          0,
          (sum, card) => sum + (card.price ?? 0),
        ),
        'cards': pokemonCards,
      };
    } catch (e) {
      print('Error getting pokemon stats: $e');
      return {
        'isCollected': false,
        'cardCount': 0,
        'totalValue': 0.0,
        'cards': <TcgCard>[],
      };
    }
  }

  // Get overall dex completion stats
  Future<Map<String, dynamic>> getDexCompletionStats() async {
    final cards = await _storage.getCards();
    final uniquePokemon = cards
        .map((card) => card.name.split(' ')[0]) // Get base Pokémon name
        .toSet()
        .length;

    return {
      'collected': uniquePokemon,
      'totalValue': cards.fold<double>(
        0,
        (sum, card) => sum + (card.price ?? 0),
      ),
    };
  }
}
