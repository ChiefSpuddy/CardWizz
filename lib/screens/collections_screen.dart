import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';  // Add this import
import '../services/storage_service.dart';
import '../services/collection_service.dart';  // Add this
import '../models/tcg_card.dart';
import '../models/custom_collection.dart';  // Add this
import '../widgets/collection_grid.dart';
import '../widgets/custom_collections_grid.dart';
import '../widgets/create_collection_sheet.dart';
import 'analytics_screen.dart';
import 'home_screen.dart';
import 'custom_collection_detail_screen.dart';  // Add this
import '../widgets/animated_background.dart';
import '../constants/card_styles.dart';
import '../widgets/app_drawer.dart';  // Add this import at the top
import '../providers/currency_provider.dart';
import '../widgets/sign_in_view.dart';
import '../providers/app_state.dart';
import '../providers/sort_provider.dart';  // Add this import

class CollectionsScreen extends StatefulWidget {
  const CollectionsScreen({super.key});

  @override
  State<CollectionsScreen> createState() => CollectionsScreenState(); // Remove underscore
}

class CollectionsScreenState extends State<CollectionsScreen> { // Remove underscore
  bool _showCustomCollections = false;

  // Add this getter to allow access from AppDrawer
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
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8), // Removed top margin
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _showCustomCollections = false),
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
              onTap: () => setState(() => _showCustomCollections = true),
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
        padding: const EdgeInsets.only(top: 24),  // Remove bottom padding
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
            // Wrap options in Flexible and SingleChildScrollView
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyProvider = context.watch<CurrencyProvider>();
    final isSignedIn = context.watch<AppState>().isAuthenticated;

    return Scaffold(
      appBar: AppBar(
        // Remove toolbarHeight as it's causing layout issues
        centerTitle: false,
        automaticallyImplyLeading: true,
        titleSpacing: 0, // Add this to fix spacing
        title: StreamBuilder<List<TcgCard>>(
          stream: Provider.of<StorageService>(context).watchCards(),
          builder: (context, snapshot) {
            final cards = snapshot.data ?? [];
            final totalValue = cards.fold<double>(
              0,
              (sum, card) => sum + (card.price ?? 0),
            );  // Remove the rate multiplication here

            if (cards.isEmpty) return const SizedBox.shrink();
            
            final isDark = Theme.of(context).brightness == Brightness.dark;

            return Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: () {
                      final homeState = context.findAncestorStateOfType<HomeScreenState>();
                      if (homeState != null) {
                        homeState.setSelectedIndex(3); // Assuming 3 is analytics tab index
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
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () {
                      final homeState = context.findAncestorStateOfType<HomeScreenState>();
                      if (homeState != null) {
                        homeState.setSelectedIndex(3); // Assuming 3 is analytics tab index
                      }
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isDark ? [
                            Colors.green[900]!,
                            Colors.green[800]!,
                          ] : [
                            Colors.green[200]!,
                            Colors.green[400]!,
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
                      child: Consumer<CurrencyProvider>(
                        builder: (context, currencyProvider, _) => Text(
                          currencyProvider.formatValue(totalValue),  // Just use formatValue
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: isDark
                              ? Colors.white.withOpacity(0.9)
                              : Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics_outlined),
            onPressed: () {
              final homeState = context.findAncestorStateOfType<HomeScreenState>();
              if (homeState != null) {
                homeState.setSelectedIndex(3); // Assuming 3 is analytics tab index
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: () => _showSortMenu(context),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(44), // Single value for height
          child: _buildToggle(), // Remove Column wrapper
        ),
      ),
      drawer: const AppDrawer(),
      body: AnimatedBackground(
        child: !isSignedIn
            ? const SignInView()
            : StreamBuilder<List<TcgCard>>(
                stream: Provider.of<StorageService>(context).watchCards(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Theme.of(context).colorScheme.error,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Something went wrong',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          TextButton(
                            onPressed: () {
                              // Add refresh logic
                            },
                            child: const Text('Try Again'),
                          ),
                        ],
                      ),
                    );
                  }

                  if (snapshot.data?.isEmpty ?? true) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.style_outlined,
                              size: 64,
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                            const SizedBox(height: 24),
                            Text(
                              AppLocalizations.of(context).translate('emptyCollection'),
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              AppLocalizations.of(context).translate('addFirstCard'),
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                              ),
                            ),
                            const SizedBox(height: 32),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                FilledButton.icon(
                                  onPressed: () => _createCollection(context),
                                  icon: const Icon(Icons.create_new_folder),
                                  label: const Text('New Binder'),
                                ),
                                const SizedBox(width: 16),
                                FilledButton.icon(
                                  onPressed: () {
                                    final homeState = context.findAncestorStateOfType<HomeScreenState>();
                                    homeState?.setSelectedIndex(2);
                                  },
                                  icon: const Icon(Icons.add),
                                  label: const Text('Add Card'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _showCustomCollections
                        ? const CustomCollectionsGrid()
                        : const CollectionGrid(),
                  );
                },
              ),
      ),
      floatingActionButton: isSignedIn && _showCustomCollections
          ? Container(
              height: 46, // Smaller height
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(23),
                gradient: LinearGradient(
                  colors: isDark ? [
                    Colors.blue[900]!,
                    Colors.blue[800]!,
                  ] : [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.secondary,
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: FloatingActionButton.extended(
                onPressed: () => _createCollection(context),
                backgroundColor: Colors.transparent,
                elevation: 0,
                extendedPadding: const EdgeInsets.symmetric(horizontal: 20),
                icon: const Icon(Icons.add, size: 20), // Smaller icon
                label: const Text(
                  'New Binder',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            )
          : null,
    );
  }
}