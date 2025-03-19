import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../models/tcg_card.dart';
import '../services/ebay_api_service.dart';
import '../providers/app_state.dart';
import '../services/logging_service.dart';
import '../services/purchase_service.dart';
import '../utils/premium_features_helper.dart';

class MarketScanner extends StatefulWidget {
  final List<TcgCard> cards;
  final Function(TcgCard) onCardTap;

  const MarketScanner({
    Key? key,
    required this.cards,
    required this.onCardTap,
  }) : super(key: key);

  @override
  State<MarketScanner> createState() => _MarketScannerState();
}

class _MarketScannerState extends State<MarketScanner> {
  bool _isLoading = true;
  bool _isExpanded = false;
  Map<String, dynamic>? _opportunities;
  
  // Add a flag to track if the scan has been started
  bool _scanStarted = false;

  @override
  void initState() {
    super.initState();
    // Wait for widget to be fully built before scanning
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startScan();
    });
  }

  @override
  void didUpdateWidget(MarketScanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // If cards list changed and scan hasn't started yet or user has new cards
    if (!_scanStarted || widget.cards.length != oldWidget.cards.length) {
      _startScan();
    }
  }

  Future<void> _startScan() async {
    if (widget.cards.isEmpty || !mounted) {
      // Handle empty state
      setState(() {
        _isLoading = false;
        _scanStarted = true; // Mark as started even if empty
        _opportunities = {
          'undervalued': [],
          'overvalued': []
        };
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _scanStarted = true;
    });

    try {
      // Only use the first 20 cards to avoid overloading the API
      final cardsToScan = widget.cards.length > 20 
          ? widget.cards.take(20).toList() 
          : widget.cards;
          
      LoggingService.debug('Market Scanner: Starting scan with ${cardsToScan.length} cards');
      
      // Get authenticated state to avoid scanning if not logged in
      final appState = Provider.of<AppState>(context, listen: false);
      if (!appState.isAuthenticated) {
        setState(() {
          _isLoading = false;
          _opportunities = {
            'undervalued': [],
            'overvalued': []
          };
        });
        return;
      }

      final ebayService = Provider.of<EbayApiService>(context, listen: false);
      final results = await ebayService.getMarketOpportunities(cardsToScan);
      
      // Ensure component is still mounted before updating state
      if (mounted) {
        setState(() {
          _isLoading = false;
          _opportunities = results;
        });
        
        // Log the results
        final undervalued = results['undervalued'] as List;
        final overvalued = results['overvalued'] as List;
        LoggingService.debug('Market Scanner: Found ${undervalued.length} undervalued and ${overvalued.length} overvalued cards');
      }
    } catch (e) {
      LoggingService.debug('Market Scanner: Error scanning market: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _opportunities = {
            'undervalued': [],
            'overvalued': []
          };
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final purchaseService = Provider.of<PurchaseService>(context);
    final isPremium = purchaseService.isPremium;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          // Content with premium overlay if needed
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                title: Text(
                  'Market Scanner',
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  'Find opportunities in your collection',
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
                      child: Column(
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Scanning market prices...'),
                        ],
                      ),
                    ),
                  )
                else if (widget.cards.isEmpty)
                  _buildEmptyState()
                else if (_opportunities != null) ...[
                  _buildOpportunitySection('Undervalued Cards', _opportunities!['undervalued'], colorScheme.primary),
                  _buildOpportunitySection('Overvalued Cards', _opportunities!['overvalued'], Colors.orange),
                ],
              ],
            ],
          ),
          
          // Premium overlay if not premium
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
            Icons.search_off,
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
            'Add cards to your collection to find market opportunities',
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

  Widget _buildOpportunitySection(String title, List<dynamic> cards, Color color) {
    if (cards.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            const Text('No opportunities found'),
            const SizedBox(height: 16),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 16,
            ),
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cards.length,
          itemBuilder: (context, index) {
            final opportunity = cards[index];
            final card = opportunity['card'] as TcgCard;
            final market = opportunity['market'] as double?;
            final difference = opportunity['difference'] as double?;
            final percentDiff = opportunity['percentDiff'] as double?;
            
            return ListTile(
              leading: card.imageUrl != null
                  ? Image.network(
                      card.imageUrl!,
                      width: 40,
                      height: 56,
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          width: 40,
                          height: 56,
                          color: Colors.grey[300],
                          child: const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        );
                      },
                    )
                  : Container(
                      width: 40,
                      height: 56,
                      color: Colors.grey[300],
                      child: const Icon(Icons.image_not_supported),
                    ),
              title: Text(
                card.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Your price: \$${card.price?.toStringAsFixed(2) ?? 'N/A'}'),
                  Text('Market price: \$${market?.toStringAsFixed(2) ?? 'N/A'}'),
                ],
              ),
              trailing: difference != null && percentDiff != null
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${difference > 0 ? '+' : ''}${difference.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: difference > 0 ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${percentDiff > 0 ? '+' : ''}${(percentDiff * 100).toStringAsFixed(1)}%',
                          style: TextStyle(
                            color: percentDiff > 0 ? Colors.green : Colors.red,
                          ),
                        ),
                      ],
                    )
                  : null,
              onTap: () => widget.onCardTap(card),
            );
          },
        ),
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
              'Unlock market scanning to find opportunities',
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
