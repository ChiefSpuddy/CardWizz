import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import '../widgets/empty_collection_view.dart';
import '../l10n/app_localizations.dart';  
import '../services/storage_service.dart';
import '../services/collection_service.dart';
import '../models/tcg_card.dart';
import '../models/custom_collection.dart';
import '../widgets/collection_grid.dart';
import '../widgets/custom_collections_grid.dart';
import '../widgets/create_collection_sheet.dart';
import '../widgets/create_binder_dialog.dart';
import 'analytics_screen.dart';
import 'home_screen.dart';
import 'custom_collection_detail_screen.dart';
import '../widgets/animated_background.dart';
import '../constants/card_styles.dart';
import '../widgets/app_drawer.dart';
import '../providers/currency_provider.dart';
import '../widgets/sign_in_view.dart';
import '../providers/app_state.dart';
import '../providers/sort_provider.dart';
import '../constants/layout.dart';

class CollectionsScreen extends StatefulWidget {
  final bool _showEmptyState;
  
  const CollectionsScreen({
    super.key,
    bool showEmptyState = true,
  }) : _showEmptyState = showEmptyState;

  @override
  State<CollectionsScreen> createState() => CollectionsScreenState();
}

class CollectionsScreenState extends State<CollectionsScreen> {
  final _pageController = PageController();
  bool _showCustomCollections = false;
  late bool _pageViewReady = false;
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() => _pageViewReady = true);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() {
      _showCustomCollections = page == 1;
    });
  }

  bool get showCustomCollections => _showCustomCollections;
  set showCustomCollections(bool value) {
    setState(() {
      _showCustomCollections = value;
    });
  }

  Widget _buildToggle() {
    final localizations = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      height: 36,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () {
                if (_pageController.hasClients) {
                  _pageController.animateToPage(
                    0,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  gradient: !_showCustomCollections
                    ? LinearGradient(
                        colors: isDark ? [
                          Colors.blue[900]!,
                          Colors.blue[800]!,
                        ] : [
                          Theme.of(context).colorScheme.primary,
                          Theme.of(context).colorScheme.secondary,
                        ],
                      )
                    : null,
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.style,
                      size: 16,
                      color: !_showCustomCollections
                        ? Colors.white
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      localizations.translate('main'),
                      style: TextStyle(
                        fontSize: 13,
                        color: !_showCustomCollections
                          ? Colors.white
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: () {
                if (_pageController.hasClients) {
                  _pageController.animateToPage(
                    1,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  gradient: _showCustomCollections
                    ? LinearGradient(
                        colors: isDark ? [
                          Colors.blue[900]!,
                          Colors.blue[800]!,
                        ] : [
                          Theme.of(context).colorScheme.primary,
                          Theme.of(context).colorScheme.secondary,
                        ],
                      )
                    : null,
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.collections_bookmark,
                      size: 16,
                      color: _showCustomCollections
                        ? Colors.white
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      localizations.translate('binders'),
                      style: TextStyle(
                        fontSize: 13,
                        color: _showCustomCollections
                          ? Colors.white
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _createCollection(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const CreateCollectionSheet(),
    );
  }

  void _showSortMenu(BuildContext context) {
    final sortProvider = Provider.of<SortProvider>(context, listen: false);
    
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.only(top: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: Row(
                children: [
                  const Icon(Icons.sort),
                  const SizedBox(width: 12),
                  Text(
                    'Sort by',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            ),
            const Divider(),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var option in CollectionSortOption.values)
                      RadioListTile<CollectionSortOption>(
                        value: option,
                        groupValue: sortProvider.currentSort,
                        onChanged: (value) {
                          sortProvider.setSort(value!);
                          Navigator.pop(context);
                        },
                        title: Text(_getSortOptionLabel(option)),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getSortOptionLabel(CollectionSortOption option) {
    switch (option) {
      case CollectionSortOption.nameAZ:
        return 'Name (A-Z)';
      case CollectionSortOption.nameZA:
        return 'Name (Z-A)';
      case CollectionSortOption.valueHighLow:
        return 'Value (High to Low)';
      case CollectionSortOption.valueLowHigh:
        return 'Value (Low to High)';
      case CollectionSortOption.newest:
        return 'Date Added (Newest First)';
      case CollectionSortOption.oldest:
        return 'Date Added (Oldest First)';
      case CollectionSortOption.countHighLow:
        return 'Card Count (High to Low)';
      case CollectionSortOption.countLowHigh:
        return 'Card Count (Low to High)';
    }
  }

  Future<void> _showCreateBinderDialog(BuildContext context) async {
    final collectionId = await showDialog<String>(
      context: context,
      builder: (context) => const CreateBinderDialog(),
      useSafeArea: true,
    );

    if (collectionId != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 2),
          backgroundColor: Theme.of(context).colorScheme.secondary,
          behavior: SnackBarBehavior.floating,
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: EdgeInsets.only(
            bottom: MediaQuery.of(context).padding.bottom + 16,
            left: 16,
            right: 16,
          ),
          content: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.check_circle_outline,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Binder Created',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Add cards to get started',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
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
  }

  Widget _buildCreateBinderButton(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      height: 46,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(23),
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).colorScheme.secondary,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: FloatingActionButton.extended(
        onPressed: () => _showCreateBinderDialog(context),
        backgroundColor: Colors.transparent,
        elevation: 0,
        icon: const Icon(Icons.add, size: 20),
        label: const Text(
          'Create New Binder',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyProvider = context.watch<CurrencyProvider>();
    final isSignedIn = context.watch<AppState>().isAuthenticated;

    return Scaffold(
      key: _scaffoldKey,
      
      // Use a PreferredSize widget for AppBar to fix the extra white space issue
      appBar: isSignedIn 
        ? PreferredSize(
            // Set minimal height when no cards, normal height when there are cards
            preferredSize: const Size.fromHeight(44), // Minimum height
            child: StreamBuilder<List<TcgCard>>(
              stream: Provider.of<StorageService>(context).watchCards(),
              builder: (context, snapshot) {
                final cards = snapshot.data ?? [];
                
                // If empty, return just a minimal AppBar with drawer icon
                if (cards.isEmpty) {
                  return AppBar(
                    toolbarHeight: 44, 
                    elevation: 0,
                    backgroundColor: Theme.of(context).scaffoldBackgroundColor, // Blend with background
                    centerTitle: false, 
                    automaticallyImplyLeading: true,
                    titleSpacing: 0,
                    // Empty to avoid taking space
                    title: const SizedBox.shrink(),
                    // No actions when empty to avoid taking space
                    actions: const [],
                    // No bottom when empty to avoid extra space
                    bottom: null,
                  );
                }
                
                // Otherwise return the full AppBar with all content
                return AppBar(
                  toolbarHeight: 44,
                  elevation: 0,
                  centerTitle: false,
                  automaticallyImplyLeading: true,
                  titleSpacing: 0,
                  // Include all the regular AppBar content
                  title: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildCardCountButton(cards),
                        const SizedBox(width: 8),
                        _buildValueButton(cards, currencyProvider),
                      ],
                    ),
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.analytics_outlined),
                      onPressed: () {
                        final homeState = context.findAncestorStateOfType<HomeScreenState>();
                        if (homeState != null) {
                          homeState.setSelectedIndex(3);
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.sort),
                      onPressed: () => _showSortMenu(context),
                    ),
                  ],
                  bottom: PreferredSize(
                    preferredSize: const Size.fromHeight(52),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _buildToggle(),
                    ),
                  ),
                );
              },
            ),
          )
        : null, // No AppBar when not signed in
      
      drawer: const AppDrawer(),
      extendBody: true,
      
      body: AnimatedBackground(
        child: !isSignedIn
            ? const SignInView()
            : _buildCollectionContent(),
      ),
      
      // ...existing floating action button...
    );
  }

  // Add these helper methods to clean up the build method
  Widget _buildCardCountButton(List<TcgCard> cards) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return InkWell(
      onTap: () {
        final homeState = context.findAncestorStateOfType<HomeScreenState>();
        if (homeState != null) {
          homeState.setSelectedIndex(3);
        }
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark ? [
              Colors.grey[800]!,
              Colors.grey[700]!,
            ] : [
              Theme.of(context).colorScheme.primaryContainer,
              Theme.of(context).colorScheme.primary.withOpacity(0.7),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.style_outlined,
              size: 16,
              color: isDark 
                ? Colors.white.withOpacity(0.9)
                : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              '${cards.length}',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isDark
                  ? Colors.white.withOpacity(0.9)
                  : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildValueButton(List<TcgCard> cards, CurrencyProvider currencyProvider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final totalValue = cards.fold<double>(
      0,
      (sum, card) => sum + (card.price ?? 0),
    );
    
    return InkWell(
      onTap: () {
        final homeState = context.findAncestorStateOfType<HomeScreenState>();
        if (homeState != null) {
          homeState.setSelectedIndex(3);
        }
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark 
                ? [Colors.green[900]!, Colors.green[800]!] 
                : [Colors.green[200]!, Colors.green[400]!],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          currencyProvider.formatValue(totalValue),
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: isDark
              ? Colors.white.withOpacity(0.9)
              : Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
      ),
    );
  }

  Widget _buildCollectionContent() {
    return Stack(
      fit: StackFit.expand,
      children: [
        MediaQuery.removePadding(
          context: context,
          removeTop: true,  
          removeBottom: true,
          child: PageView(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            physics: const ClampingScrollPhysics(),
            children: [
              StreamBuilder<List<TcgCard>>(
                stream: Provider.of<StorageService>(context).watchCards(),
                builder: (context, snapshot) {
                  final cards = snapshot.data ?? [];
                  
                  if (cards.isEmpty) {
                    // Simply return the EmptyCollectionView directly with no nesting
                    // This ensures uniform alignment across all screens
                    return const EmptyCollectionView(
                      title: 'Add Cards',
                      message: 'Start building your collection',
                      buttonText: 'Browse Cards',
                      icon: Icons.add_circle_outline,
                    );
                  }
                  
                  return const CollectionGrid(key: PageStorageKey('main_collection'));
                },
              ),
              
              // Use StreamBuilder here too to conditionally show empty state for custom collections
              StreamBuilder<List<TcgCard>>(
                stream: Provider.of<StorageService>(context).watchCards(),
                builder: (context, snapshot) {
                  final cards = snapshot.data ?? [];
                  
                  if (cards.isEmpty) {
                    // Return the EmptyCollectionView with binder-specific text
                    return const EmptyCollectionView(
                      title: 'Create Binders',
                      message: 'Organize your collection into custom binders',
                      buttonText: 'Browse Cards',
                      icon: Icons.collections_bookmark_outlined,
                    );
                  }
                  
                  return const CustomCollectionsGrid(key: PageStorageKey('custom_collections'));
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ...existing methods...
}