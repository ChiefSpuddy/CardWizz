import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/dex_names_service.dart';
import '../services/dex_collection_service.dart';
import '../services/storage_service.dart';
import '../widgets/sign_in_button.dart';
import '../providers/app_state.dart';
import 'card_details_screen.dart';

class DexScreen extends StatefulWidget {
  const DexScreen({super.key});

  @override
  State<DexScreen> createState() => _DexScreenState();
}

class _DexScreenState extends State<DexScreen> {
  final _searchController = TextEditingController();
  final _namesService = DexNamesService();
  late final DexCollectionService _collectionService;
  List<String> _allDexNames = [];
  List<String> _filteredDexNames = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _collectionService = DexCollectionService(
      Provider.of<StorageService>(context, listen: false),
    );
    _loadDexNames();
  }

  Future<void> _loadDexNames() async {
    setState(() => _isLoading = true);
    final names = await _namesService.loadDexNames();
    if (mounted) {
      setState(() {
        _allDexNames = names;
        _filteredDexNames = names;
        _isLoading = false;
      });
    }
  }

  void _filterDexNames(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredDexNames = _allDexNames;
      } else {
        _filteredDexNames = _allDexNames
            .where((name) => name.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  Widget _buildPokemonTile(String pokemonName) {
    final dexNumber = _namesService.getDexNumber(pokemonName);
    
    return FutureBuilder<Map<String, dynamic>>(
      future: _collectionService.getPokemonStats(pokemonName),
      builder: (context, snapshot) {
        final stats = snapshot.data;
        final isCollected = stats?['isCollected'] ?? false;
        final cardCount = stats?['cardCount'] ?? 0;

        return ListTile(
          leading: CircleAvatar(
            child: Text('#${dexNumber.toString().padLeft(3, '0')}'),
          ),
          title: Text(pokemonName),
          subtitle: isCollected 
            ? Text('$cardCount cards collected')
            : const Text('Not collected'),
          trailing: isCollected
            ? const Icon(Icons.check_circle, color: Colors.green)
            : null,
          onTap: isCollected 
            ? () => _showPokemonCards(context, pokemonName, stats?['cards'])
            : null,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final isSignedIn = appState.isAuthenticated;

    if (!isSignedIn) {
      return const SignInButton(
        message: 'Sign in to view your collection stats',
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('TCG Sets'),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search sets...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _filterDexNames('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: _filterDexNames,
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: _filteredDexNames.length,
                    itemBuilder: (context, index) => _buildPokemonTile(_filteredDexNames[index]),
                  ),
          ),
        ],
      ),
    );
  }

  void _showPokemonCards(BuildContext context, String pokemonName, List<TcgCard> cards) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (_, controller) => Column(
          children: [
            AppBar(
              title: Text('$pokemonName Cards'),
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            Expanded(
              child: GridView.builder(
                controller: controller,
                padding: const EdgeInsets.all(8),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 0.7,
                ),
                itemCount: cards.length,
                itemBuilder: (context, index) {
                  final card = cards[index];
                  return GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CardDetailsScreen(card: card),
                      ),
                    ),
                    child: Card(
                      child: Column(
                        children: [
                          Expanded(
                            child: Image.network(
                              card.imageUrl,
                              fit: BoxFit.contain,
                            ),
                          ),
                          if (card.price != null)
                            Padding(
                              padding: const EdgeInsets.all(4),
                              child: Text(
                                '€${card.price!.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
