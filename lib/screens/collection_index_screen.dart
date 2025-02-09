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
import 'home_screen.dart';  // Add this import
import 'dart:math' as math;  // Add this import at the top

class CollectionIndexScreen extends StatefulWidget {
  const CollectionIndexScreen({super.key});

  @override
  State<CollectionIndexScreen> createState() => _CollectionIndexScreenState();
}

class _CollectionIndexScreenState extends State<CollectionIndexScreen> {
  final _namesService = CollectionIndexService();
  late final DexCollectionService _collectionService;
  List<String> _allNames = [];
  bool _isLoading = true;
  String? _selectedSeries;

  // Simplify series definitions
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

  Widget _buildPlaceholder(String name) {
    return Tooltip(
      message: 'Card not yet collected',
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Faded card icon background
            Positioned.fill(
              child: Icon(
                Icons.style_outlined,
                size: 48,
                color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.1),
              ),
            ),
            // Smaller icon and text overlay
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add_circle_outline,
                  size: 24,
                  color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5),
                ),
                const SizedBox(height: 4),
                Text(
                  'Add Card',
                  style: TextStyle(
                    fontSize: 10,
                    color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreatureTile(String name) {
    final searchName = _namesService.normalizeSearchQuery(name);
    final stats = _collectionService.getCreatureStats(searchName);
    final cards = stats['cards'] as List<TcgCard>? ?? [];
    final hasCards = cards.isNotEmpty;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Card(
      elevation: hasCards ? 2 : 0,
      margin: const EdgeInsets.all(2),
      color: hasCards 
        ? (isDark ? Colors.grey[900] : Colors.white)
        : (isDark ? Colors.grey[850] : Colors.grey[100]),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: hasCards 
          ? BorderSide(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
              width: 1,
            )
          : BorderSide.none,
      ),
      child: InkWell(
        onTap: hasCards 
          ? () => _showCardsDetail(cards)
          : () => _showUncollectedInfo(name),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                    child: hasCards
                      ? CachedNetworkImage(
                          imageUrl: cards.first.imageUrl,
                          fit: BoxFit.contain,
                          errorWidget: (_, __, ___) => _buildPlaceholder(name),
                        )
                      : _buildPlaceholder(name),
                  ),
                  if (!hasCards)
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.1),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                color: hasCards 
                  ? (isDark ? Colors.black26 : Colors.grey[50])
                  : Colors.transparent,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '#${_namesService.getCardNumber(name)}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: hasCards ? FontWeight.bold : FontWeight.normal,
                      color: hasCards 
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                  if (hasCards && cards.length > 1)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context).colorScheme.primary,
                            Theme.of(context).colorScheme.secondary,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${cards.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showUncollectedInfo(String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(
              Icons.style_outlined,
              color: Theme.of(context).colorScheme.primary,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text('Add $name')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'You haven\'t collected any $name cards yet.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                // Find the home screen state
                final homeState = context.findRootAncestorStateOfType<HomeScreenState>();
                if (homeState != null) {
                  // Switch to search tab
                  homeState.setSelectedIndex(2);
                  // Pass search term through state management or similar
                } else {
                  // Fallback to regular navigation if not in HomeScreen
                  Navigator.pushNamed(
                    context, 
                    '/search',
                    arguments: {'searchTerm': name},
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ).copyWith(
                backgroundColor: MaterialStateProperty.all(
                  Theme.of(context).colorScheme.primary,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.search, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Search Cards',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: TextStyle(color: Theme.of(context).colorScheme.secondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row( 
        children: [
          Icon(
            icon,
            size: 16,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
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

  Widget _buildSeriesProgress() {
    return SizedBox(  // Changed from Container to SizedBox for simpler layout
      height: 70,
      child: Center(  // Added Center widget
        child: SingleChildScrollView(  // Changed to SingleChildScrollView
          scrollDirection: Axis.horizontal,
          child: Padding(  // Added Padding for consistent spacing
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(  // Changed to Row for better centering
              mainAxisAlignment: MainAxisAlignment.center,  // Center the series tiles
              children: _series.entries.map((entry) {
                final (start, end) = entry.value;
                final total = end - start + 1;
                final collected = _collectionService.getCollectedCount(start, end);
                final isSelected = entry.key == _selectedSeries;
                
                final progress = total > 0 ? collected / total : 0.0;
                
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Material(
                    borderRadius: BorderRadius.circular(12),
                    color: isSelected 
                      ? Theme.of(context).colorScheme.primaryContainer 
                      : Theme.of(context).cardColor,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => _selectGeneration(entry.key),
                      child: SizedBox(
                        width: 100,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 6,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                entry.key,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: isSelected 
                                    ? Theme.of(context).colorScheme.onPrimaryContainer
                                    : Theme.of(context).textTheme.bodyLarge?.color,
                                ),
                              ),
                              const SizedBox(height: 4),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: progress,
                                  minHeight: 3,
                                  backgroundColor: isSelected
                                    ? Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.1)
                                    : Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    isSelected
                                      ? Theme.of(context).colorScheme.onPrimaryContainer
                                      : Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$collected/$total',
                                style: TextStyle(
                                  fontSize: 10,
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
              }).toList(),
            ),
          ),
        ),
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

  Widget _buildCollectionGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(4),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4, // Increased from 3 to 4
        childAspectRatio: 0.75,
        crossAxisSpacing: 2, // Reduced spacing
        mainAxisSpacing: 2,
      ),
      itemCount: _allNames.length,
      itemBuilder: (context, index) => _buildCreatureTile(_allNames[index]),
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
      : _buildCollectionGrid();
  }

  Future<void> _selectGeneration(String? genKey) async {
    if (!mounted || genKey == null || genKey == _selectedSeries) return;
    
    setState(() => _isLoading = true);
    
    try {
      final range = _series[genKey];
      if (range != null) {
        final (start, end) = range;
        _allNames = await _namesService.loadGenerationNames(start, end);
        _selectedSeries = genKey;
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
              _buildSeriesProgress(),
              Expanded(
                child: _allNames.isEmpty && !_isLoading
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

