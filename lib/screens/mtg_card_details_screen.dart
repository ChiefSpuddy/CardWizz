import 'dart:math';
import '../constants/app_colors.dart';
import '../services/logging_service.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../services/tcg_api_service.dart';
import '../services/ebay_api_service.dart';
import '../services/collection_service.dart';
import '../providers/currency_provider.dart';
import '../utils/hero_tags.dart';
import 'base_card_details_screen.dart';
import '../widgets/mtg_set_icon.dart';
import '../models/tcg_card.dart';
import '../widgets/network_card_image.dart'; // Add this import
import '../widgets/zoomable_card_image.dart'; // Add this import

class MtgCardDetailsScreen extends BaseCardDetailsScreen {
  final Widget? marketActionButtons;  // Add this property

  const MtgCardDetailsScreen({
    super.key,
    required super.card,
    super.heroContext = 'details',
    super.isFromBinder = false,
    super.isFromCollection = false,
    this.marketActionButtons,  // Add this parameter
  });

  @override
  State<MtgCardDetailsScreen> createState() => _MtgCardDetailsScreenState();
}

class _MtgCardDetailsScreenState extends BaseCardDetailsScreenState<MtgCardDetailsScreen> {
  final _apiService = TcgApiService();
  // Create our own instance of EbayApiService to avoid Provider dependency
  final _ebayApiService = EbayApiService();
  Map<String, dynamic>? _additionalData;
  Map<String, dynamic>? _priceData;
  bool _isLoading = true;

  // Replace simple boolean with proper animation controller
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;
  bool get _showingCardBack => _flipAnimation.value >= 0.5;

