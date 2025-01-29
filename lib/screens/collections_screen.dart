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
    return Container(
      height: 36,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 12), // Added more bottom margin
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
                  color: !_showCustomCollections 
                    ? Theme.of(context).colorScheme.primary
                    : Colors.transparent,
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
                        ? Theme.of(context).colorScheme.onPrimary
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      localizations.translate('main'),
                      style: TextStyle(
                        fontSize: 13,
                        color: !_showCustomCollections
                          ? Theme.of(context).colorScheme.onPrimary
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
                  color: _showCustomCollections 
                    ? Theme.of(context).colorScheme.primary
                    : Colors.transparent,
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
                        ? Theme.of(context).colorScheme.onPrimary
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      localizations.translate('binders'),
                      style: TextStyle(
                        fontSize: 13,
                        color: _showCustomCollections
                          ? Theme.of(context).colorScheme.onPrimary
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyProvider = context.watch<CurrencyProvider>();
    final isSignedIn = context.watch<AppState>().isAuthenticated;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 72,
        centerTitle: false,
        title: StreamBuilder<List<TcgCard>>(
          stream: Provider.of<StorageService>(context).watchCards(),
          builder: (context, snapshot) {
            final cards = snapshot.data ?? [];
            final totalValue = cards.fold<double>(
              0,
              (sum, card) => sum + (card.price ?? 0),
            );

            if (cards.isEmpty) return const SizedBox.shrink(); // Fix here

            return Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
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
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${cards.length}',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
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
                      Text(
                        currencyProvider.symbol,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        (totalValue * currencyProvider.rate).toStringAsFixed(2),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AnalyticsScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: () {
              // TODO: Implement sorting
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48), // Increased from 36
          child: _buildToggle(),
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
          ? FloatingActionButton.extended(
              onPressed: () => _createCollection(context),
              elevation: 4,
              backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
              foregroundColor: Theme.of(context).colorScheme.onSecondaryContainer,
              label: const Text('New Binder'),
              icon: const Icon(Icons.add),
            )
          : null,
    );
  }
}