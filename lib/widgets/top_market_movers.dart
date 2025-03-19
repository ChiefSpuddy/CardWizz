import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'dart:math';
import '../models/tcg_card.dart';
import '../services/ebay_api_service.dart';
import '../services/logging_service.dart';
import '../services/purchase_service.dart';
import '../utils/premium_features_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TopMarketMovers extends StatefulWidget {
  final List<TcgCard> cards;
  final Function(TcgCard) onCardTap;
  final String? userIdentifier;

  const TopMarketMovers({
    Key? key,
    required this.cards,
    required this.onCardTap,
    this.userIdentifier,
  }) : super(key: key);

  @override
  State<TopMarketMovers> createState() => _TopMarketMoversState();
}

class _TopMarketMoversState extends State<TopMarketMovers> {
  bool _isLoading = true;
  bool _isExpanded = false;
  List<Map<String, dynamic>> _marketMovers = [];
  
  // Add timestamp for cache validation
  DateTime? _lastUpdate;
  static const _cacheDuration = Duration(hours: 12);
  static const _maxMoversToShow = 5;

  @override
  void initState() {
    super.initState();
    // Delay to let UI render first
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMarketData();
    });
  }
  
  @override
  void didUpdateWidget(TopMarketMovers oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // If user ID changed or cards changed significantly, reload data
    if (widget.userIdentifier != oldWidget.userIdentifier ||
        widget.cards.length != oldWidget.cards.length) {
      _loadMarketData();
    }
  }

  Future<void> _loadMarketData() async {
    if (widget.cards.isEmpty) {
      setState(() {
        _isLoading = false;
        _marketMovers = [];
      });
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Check for cached data first using the user identifier
      final cachedData = await _loadCachedMovers();
      if (cachedData != null) {
        setState(() {
          _isLoading = false;
          _marketMovers = cachedData;
        });
        return;
      }

      // Generate market movers for current user's cards only
      final generatedMovers = await _generateMarketMovers();
      
      // Cache the results with the user identifier
      await _cacheMarketMovers(generatedMovers);
      
      if (mounted) {
        setState(() {
          _isLoading = false;
          _marketMovers = generatedMovers;
        });
      }
    } catch (e) {
      LoggingService.debug('Top Market Movers: Error loading market data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  Future<List<Map<String, dynamic>>?> _loadCachedMovers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userKey = widget.userIdentifier ?? 'default_user';
      final cacheKey = 'market_movers_$userKey';
      
      // Get the timestamp of the last update
      final lastUpdateMillis = prefs.getInt('${cacheKey}_timestamp');
      if (lastUpdateMillis == null) {
        return null;
      }
      
      final lastUpdate = DateTime.fromMillisecondsSinceEpoch(lastUpdateMillis);
      final now = DateTime.now();
      
      // If cache is too old, return null to force refresh
      if (now.difference(lastUpdate) > _cacheDuration) {
        return null;
      }
      
      // Get the cached data
      final cachedJson = prefs.getString(cacheKey);
      if (cachedJson == null) {
        return null;
      }
      
      // Return the cached data along with the timestamp
      _lastUpdate = lastUpdate;
      
      // Parse the cached data
      // For this example, we'll use a simple format, but in a real app you'd use JSON
      // return jsonDecode(cachedJson) as List<Map<String, dynamic>>;
      
      // Instead, generate fresh data for now
      return null;
    } catch (e) {
      LoggingService.debug('Top Market Movers: Error loading cached data: $e');
      return null;
    }
  }
  
  Future<void> _cacheMarketMovers(List<Map<String, dynamic>> movers) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userKey = widget.userIdentifier ?? 'default_user';
      final cacheKey = 'market_movers_$userKey';
      
      // Set the timestamp
      final now = DateTime.now();
      await prefs.setInt('${cacheKey}_timestamp', now.millisecondsSinceEpoch);
      
      // Cache the data
      // In a real app, you'd serialize this to JSON
      // await prefs.setString(cacheKey, jsonEncode(movers));
      
      // Update the timestamp in memory
      _lastUpdate = now;
    } catch (e) {
      LoggingService.debug('Top Market Movers: Error caching data: $e');
    }
  }

  Future<List<Map<String, dynamic>>> _generateMarketMovers() async {
    if (widget.cards.isEmpty) {
      return [];
    }

    // Select random cards from the user's collection to simulate market movers
    // In a real app, you'd use actual market data
    final random = Random();
    final selectedCards = <TcgCard>[];
    final allCards = widget.cards;
    
    // Ensure we have enough cards
    final numCardsToSelect = min(_maxMoversToShow, allCards.length);
    
    // Select random cards without duplicates
    final selectedIndices = <int>{};
    while (selectedCards.length < numCardsToSelect) {
      final index = random.nextInt(allCards.length);
      if (!selectedIndices.contains(index)) {
        selectedIndices.add(index);
        selectedCards.add(allCards[index]);
      }
    }
    
    // Generate random market movements for the selected cards
    return selectedCards.map((card) {
      final price = card.price ?? 10.0;
      
      // Generate a random price change (-20% to +30%)
      final changePercent = (random.nextDouble() * 0.5) - 0.2; // -20% to +30%
      final newPrice = price * (1 + changePercent);
      
      return {
        'card': card,
        'oldPrice': price,
        'newPrice': newPrice,
        'change': newPrice - price,
        'changePercent': changePercent,
      };
    }).toList()
      ..sort((a, b) => (b['changePercent'] as double).abs()
          .compareTo((a['changePercent'] as double).abs()));
  }

  @override
  Widget build(BuildContext context) {
    final purchaseService = Provider.of<PurchaseService>(context);
    final isPremium = purchaseService.isPremium;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    // Format the last update time
    String lastUpdateText = '';
    if (_lastUpdate != null) {
      final now = DateTime.now();
      final diff = now.difference(_lastUpdate!);
      
      if (diff.inMinutes < 60) {
        lastUpdateText = '${diff.inMinutes} minutes ago';
      } else if (diff.inHours < 24) {
        lastUpdateText = '${diff.inHours} hours ago';
      } else {
        lastUpdateText = '${diff.inDays} days ago';
      }
    }
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                title: Text(
                  'Top Market Movers',
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  lastUpdateText.isNotEmpty 
                      ? 'Last updated $lastUpdateText'
                      : 'Cards with recent price changes',
                  style: textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
                trailing: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : IconButton(
                        icon: Icon(_isExpanded ? Icons.expand_less : Icons.expand_more),
                        onPressed: () {
                          setState(() {
                            _isExpanded = !_isExpanded;
                          });
                        },
                      ),
              ),
              
              if (_isExpanded) ...[
                if (_isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (widget.cards.isEmpty)
                  _buildEmptyState()
                else if (_marketMovers.isEmpty)
                  _buildNoMoversState()
                else
                  _buildMarketMoversContent(),
              ],
            ],
          ),
          
          if (!isPremium && _isExpanded)
            Positioned.fill(
              child: _buildPremiumOverlay(),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(24.0),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(
            Icons.trending_flat,
            size: 48,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'No Cards to Analyze',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Add cards to your collection to track market movements',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () {
              Navigator.pushNamed(context, '/search');
            },
            icon: const Icon(Icons.add),
            label: const Text('Add Cards'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildNoMoversState() {
    return Container(
      padding: const EdgeInsets.all(24.0),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(
            Icons.analytics_outlined,
            size: 48,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'No Market Data',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'No recent price changes detected in your collection',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: _loadMarketData,
            child: const Text('Refresh'),
          ),
        ],
      ),
    );
  }

  Widget _buildMarketMoversContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Divider(),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _marketMovers.length,
          itemBuilder: (context, index) {
            final mover = _marketMovers[index];
            final card = mover['card'] as TcgCard;
            final oldPrice = mover['oldPrice'] as double;
            final newPrice = mover['newPrice'] as double;
            final change = mover['change'] as double;
            final changePercent = mover['changePercent'] as double;
            
            final isIncreasing = change > 0;
            
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              leading: card.imageUrl != null 
                  ? SizedBox(
                      width: 40,
                      child: Image.network(
                        card.imageUrl!,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
                      ),
                    )
                  : const SizedBox(
                      width: 40,
                      child: Icon(Icons.image_not_supported),
                    ),
              title: Text(
                card.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text('${(oldPrice).toStringAsFixed(2)} → ${newPrice.toStringAsFixed(2)}'),
              trailing: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isIncreasing ? Icons.trending_up : Icons.trending_down,
                        color: isIncreasing ? Colors.green : Colors.red,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${isIncreasing ? '+' : ''}${(changePercent * 100).toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isIncreasing ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${isIncreasing ? '+' : ''}${change.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                ],
              ),
              onTap: () => widget.onCardTap(card),
            );
          },
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildPremiumOverlay() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.lock,
              color: Colors.white,
              size: 48,
            ),
            const SizedBox(height: 16),
            const Text(
              'Premium Feature',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Unlock market trends to track price changes',
              style: TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                PremiumFeaturesHelper.showPremiumDialog(context);
              },
              child: const Text('Upgrade Now'),
            ),
          ],
        ),
      ),
    );
  }
}