  @override
  void initState() {
    super.initState();
    
    // Initialize flip animation controller
    _flipController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _flipAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _flipController,
        curve: Curves.easeInOut,
      ),
    );
    
    // Preload the card back image to prevent flicker during animation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _precacheCardBackImage();
    });
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  // Replace toggle method with animating method
  void _flipCard() {
    if (_flipController.isAnimating) return;
    
    if (_flipController.value == 0) {
      _flipController.forward();
    } else {
      _flipController.reverse();
    }
  }

  @override
  void loadData() {
    _loadAdditionalData();
  }

  // Add a dedicated method to preload MTG card back with error handling
  Future<void> _precacheCardBackImage() async {
    try {
      await precacheImage(const AssetImage('assets/images/mtgback.png'), context);
      LoggingService.debug('MTG card back image precached successfully');
    } catch (e) {
      LoggingService.debug('Error precaching MTG card back image: $e');
    }
  }

  // Add this helper method to build the MTG card back with proper fallback
  Widget _buildCardBack() {
    return Image.asset(
      'assets/images/mtgback.png',
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        LoggingService.debug('Error loading MTG card back: $error');
        // Provide a solid color fallback with MTG branding
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF8B4513), // Brown color for MTG card back
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.auto_awesome, color: Colors.white, size: 48),
                const SizedBox(height: 12),
                Text(
                  'Magic',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 4,
                        offset: const Offset(2, 2),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _loadAdditionalData() async {
    try {
      // For MTG cards, load data from Scryfall
      if (widget.card.id.startsWith("mtg_")) {
        // Extract the Scryfall ID
        final scryId = widget.card.id.replaceAll("mtg_", "");
        final data = await _apiService.getCardDetails("mtg_$scryId");
        
        if (mounted) {
          setState(() {
            _additionalData = data;
            _isLoading = false;
            
            // Try to extract price data
            _priceData = {
              'usd': double.tryParse(data['prices']?['usd'] ?? '0'),
              'usd_foil': double.tryParse(data['prices']?['usd_foil'] ?? '0'),
              'eur': double.tryParse(data['prices']?['eur'] ?? '0'),
              'tix': double.tryParse(data['prices']?['tix'] ?? '0'),
            };
          });
        }
      } else if (widget.card.set.id.isNotEmpty && widget.card.number != null) {
        // Try to load by set code and collector number
        try {
          final data = await _apiService.getScryfallCardBySetAndNumber(
            widget.card.set.id, 
            widget.card.number ?? ''
          );
          
          if (mounted) {
            setState(() {
              _additionalData = data;
              _isLoading = false;
              
              // Try to extract price data
              _priceData = {
                'usd': double.tryParse(data['prices']?['usd'] ?? '0'),
                'usd_foil': double.tryParse(data['prices']?['usd_foil'] ?? '0'),
                'eur': double.tryParse(data['prices']?['eur'] ?? '0'),
                'tix': double.tryParse(data['prices']?['tix'] ?? '0'),
              };
            });
          }
        } catch (e) {
          LoggingService.debug('Error loading card by set/number: $e');
          if (mounted) {
            setState(() => _isLoading = false);
          }
        }
      } else {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      LoggingService.debug('Error loading additional data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildPricingSection() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Early validation of price data
    if (_priceData == null || (_priceData!['usd'] == null && 
                              _priceData!['usd_foil'] == null && 
                              _priceData!['eur'] == null)) {
      return _buildNoPriceData(isDark);
    }

    final currencyProvider = context.watch<CurrencyProvider>();

    // Use the enhanced dark mode decoration
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: isDark 
          ? AppColors.darkModePremiumCardDecoration 
          : BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              boxShadow: AppColors.getCardShadow(elevation: 1),
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Add marketplace buttons at the top with gradient styling
          _buildMarketplaceButtons(),
          const SizedBox(height: 20),
          
          Text(
            'Current Prices',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          if (_priceData!['usd'] != null && (_priceData!['usd'] as double) > 0) ...[
            _buildPriceRow('Regular', _priceData!['usd'] as double, currencyProvider),
          ],
          
          if (_priceData!['usd_foil'] != null && (_priceData!['usd_foil'] as double) > 0) ...[
            const SizedBox(height: 8),
            _buildPriceRow('Foil', _priceData!['usd_foil'] as double, currencyProvider),
          ],
          
          if (_priceData!['eur'] != null && (_priceData!['eur'] as double) > 0) ...[
            const SizedBox(height: 8),
            _buildPriceRow('EUR', _priceData!['eur'] as double, currencyProvider, currency: '€'),
          ],
          
          if (_priceData!['tix'] != null && (_priceData!['tix'] as double) > 0) ...[
            const SizedBox(height: 8),
            _buildPriceRow('MTGO Tix', _priceData!['tix'] as double, currencyProvider, currency: ''),
          ],
          
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildMarketplaceButton(
                  title: 'TCGplayer',
                  icon: Icons.shopping_cart,
                  color: isDark ? const Color(0xFF414141).withOpacity(0.8) : const Color(0xFF414141),
                  onTap: () => _launchUrl(_additionalData?['purchase_uris']?['tcgplayer'] ?? 
                    'https://www.tcgplayer.com/search/magic/product?q=${Uri.encodeComponent(widget.card.name)}'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMarketplaceButton(
                  title: 'eBay',
                  icon: Icons.search,
                  color: isDark ? const Color(0xFF0064D2).withOpacity(0.8) : const Color(0xFF0064D2),
                  onTap: () => _launchUrl(_apiService.getEbayMtgSearchUrl(
                    widget.card.name,
                    setName: widget.card.setName,
                    number: widget.card.number,
                  )),
                ),
              ),
            ],
          ),
          
          // Add eBay recent sales section
          const SizedBox(height: 24),
          _buildEbayRecentSales(),
        ],
      ),
    );
  }

  Widget _buildEbayRecentSales() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent eBay Sales',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Image.asset(
              'assets/images/ebay_logo.png', 
              height: 24,
              errorBuilder: (context, error, stackTrace) => 
                  const SizedBox.shrink(), // Gracefully handle missing asset
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        // Use FutureBuilder to fetch and display real eBay sales data
        FutureBuilder<List<Map<String, dynamic>>>(
          future: _ebayApiService.getRecentSales(
            widget.card.name,
            setName: widget.card.setName,
            number: widget.card.number,
            isMtg: true, // This is an MTG card
          ),
          builder: (context, snapshot) {
            // Loading state
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 24.0),
                  child: CircularProgressIndicator(),
                ),
              );
            }
            
            // Error state
            if (snapshot.hasError) {
              return _buildErrorState('Error loading sales data');
            }
            
            // Empty state
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return _buildEmptyState();
            }
            
            final sales = snapshot.data!;
            final currencyProvider = context.watch<CurrencyProvider>();
            
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Display the first few sales
                ...sales.take(3).map((sale) {
                  final price = (sale['price'] as num).toDouble();
                  final title = sale['title'] as String? ?? 'Unknown item';
                  final condition = sale['condition'] as String? ?? '';
                  final link = sale['link'] as String? ?? '';
                  
                  return InkWell(
                    onTap: () {
                      if (link.isNotEmpty) {
                        _launchUrl(link);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: Theme.of(context).dividerColor.withOpacity(0.5),
                            width: 0.5,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10, 
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              currencyProvider.formatValue(price),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade800,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 14),
                                ),
                                if (condition.isNotEmpty)
                                  Text(
                                    condition,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right, size: 16),
                        ],
                      ),
                    ),
                  );
                }),
                
                // Show a "View More" button if there are more than 3 sales
                if (sales.length > 3)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: TextButton.icon(
                      onPressed: () => _showAllSales(sales),
                      icon: const Icon(Icons.list, size: 16),
                      label: Text('See ${sales.length - 3} more'),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        iconColor: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildErrorState(String message) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24.0),
      width: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: Theme.of(context).colorScheme.error.withOpacity(0.8),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => _launchUrl(_apiService.getEbayMtgSearchUrl(
              widget.card.name,
              setName: widget.card.setName,
              number: widget.card.number,
            )),
            icon: const Icon(Icons.open_in_new, size: 16),
            label: const Text('Check eBay Manually'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24.0),
      width: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 48,
            color: isDark 
                ? Colors.white.withOpacity(0.5) 
                : Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No recent sales found',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: isDark ? Colors.white.withOpacity(0.9) : null,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'We couldn\'t find any completed listings for this card',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDark 
                  ? Colors.white.withOpacity(0.7) 
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => _launchUrl(_apiService.getEbayMtgSearchUrl(
              widget.card.name,
              setName: widget.card.setName,
              number: widget.card.number,
            )),
            icon: const Icon(Icons.search),
            label: const Text('Check eBay Manually'),
            style: OutlinedButton.styleFrom(
              foregroundColor: isDark ? AppColors.darkAccentPrimary : Theme.of(context).colorScheme.primary,
              side: BorderSide(
                color: isDark 
                    ? AppColors.darkAccentPrimary.withOpacity(0.8) 
                    : Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAllSales(List<Map<String, dynamic>> sales) {
    final currencyProvider = context.read<CurrencyProvider>();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                // Handle bar
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                // Header
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.history),
                      const SizedBox(width: 8),
                      Text(
                        'Recent eBay Sales',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${sales.length} sales',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                // Sales list
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: sales.length,
                    itemBuilder: (context, index) {
                      final sale = sales[index];
                      final price = (sale['price'] as num).toDouble();
                      final title = sale['title'] as String? ?? 'Unknown item';
                      final condition = sale['condition'] as String? ?? '';
                      final link = sale['link'] as String? ?? '';
                      final date = sale['date'] != null ? 
                          _formatDate(sale['date'].toString()) : '';
                      
                      return ListTile(
                        title: Text(title),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (condition.isNotEmpty)
                              Text(condition),
                            if (date.isNotEmpty)
                              Text(
                                'Sold: $date',
                                style: const TextStyle(fontSize: 12),
                              ),
                          ],
                        ),
                        trailing: Text(
                          currencyProvider.formatValue(price),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onTap: link.isNotEmpty ? () => _launchUrl(link) : null,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
  
  // Format date for display
  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.month}/${date.day}/${date.year}';
    } catch (e) {
      return '';
    }
  }

  Widget _buildPriceRow(String label, double price, CurrencyProvider currencyProvider, {String currency = '\$'}) {
    // Replace with standard currency formatting
    final formattedPrice = currencyProvider.formatValue(price);
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          Text(
            formattedPrice, // Use the properly formatted value
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.green.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMarketplaceButton({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.4),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoPriceData(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.currency_exchange, color: Colors.grey[500], size: 20),
              const SizedBox(width: 8),
              Text(
                'Price Information',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'No price data available for this card',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildMarketplaceButton(
                  title: 'TCGplayer',
                  icon: Icons.shopping_cart,
                  color: isDark ? const Color(0xFF414141).withOpacity(0.8) : const Color(0xFF414141),
                  onTap: () => _launchUrl('https://www.tcgplayer.com/search/magic/product?q=${Uri.encodeComponent(widget.card.name)}'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMarketplaceButton(
                  title: 'eBay',
                  icon: Icons.search,
                  color: isDark ? const Color(0xFF0064D2).withOpacity(0.8) : const Color(0xFF0064D2),
                  onTap: () => _launchUrl(_apiService.getEbayMtgSearchUrl(
                    widget.card.name,
                    setName: widget.card.setName,
                  )),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCardInfo() {
    final card = widget.card;
    final rawData = _additionalData;
    
    // Extract useful details
    final setName = card.setName ?? rawData?['set_name'] ?? 'Unknown Set';
    final setCode = card.set.id;
    final artist = rawData?['artist'] ?? '';
    final rarity = rawData?['rarity'] ?? card.rarity?.toUpperCase() ?? '';
    final collectorNumber = rawData?['collector_number'] ?? card.number ?? '';
    
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Use the enhanced dark mode decoration
    return Container(
      decoration: isDark
          ? AppColors.darkModeCardDecoration
          : BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              boxShadow: AppColors.getCardShadow(elevation: 1),
            ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title section with set icon
          Row(
            children: [
              Expanded(
                child: Text(
                  'Card Information',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (setCode.isNotEmpty) 
                MtgSetIcon(
                  setCode: setCode,
                  size: 28,
                  color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : null,
                ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Card details in rows
          _buildDetailRow('Set', setName),
          const Divider(),
          
          // Fix overflow by using Flexible for wide content
          _buildDetailRow(
            'Collector Number', 
            '$collectorNumber${rawData?["set_count"] != null ? ' of ${rawData!["set_count"]}' : ''}'
          ),
          
          if (rarity.isNotEmpty) ...[
            const Divider(),
            _buildDetailRow('Rarity', rarity),
          ],
          
          // Type line
          if (rawData?['type_line'] != null) ...[
            const Divider(),
            _buildDetailRow(
              'Type', 
              rawData!['type_line'] as String? ?? '',
              allowWrap: true,  // Allow long type lines to wrap
            ),
          ],
          
          // Mana cost
          if (rawData?['mana_cost'] != null) ...[
            const Divider(),
            _buildManaRow('Mana Cost', rawData!['mana_cost'] as String? ?? ''),
          ],
          
          // Set Info
          if (rawData?['set_type'] != null) ...[
            const Divider(),
            _buildDetailRow('Set Type', rawData!['set_type'] as String? ?? ''),
          ],
          
          if (rawData?['released_at'] != null) ...[
            const Divider(),
            _buildDetailRow('Released', _formatDate(rawData!['released_at'] as String? ?? '')),
          ],
          
          if (artist.isNotEmpty) ...[
            const Divider(),
            _buildDetailRow('Artist', artist),
          ],

          // Oracle text (card text)
          if (rawData?['oracle_text'] != null) ...[
            const Divider(),
            _buildOracleText(rawData!['oracle_text'] as String? ?? ''),
          ],

          // Flavor text if available
          if (rawData?['flavor_text'] != null) ...[
            const Divider(),
            _buildFlavorText(rawData!['flavor_text'] as String? ?? ''),
          ],

          // Legality information
          if (rawData?['legalities'] != null) ...[
            const Divider(),
            _buildLegalities(rawData!['legalities'] as Map<String, dynamic>? ?? {}),
          ],
        ],
      ),
    );
  }

  // Updated to handle text overflow properly
  Widget _buildDetailRow(String label, String value, {bool allowWrap = false}) {
    if (value.isEmpty) {
      return const SizedBox.shrink();
    }
    
    // Use different layouts based on whether we allow wrapping
    if (allowWrap) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }
    
    // Default row layout for short content
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManaRow(String label, String manaString) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          _buildManaIcons(manaString),
        ],
      ),
    );
  }

  // Parse mana symbols like {W}{U}{2} and display them as icons
  Widget _buildManaIcons(String manaString) {
    // Extract symbols between curly braces
    final regex = RegExp(r'{([^{}]+)}');
    final matches = regex.allMatches(manaString);
    
    if (matches.isEmpty) {
      return Text(
        manaString,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      );
    }

    return Wrap(
      spacing: 4,
      children: matches.map((match) {
        final symbol = match.group(1) ?? '';
        return _buildManaSymbol(symbol);
      }).toList(),
    );
  }

  Widget _buildManaSymbol(String symbol) {
    // Use custom colors based on mana symbol
    Color backgroundColor;
    Color textColor = Colors.white;
    
    switch (symbol.toUpperCase()) {
      case 'W':
        backgroundColor = Colors.amber.shade100;
        textColor = Colors.black87;
        break;
      case 'U':
        backgroundColor = Colors.blue.shade700;
        break;
      case 'B':
        backgroundColor = Colors.grey.shade800;
        break;
      case 'R':
        backgroundColor = Colors.red.shade700;
        break;
      case 'G':
        backgroundColor = Colors.green.shade700;
        break;
      case 'C':
        backgroundColor = Colors.brown.shade300;
        textColor = Colors.black;
        break;
      default:
        // For colorless mana or other symbols
        backgroundColor = Colors.grey.shade400;
        textColor = Colors.black;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Enhanced container styling for dark mode
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        border: Border.all(
          color: isDark ? Colors.black : Colors.grey.shade300,
          width: 1,
        ),
        boxShadow: isDark ? [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 2,
            offset: const Offset(0, 1),
          )
        ] : null,
      ),
      child: Center(
        child: Text(
          symbol,
          style: TextStyle(
            color: textColor,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildOracleText(String text) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Card Text',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(isDark ? 0.9 : 0.7),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: isDark 
                ? Theme.of(context).colorScheme.surface.withOpacity(0.5)
                : Theme.of(context).cardColor.withOpacity(0.3),
            borderRadius: BorderRadius.circular(8),
            border: isDark ? Border.all(color: Colors.white10) : null,
          ),
          padding: const EdgeInsets.all(12),
          child: Text(
            text.replaceAll("\n", "\n\n"), // Add extra spacing between paragraphs
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isDark ? Theme.of(context).colorScheme.onSurface : null,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFlavorText(String text) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Flavor Text',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor.withOpacity(0.3),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.all(12),
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLegalities(Map<String, dynamic> legalities) {
    // Filter to just the legal formats
    final legalFormats = legalities.entries
        .where((e) => e.value == 'legal')
        .map((e) => _formatName(e.key))
        .toList();

    if (legalFormats.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Legal In',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: legalFormats.map((format) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                format,
                style: TextStyle(
                  color: Colors.blue.shade800,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
  
  // Add the missing method to display related links
  Widget _buildRelatedLink(String title, IconData icon, String url) {
    if (url.isEmpty) return const SizedBox.shrink();
    
    return InkWell(
      onTap: () => _launchUrl(url),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const Spacer(),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  // Format MTG format names for display
  String _formatName(String format) {
    switch (format) {
      case 'standard': return 'Standard';
      case 'future': return 'Future';
      case 'historic': return 'Historic';
      case 'gladiator': return 'Gladiator';
      case 'pioneer': return 'Pioneer';
      case 'explorer': return 'Explorer';
      case 'modern': return 'Modern';
      case 'legacy': return 'Legacy';
      case 'pauper': return 'Pauper';
      case 'vintage': return 'Vintage';
      case 'penny': return 'Penny Dreadful';
      case 'commander': return 'Commander';
      case 'brawl': return 'Brawl';
      case 'historicbrawl': return 'Historic Brawl';
      case 'alchemy': return 'Alchemy';
      case 'paupercommander': return 'Pauper Commander';
      case 'duel': return 'Duel Commander';
      case 'oldschool': return 'Old School';
      case 'premodern': return 'Premodern';
      default: return format.substring(0, 1).toUpperCase() + format.substring(1);
    }
  }

  Future<void> _launchUrl(String url) async {
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (e) {
      LoggingService.debug('Could not launch URL: $e');
    }
  }

  // Add the same marketplace buttons method 
  Widget _buildMarketplaceButtons() {
    return Row(
      children: [
        Expanded(
          child: _buildGradientMarketButton(
            'Cardmarket',
            [const Color(0xFF1E88E5), const Color(0xFF1565C0)],  // Blue gradient
            Icons.shopping_cart_outlined,
            () => _openCardmarket(widget.card),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildGradientMarketButton(
            'eBay',
            [const Color(0xFFE53935), const Color(0xFFC62828)],  // Red gradient
            Icons.gavel_outlined,
            () => _openEbay(widget.card),
          ),
        ),
      ],
    );
  }

  // Method for styled gradient buttons
  Widget _buildGradientMarketButton(
    String text, 
    List<Color> gradientColors, 
    IconData icon, 
    VoidCallback onPressed
  ) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: gradientColors.last.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 18),
                const SizedBox(width: 6),
                Text(
                  text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper methods for opening marketplace links (adjusted for MTG)
  Future<void> _openCardmarket(TcgCard card) async {
    final query = Uri.encodeComponent(card.name);
    final url = 'https://www.cardmarket.com/en/Magic/Products/Singles?searchString=$query';
    await _launchUrl(url);
  }

  Future<void> _openEbay(TcgCard card) async {
    final query = Uri.encodeComponent('${card.name} mtg card');
    final url = 'https://www.ebay.com/sch/i.html?_nkw=$query';
    await _launchUrl(url);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Calculate proper card dimensions for display
    final screenSize = MediaQuery.of(context).size;
    final cardWidth = screenSize.width * 0.7;
    final cardHeight = cardWidth * 1.4; // Standard MTG card aspect ratio
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.card.name,
          style: TextStyle(
            color: isDark ? AppColors.textDarkPrimary : null,
          ),
        ),
        backgroundColor: isDark ? AppColors.darkBackground : Colors.transparent,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Card display area with flip animation
            Hero(
              tag: 'card_${widget.card.id}_${widget.heroContext}',
              child: Container(
                color: isDark ? AppColors.darkBackground : Colors.grey[100],
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: GestureDetector(
                  onTap: _flipCard,
                  child: AnimatedBuilder(
                    animation: _flipAnimation,
                    builder: (context, child) {
                      final value = _flipAnimation.value;
                      final angle = value * pi;
                      
                      return Container(
                        height: cardHeight,
                        width: cardWidth,
                        child: Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.identity()
                            ..setEntry(3, 2, 0.001) // Add perspective
                            ..rotateY(angle),
                          child: value >= 0.5
                            ? Transform(
                                alignment: Alignment.center,
                                transform: Matrix4.identity()..rotateY(pi),
                                child: Image.asset(
                                  'assets/images/mtgback.png',
                                  height: cardHeight,
                                  width: cardWidth,
                                  fit: BoxFit.contain,
                                ),
                              )
                            : ZoomableCardImage(
                                imageUrl: widget.card.largeImageUrl ?? widget.card.imageUrl,
                                height: cardHeight,
                                width: cardWidth,
                                onTap: _flipCard,
                              ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            
            // Card Info section
            Padding(
              padding: const EdgeInsets.all(16),
              child: _buildCardInfo(),
            ),
            
            // Pricing section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildPricingSection(),
            ),
            
            // Add the market action buttons if provided
            if (widget.marketActionButtons != null)
              widget.marketActionButtons!,
            
            const SizedBox(height: 24),
          ],
        ),
      ),
      floatingActionButton: FutureBuilder<CollectionService>(
        future: CollectionService.getInstance(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const SizedBox.shrink();

          return StreamBuilder<List<dynamic>>(
            stream: storage.watchCards(), // Use the storage property from the base class
            builder: (context, cardsSnapshot) {
              // If we're viewing from collection or binder, show "Add to Binder"
              if (widget.isFromCollection || widget.isFromBinder) {
                return buildFAB(
                  icon: Icons.collections_bookmark,
                  label: 'Add to Binder',
                  onPressed: () => showAddToBinderDialog(context),
                );
              }

              // Otherwise check if card is in collection
              final isInCollection = cardsSnapshot.data?.any(
                (c) => c is TcgCard && c.id == widget.card.id
              ) ?? false;

              return buildFAB(
                icon: isInCollection ? Icons.collections_bookmark : Icons.add,
                label: isInCollection ? 'Add to Binder' : 'Add to Collection',
                onPressed: () {
                  if (isInCollection) {
                    showAddToBinderDialog(context);
                  } else {
                    addToCollection(context);
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}
