import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lottie/lottie.dart';
import 'package:shimmer/shimmer.dart';
import '../models/tcg_card.dart';
import '../services/collection_index_service.dart';
import '../services/storage_service.dart';
import '../providers/currency_provider.dart';
import '../constants/colors.dart';  // Add this import
import '../services/dex_collection_service.dart';  // Add this import
import '../services/poke_api_service.dart';  // Add this import
import '../services/tcg_api_service.dart';  // Add this import
import 'card_details_screen.dart';
import 'dart:math' as math;  // Add this import at the top

class CollectionIndexScreen extends StatefulWidget {
  const CollectionIndexScreen({super.key});

  @override
  State<CollectionIndexScreen> createState() => _CollectionIndexScreenState();
}

class _CollectionIndexScreenState extends State<CollectionIndexScreen> {
  final _namesService = CollectionIndexService();
  late final DexCollectionService _collectionService;
  // Remove unused tcgApi service since we're not fetching images directly anymore
  List<String> _allDexNames = [];
  bool _isLoading = true;
  String? _selectedGeneration;

  final Map<String, (int, int)> _series = {
    'Series 1': (1, 151),
    'Series 2': (152, 251),
    'Series 3': (252, 386),
  };

  @override
  void initState() {
    super.initState();
    _collectionService = DexCollectionService(
      Provider.of<StorageService>(context, listen: false),
    );
    _initializeCollection();
  }

  Future<void> _initializeCollection() async {
    await _collectionService.initialize();
    _loadInitialSeries();
  }

  Future<void> _loadInitialSeries() async {
    await _selectGeneration('Series 1');
  }

  Widget _buildCreatureTile(String creatureName) {
    final searchName = _namesService.normalizeSearchQuery(creatureName);
    final stats = _collectionService.getCreatureStats(searchName);
    final cards = stats['cards'] as List<TcgCard>? ?? [];
    final hasCards = cards.isNotEmpty;
    
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: hasCards ? () => _showCardsDetail(cards) : null,
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  flex: 3,
                  child: hasCards
                    ? CachedNetworkImage(
                        imageUrl: cards.first.imageUrl,
                        fit: BoxFit.contain,
                        errorWidget: (_, __, ___) => _buildPlaceholder(creatureName),
                      )
                    : _buildPlaceholder(creatureName),
                ),
                Padding(
                  padding: const EdgeInsets.all(4),
                  child: Text(
                    creatureName,
                    style: TextStyle(
                      fontSize: 12,
                      color: hasCards ? Colors.black87 : Colors.grey[500],
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (hasCards && cards.length > 1)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${cards.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder(String name) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.card_giftcard, color: Colors.grey[400]), // Changed from catching_pokemon
            const SizedBox(height: 4),
            Text(
              name,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[400],
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  void _showCardsDetail(List<TcgCard> cards) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => Column(
          children: [
            AppBar(
              title: Text('${cards.length} Cards'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            Expanded(
              child: GridView.builder(
                controller: controller,
                padding: const EdgeInsets.all(8),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.7,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: cards.length,
                itemBuilder: (context, index) => Card(
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CardDetailsScreen(card: cards[index]),
                      ),
                    ),
                    child: Column(
                      children: [
                        Expanded(
                          child: CachedNetworkImage(
                            imageUrl: cards[index].imageUrl,
                            fit: BoxFit.contain,
                          ),
                        ),
                        if (cards[index].price != null)
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              '\$${cards[index].price!.toStringAsFixed(2)}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenerationProgress() {
    return SizedBox(  // Changed from Container to SizedBox
      height: 110,    // Increased height slightly
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _series.length,
        itemBuilder: (context, index) {
          final series = _series.entries.elementAt(index);
          final (start, end) = series.value;
          final total = end - start + 1;
          final collected = _collectionService.getCollectedInRange(start, end);
          final isSelected = series.key == _selectedGeneration;
          
          final progress = total > 0 ? collected / total : 0.0;
          
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ConstrainedBox(  // Added ConstrainedBox for size constraints
              constraints: const BoxConstraints(
                minWidth: 100,
                maxWidth: 130,
              ),
              child: Card(
                elevation: isSelected ? 4 : 1,
                color: isSelected 
                    ? Theme.of(context).colorScheme.primaryContainer 
                    : Theme.of(context).cardColor,
                child: InkWell(
                  onTap: () => _selectGeneration(series.key),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          series.key,
                          style: TextStyle(
                            fontSize: 13,  // Reduced font size
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected 
                                ? Theme.of(context).colorScheme.onPrimaryContainer
                                : Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                          maxLines: 1,  // Prevent text wrapping
                          overflow: TextOverflow.ellipsis,  // Handle overflow with ellipsis
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progress,
                            backgroundColor: isSelected 
                                ? Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.1)
                                : Theme.of(context).colorScheme.primary.withOpacity(0.1),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isSelected 
                                  ? Theme.of(context).colorScheme.onPrimaryContainer
                                  : Theme.of(context).colorScheme.primary,
                            ),
                            minHeight: 8,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$collected/$total',
                          style: TextStyle(
                            fontSize: 12,
                            color: isSelected 
                                ? Theme.of(context).colorScheme.onPrimaryContainer
                                : Theme.of(context).textTheme.bodySmall?.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.style_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No cards found',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreatureGrid() {
    return ListView.builder(
      itemCount: (_allDexNames.length / 3).ceil(),
      itemBuilder: (context, rowIndex) {
        final startIndex = rowIndex * 3;
        final endIndex = math.min(startIndex + 3, _allDexNames.length);
        final rowItems = _allDexNames.sublist(startIndex, endIndex);
        
        return Row(
          children: rowItems.map((name) {
            return Expanded(
              child: AspectRatio(
                aspectRatio: 0.7,
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: _buildCreatureTile(name),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildLoadingGrid() {
    return _isLoading 
      ? GridView.builder(
          padding: const EdgeInsets.all(8),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 0.7,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: 12,
          itemBuilder: (context, index) => Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Card(
              elevation: 2,
            ),
          ),
        )
      : _buildCreatureGrid();
  }

  Future<void> _selectGeneration(String? genKey) async {
    if (!mounted || genKey == null || genKey == _selectedGeneration) return;
    
    setState(() => _isLoading = true);
    
    try {
      final range = _series[genKey];
      if (range != null) {
        final (start, end) = range;
        _allDexNames = await _namesService.loadGenerationNames(start, end);
        _selectedGeneration = genKey;
      }
    } catch (e) {
      print('Error loading generation: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
        toolbarHeight: 44,
        automaticallyImplyLeading: true,
      ),
      body: Stack(
        children: [
          // Add animated background
          Lottie.asset(
            'assets/animations/background.json',
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
          // Main content
          Column(
            children: [
              _buildGenerationProgress(),
              Expanded(
                child: _allDexNames.isEmpty && !_isLoading
                    ? _buildEmptyState()
                    : _buildLoadingGrid(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

