import 'dart:math' show pi;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/tcg_card.dart';
import '../services/tcg_api_service.dart';
import '../services/ebay_api_service.dart';
import '../services/collection_service.dart';
import '../providers/currency_provider.dart';
import '../utils/hero_tags.dart';
import 'base_card_details_screen.dart';
import '../widgets/pokemon_set_icon.dart';
import '../widgets/card_back_fallback.dart';
import '../utils/bottom_toast.dart';
import '../providers/app_state.dart';
import '../services/storage_service.dart';
import '../widgets/bottom_notification.dart';

class PokemonCardDetailsScreen extends BaseCardDetailsScreen {
  const PokemonCardDetailsScreen({
    super.key,
    required super.card,
    super.heroContext = 'details',
    super.isFromBinder = false,
    super.isFromCollection = false,
  });

  @override
  State<PokemonCardDetailsScreen> createState() => _PokemonCardDetailsScreenState();
}

class _PokemonCardDetailsScreenState extends BaseCardDetailsScreenState<PokemonCardDetailsScreen> {
  final _apiService = TcgApiService();
  final _ebayService = EbayApiService();
  Map<String, dynamic>? _additionalData;
  Map<String, List<Map<String, dynamic>>>? _salesByCategory;
  bool _isAddingToCollection = false;

  @override
  void loadData() {
    _loadAdditionalData();
    _loadRecentSales();
  }

  Future<void> _loadAdditionalData() async {
    try {
      // Pokemon cards - use normal API with detailed error handling
      Map<String, dynamic> data = {};
      
      try {
        data = await _apiService.getCardDetails(widget.card.id);
        
        if (data.isEmpty) {
          print("Received empty data from API for Pokemon card ${widget.card.id}");
          // Try alternate endpoint if available
          if (widget.card.set.id.isNotEmpty && widget.card.number != null) {
            print("Trying to fetch by set and number: ${widget.card.set.id}/${widget.card.number}");
            // Search by set and number
            final searchData = await _apiService.searchCards(
              query: 'set.id:${widget.card.set.id} number:${widget.card.number}',
              pageSize: 1
            );
            
            if (searchData['data'] != null && (searchData['data'] as List).isNotEmpty) {
              data = (searchData['data'] as List).first as Map<String, dynamic>;
            }
          }
        }
      } catch (e) {
        print("Error fetching Pokemon card from API: $e");
      }
      
      if (mounted) {
        setState(() {
          _additionalData = data;
          isLoading = false;
          
          // For Pokemon cards, try to restore price data from the card itself
          if (data.isEmpty && widget.card.price != null) {
            print("Restoring price data from card object");
            final cardPrice = widget.card.price ?? 0.0;
            _additionalData = {
              'cardmarket': {
                'prices': {
                  'averageSellPrice': cardPrice,
                  'lowPrice': cardPrice * 0.9,
                  'trendPrice': cardPrice,
                  'avg1': cardPrice,
                  'avg7': cardPrice,
                  'avg30': cardPrice,
                }
              }
            };
          }
        });
      }
    } catch (e) {
      print("Error loading additional data: $e");
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _loadRecentSales() async {
    try {
      final cardName = widget.card.name;
      final setName = widget.card.setName;
      final number = widget.card.number;
      
      final sales = await _ebayService.getRecentSalesWithGraded(
        cardName,
        setName: setName,
        number: number,
        isMtg: false, // Pokemon cards
      );
        
      if (mounted) {
        setState(() => _salesByCategory = sales);
      }
    } catch (e) {
      print('Error loading recent sales: $e');
    }
  }

  Widget _buildPricingSection() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    Map<String, dynamic> prices = {};
    
    try {
      // Pokemon price handling
      print('Processing Pokemon card price data for ${widget.card.name}');
      
      // Always include the card's price data as baseline if available
      if (widget.card.price != null && widget.card.price! > 0) {
        print('Using card object price: ${widget.card.price}');
        final cardPrice = widget.card.price!;
        prices = {
          'market': cardPrice,
          'averageSellPrice': cardPrice,
          'low': cardPrice * 0.9,
          'high': cardPrice * 1.1,
          'trendPrice': cardPrice,
        };
      }
      
      // Try to get price from tcgplayer if available
      if (_additionalData?.containsKey('tcgplayer') == true && 
          _additionalData!['tcgplayer']['prices'] != null) {
        final tcgPrices = _additionalData!['tcgplayer']['prices'];
        
        // Find the first pricing object - could be 'normal', 'holofoil', etc.
        final priceKey = tcgPrices.keys.firstWhere(
          (k) => tcgPrices[k] != null && tcgPrices[k] is Map,
          orElse: () => null
        );
        
        if (priceKey != null) {
          final normalPrices = tcgPrices[priceKey];
          prices['market'] = _parsePrice(normalPrices['market']);
          prices['low'] = _parsePrice(normalPrices['low']);
          prices['high'] = _parsePrice(normalPrices['high']);
          prices['mid'] = _parsePrice(normalPrices['mid']);
          print('Using TCGPlayer prices: $prices');
        }
      }
      
      // Also check for cardmarket prices which have historical data
      if (_additionalData?.containsKey('cardmarket') == true &&
          _additionalData!['cardmarket']['prices'] != null) {
        final cmPrices = _additionalData!['cardmarket']['prices'];
        prices['averageSellPrice'] = _parsePrice(cmPrices['averageSellPrice']);
        prices['lowPrice'] = _parsePrice(cmPrices['lowPrice']);
        prices['trendPrice'] = _parsePrice(cmPrices['trendPrice']);
        prices['avg1'] = _parsePrice(cmPrices['avg1']);
        prices['avg7'] = _parsePrice(cmPrices['avg7']);
        prices['avg30'] = _parsePrice(cmPrices['avg30']);
        print('Using CardMarket prices: $prices');
      }
    } catch (e) {
      print('Error processing price data: $e');
    }

    // Early validation of price data
    if (prices.isEmpty || (prices['market'] == null && 
                          prices['averageSellPrice'] == null && 
                          prices['mid'] == null)) {
      return _buildNoPriceData(isDark);
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (prices.isNotEmpty) ...[
            // Show chart if we have historical data
            if (prices.containsKey('avg1') || prices.containsKey('avg7') || prices.containsKey('avg30')) 
              _buildPriceChart(prices)
            else
              _buildCurrentPrice(prices),  
            const SizedBox(height: 24),
          ],
          
          Row(
            children: [
              Expanded(
                child: _buildMarketplaceButton(
                  title: 'Cardmarket',
                  icon: Icons.shopping_cart,
                  color: isDark ? const Color(0xFF007D41).withOpacity(0.8) : const Color(0xFF007D41),
                  onTap: () {
                    final url = _additionalData?['cardmarket']?['url'] ?? 
                      'https://www.cardmarket.com/en/Pokemon/Products/Search?searchString=${Uri.encodeComponent(widget.card.name)}';
                    _launchUrl(url);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMarketplaceButton(
                  title: 'eBay',
                  icon: Icons.search,
                  color: isDark ? const Color(0xFF0064D2).withOpacity(0.8) : const Color(0xFF0064D2),
                  onTap: () => _launchUrl(_apiService.getEbaySearchUrl(
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

  Widget _buildPriceChart(Map<String, dynamic> prices) {
    final currencyProvider = context.watch<CurrencyProvider>();
    if (prices.isEmpty) return const SizedBox.shrink();
    
    // Collect and sort price points
    final pricePoints = [
      {'label': '30d', 'value': prices['avg30']},
      {'label': '21d', 'value': _calculateAverage(prices['avg30'], prices['avg7'])},
      {'label': '14d', 'value': prices['avg7']},
      {'label': '7d', 'value': _calculateAverage(prices['avg7'], prices['avg1'])},
      {'label': '1d', 'value': prices['avg1']},
      {'label': 'Now', 'value': prices['market'] ?? prices['averageSellPrice']},
    ].where((p) => p['value'] != null).toList();

    // Modify the price points collection to always include current price
    final currentPrice = prices['market'] ?? prices['averageSellPrice'];
    if (currentPrice != null && pricePoints.length == 1) {
      // If we only have one price point, duplicate it to show a flat line
      pricePoints.add({'label': 'Now', 'value': currentPrice});
    }

    // Show placeholder if we don't have enough data
    if (pricePoints.length < 2) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Price History',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 200,
            alignment: Alignment.center,
            child: Text(
              'Price history not available yet',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Calculate min/max with padding
    final values = pricePoints.map((p) => (p['value'] as num).toDouble()).toList();
    final minValue = values.reduce((a, b) => a < b ? a : b);
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    final range = maxValue - minValue;
    
    // Use 20% of the range for padding
    final minY = (minValue - (range * 0.2)).clamp(0.0, double.infinity);
    final maxY = maxValue + (range * 0.1);
    
    // Ensure interval is never zero
    final interval = ((maxY - minY) / 4).clamp(0.1, double.infinity);

    // Validate price data
    if (interval <= 0 || maxY <= minY) {
      return const Center(child: Text('Insufficient Price Data'));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Price History',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Highest: ${currencyProvider.formatValue(maxValue)}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.green.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Current: ${currencyProvider.formatValue(currentPrice)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 200,
          child: Padding(
            padding: const EdgeInsets.only(right: 16, top: 8),
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: interval,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    axisNameSize: 24,
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 64,
                      interval: (maxY - minY) / 2,
                      getTitlesWidget: (value, meta) {
                        final isBottom = (value - minY).abs() < 0.0001;
                        final isTop = (value - maxY).abs() < 0.0001;
                        final isMiddle = ((value - ((maxY + minY) / 2)).abs() < interval / 2);

                        if (isBottom || isMiddle || isTop) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Text(
                              currencyProvider.formatValue(value),
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? Colors.grey[400] : Colors.grey[600],
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: (pricePoints.length / 3).ceil().toDouble(),
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < pricePoints.length && index % 2 == 0) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              pricePoints[index]['label'] as String,
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? Colors.grey[400] : Colors.grey[600],
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minY: minY,
                maxY: maxY,
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchTooltipData: LineTouchTooltipData(
                    tooltipBgColor: Theme.of(context).cardColor,
                    tooltipRoundedRadius: 8,
                    tooltipMargin: 28,
                    tooltipPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    tooltipHorizontalAlignment: FLHorizontalAlignment.center,
                    getTooltipItems: (spots) {
                      return spots.map((spot) {
                        return LineTooltipItem(
                          currencyProvider.formatValue(spot.y),
                          TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontWeight: FontWeight.w500,
                          ),
                        );
                      }).toList();
                    },
                    fitInsideHorizontally: true,
                    fitInsideVertically: true,
                  ),
                  handleBuiltInTouches: true,
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: List.generate(pricePoints.length, (i) {
                      return FlSpot(
                        i.toDouble(),
                        (pricePoints[i]['value'] as num).toDouble(),
                      );
                    }),
                    isCurved: true,
                    curveSmoothness: 0.35,
                    color: Colors.green.shade600,
                    barWidth: 2.5,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 3,
                          color: Colors.white,
                          strokeWidth: 2,
                          strokeColor: Colors.green.shade600,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.green.shade600.withOpacity(0.2),
                          Colors.green.shade600.withOpacity(0.0),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentPrice(Map<String, dynamic> prices) {
    final currencyProvider = context.watch<CurrencyProvider>();
    
    final currentPrice = prices['market'] ?? prices['averageSellPrice'] ?? prices['trendPrice'];
    final lowPrice = prices['low'] ?? prices['lowPrice'];
    final highPrice = prices['high'] ?? prices['highPrice'];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Current Prices',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        if (currentPrice != null) ...[
          _buildPriceRow('Market Price', currentPrice, isHighlight: true),
        ],
        if (lowPrice != null) ...[
          const SizedBox(height: 8),
          _buildPriceRow('Low Price', lowPrice, isHighlight: false),
        ],
        if (highPrice != null) ...[
          const SizedBox(height: 8),
          _buildPriceRow('High Price', highPrice, isHighlight: false),
        ],
      ],
    );
  }

  Widget _buildPriceRow(String label, dynamic price, {bool isHighlight = false}) {
    final currencyProvider = context.watch<CurrencyProvider>();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: isHighlight
                ? Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    )
                : Theme.of(context).textTheme.bodyLarge,
          ),
          Text(
            currencyProvider.formatValue(price.toDouble()),
            style: isHighlight
                ? Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade600,
                    )
                : Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
          ),
        ],
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
                  title: 'Cardmarket',
                  icon: Icons.shopping_cart,
                  color: isDark ? const Color(0xFF007D41).withOpacity(0.8) : const Color(0xFF007D41),
                  onTap: () {
                    final url = 'https://www.cardmarket.com/en/Pokemon/Products/Search?searchString=${Uri.encodeComponent(widget.card.name)}';
                    _launchUrl(url);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMarketplaceButton(
                  title: 'eBay',
                  icon: Icons.search,
                  color: isDark ? const Color(0xFF0064D2).withOpacity(0.8) : const Color(0xFF0064D2),
                  onTap: () => _launchUrl(_apiService.getEbaySearchUrl(
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
    // Get the set info with proper defaults
    final setInfo = _additionalData?['set'] ?? {};
    final printedTotal = setInfo['printedTotal'] ?? setInfo['total'] ?? card.set.printedTotal ?? card.set.total;
    final legalities = _additionalData?['legalities'] as Map<dynamic, dynamic>? ?? {};
    final setId = card.set.id;

    // Extract additional Pokemon-specific data
    final types = _additionalData?['types'] as List<dynamic>? ?? [];
    final attacks = _additionalData?['attacks'] as List<dynamic>? ?? [];
    final abilities = _additionalData?['abilities'] as List<dynamic>? ?? [];
    final weaknesses = _additionalData?['weaknesses'] as List<dynamic>? ?? [];
    final resistances = _additionalData?['resistances'] as List<dynamic>? ?? [];
    final retreatCost = _additionalData?['retreatCost'] as int? ?? 0;
    final hp = _additionalData?['hp'] as String? ?? '';
    final flavorText = _additionalData?['flavorText'] as String? ?? '';
    final nationalPokedexNumbers = _additionalData?['nationalPokedexNumbers'] as List<dynamic>? ?? [];

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark 
            ? Colors.grey[900] 
            : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
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
                  'Pokémon Card Information',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (setId.isNotEmpty) 
                PokemonSetIcon(
                  setId: setId,
                  size: 28,
                  color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : null,
                ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Card details in rows
          _buildDetailRow(
            'Number', 
            '${ card.number ?? "?" } / ${ printedTotal != null && printedTotal > 0 ? printedTotal : '?' }' 
          ),
          const Divider(),
          _buildDetailRow('Rarity', card.rarity ?? 'Unknown'),
          const Divider(),
          _buildDetailRow('Set', card.setName ?? "Unknown Set"),
          if (setInfo['series'] != null) ...[
            const Divider(),
            _buildDetailRow(
              'Series',
              setInfo['series']
            ),
          ],
          if (setInfo['releaseDate'] != null) ...[
            const Divider(),
            _buildDetailRow(
              'Release Date', 
              _formatDate(setInfo['releaseDate']?.toString())
            ),
          ],

          // Add Pokemon-specific data
          if (_additionalData?['supertype'] != null) ...[
            const Divider(),
            _buildDetailRow('Type', _additionalData!['supertype']),
          ],

          // Add Pokedex number when available
          if (nationalPokedexNumbers.isNotEmpty) ...[
            const Divider(),
            _buildDetailRow('Pokédex #', nationalPokedexNumbers.first.toString()),
          ],

          // Add HP information
          if (hp.isNotEmpty) ...[
            const Divider(),
            _buildDetailRow('HP', hp),
          ],

          // Add Pokemon types (Fire, Water, etc)
          if (types.isNotEmpty) ...[
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Types',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                Wrap(
                  spacing: 8,
                  children: (types as List).map((type) => _buildTypeChip(type)).toList(),
                ),
              ],
            ),
          ],

          if (_additionalData?['subtypes'] != null && 
              (_additionalData!['subtypes'] as List).isNotEmpty) ...[
            const Divider(),
            _buildDetailRow(
              'Subtypes',
              (_additionalData!['subtypes'] as List).join(', ')
            ),
          ],

          // Show weaknesses section when available
          if (weaknesses.isNotEmpty) ...[
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Weaknesses',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                Wrap(
                  spacing: 8,
                  children: (weaknesses as List).map((weakness) => _buildWeaknessChip(weakness)).toList(),
                ),
              ],
            ),
          ],

          // Show resistances when available
          if (resistances.isNotEmpty) ...[
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Resistances',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                Wrap(
                  spacing: 8,
                  children: (resistances as List).map((resistance) => _buildResistanceChip(resistance)).toList(),
                ),
              ],
            ),
          ],

          // Show retreat cost when available
          if (retreatCost > 0) ...[
            const Divider(),
            _buildDetailRow('Retreat Cost', '${retreatCost} Energy'),
          ],

          // Show flavor text when available
          if (flavorText.isNotEmpty) ...[
            const Divider(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Flavor Text',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    flavorText,
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.9),
                    ),
                  ),
                ),
              ],
            ),
          ],

          if (_additionalData?['artist'] != null) ...[
            const Divider(),
            _buildDetailRow('Artist', _additionalData!['artist']),
          ],

          // Add legality information for Pokemon cards
          if (legalities.isNotEmpty) ...[
            const Divider(),
            Column(
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
                  children: legalities.entries
                      .where((e) => e.value == 'Legal')
                      .map((e) => _buildLegalityTag(e.key.toString()))
                      .toList(),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // Add new widget to display Pokemon type chips
  Widget _buildTypeChip(dynamic type) {
    final typeColor = _getTypeColor(type.toString());
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: typeColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: typeColor),
      ),
      child: Text(
        type.toString(),
        style: TextStyle(
          color: typeColor,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  // Add new widget to display weakness chips
  Widget _buildWeaknessChip(dynamic weakness) {
    final type = weakness['type'].toString();
    final value = weakness['value'].toString();
    final typeColor = _getTypeColor(type);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade400),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: typeColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '$type $value',
            style: TextStyle(
              color: Colors.red.shade700,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // Add new widget to display resistance chips
  Widget _buildResistanceChip(dynamic resistance) {
    final type = resistance['type'].toString();
    final value = resistance['value'].toString();
    final typeColor = _getTypeColor(type);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade400),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: typeColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '$type $value',
            style: TextStyle(
              color: Colors.blue.shade700,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to get color for Pokemon types
  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'fire': return Colors.orange.shade700;
      case 'water': return Colors.blue.shade600;
      case 'grass': return Colors.green.shade600;
      case 'electric': return Colors.amber.shade500;
      case 'psychic': return Colors.purple.shade400;
      case 'fighting': return Colors.brown.shade600;
      case 'darkness': case 'dark': return Colors.grey.shade800;
      case 'metal': case 'steel': return Colors.blueGrey.shade400;
      case 'dragon': return Colors.indigo.shade600;
      case 'fairy': return Colors.pink.shade300;
      case 'colorless': case 'normal': return Colors.grey.shade400;
      case 'lightning': return Colors.yellow.shade700;
      default: return Colors.grey.shade500;
    }
  }

  // Add new widget to display legality tags
  Widget _buildLegalityTag(String format) {
    // Format the format name for display
    final displayText = format
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word.isNotEmpty 
            ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}'
            : '')
        .join(' ');
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.green.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        displayText,
        style: TextStyle(
          color: Colors.green.shade800,
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
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

  Widget _buildRecentSales() {
    if (_salesByCategory == null) {
      return const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    // Count total valid sales
    int totalSales = 0;
    if (_salesByCategory!.isNotEmpty) {
      totalSales = _salesByCategory!.values
          .map((list) => list.length)
          .reduce((a, b) => a + b);
    }

    if (totalSales == 0) {
      return _buildNoSalesMessage();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSalesHeader(totalSales),
        const SizedBox(height: 16),
        
        // Ungraded Sales Section
        if (_salesByCategory!.containsKey('ungraded') && 
            _salesByCategory!['ungraded']!.isNotEmpty)
          _buildSalesCategory(
            'Recent Pokémon Sales',
            _salesByCategory!['ungraded']!,
            icon: Icons.sell_outlined,
          ),

        // Graded Sales Sections
        if (_hasGradedSales()) ...[
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(),
          ),
          _buildGradedSalesHeader(),
          const SizedBox(height: 16),
          
          // Individual grading service sections
          for (final entry in _salesByCategory!.entries)
            if (entry.key != 'ungraded' && entry.value.isNotEmpty)
              _buildSalesCategory(
                _getGradingServiceName(entry.key),
                entry.value,
                icon: _getGradingServiceIcon(entry.key),
              ),
        ],
        
        const SizedBox(height: 24),
        _buildViewMoreButton(),
      ],
    );
  }

  Widget _buildNoSalesMessage() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 48,
            color: Theme.of(context).colorScheme.secondary,
          ),
          const SizedBox(height: 16),
          Text(
            'No Recent Sales',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'No completed sales found in the last 90 days',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 24),
          _buildViewMoreButton(),
        ],
      ),
    );
  }

  Widget _buildSalesHeader(int totalSales) {
    return Row(
      children: [
        Icon(
          Icons.analytics_outlined,
          size: 20,
          color: Colors.green.shade600,
        ),
        const SizedBox(width: 8),
        Text(
          'Market Activity',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$totalSales sales',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSalesCategory(String title, List<Map<String, dynamic>> sales, {IconData? icon}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category header
        if (title != 'Recent Sales') ...[
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: Colors.green.shade600),
                const SizedBox(width: 4),
              ],
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Colors.green.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${sales.length} sales',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        
        // Sales list
        ...sales.take(3).map((sale) => _buildSaleItem(sale)),
        // Show more button if there are more sales
        if (sales.length > 3)
          TextButton(
            onPressed: () => _showAllSales(title, sales, icon),
            child: Text(
              'See ${sales.length - 3} more',
              style: TextStyle(
                color: Colors.green.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }

  void _showAllSales(String title, List<Map<String, dynamic>> sales, IconData? icon) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
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
                  if (icon != null) ...[
                    Icon(icon, size: 20, color: Colors.green.shade600),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${sales.length} sales',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.w500,
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
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: sales.length,
                itemBuilder: (context, index) => _buildSaleItem(sales[index]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getGradingServiceIcon(String service) {
    switch (service) {
      case 'PSA': return Icons.verified_outlined;
      case 'BGS': return Icons.grade_outlined;
      case 'CGC': return Icons.workspace_premium_outlined;
      case 'ACE': return Icons.military_tech_outlined;
      case 'SGC': return Icons.shield_outlined;
      default: return Icons.sell_outlined;
    }
  }

  String _getGradingServiceName(String key) {
    switch (key) {
      case 'PSA': return 'PSA Graded';
      case 'BGS': return 'Beckett Graded';
      case 'CGC': return 'CGC Graded';
      case 'ACE': return 'ACE Graded';
      case 'SGC': return 'SGC Graded';
      default: return key;
    }
  }

  bool _hasGradedSales() {
    return _salesByCategory!.entries
        .where((e) => e.key != 'ungraded')
        .any((e) => e.value.isNotEmpty);
  }

  Widget _buildGradedSalesHeader() {
    return Row(
      children: [
        Icon(
          Icons.verified_outlined,
          size: 20,
          color: Colors.green.shade600,
        ),
        const SizedBox(width: 8),
        Text(
          'Graded Listings',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildViewMoreButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _launchUrl(_apiService.getEbaySearchUrl(
          widget.card.name,
          setName: widget.card.setName,
        )),
        icon: const Icon(Icons.shopping_bag_outlined, size: 18),
        label: const Text('View More on eBay'),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          side: BorderSide(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
          ),
        ),
      ),
    );
  }

  Widget _buildSaleItem(Map<String, dynamic> sale) {
    final currencyProvider = context.watch<CurrencyProvider>();
    final price = sale['price'] as double;
    final condition = sale['condition'] as String? ?? 'Unknown';
    final title = sale['title'] as String;
    final link = sale['link'] as String;

    return InkWell(
      onTap: () => _launchUrl(link),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: Colors.green.shade600.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                currencyProvider.formatValue(price),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade600,
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
                    style: Theme.of(context).textTheme.bodyMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    condition,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 16,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  double? _parsePrice(dynamic price) {
    try {
      if (price == null) return null;
      
      if (price is num) return price.toDouble();
      
      if (price is String) {
        final cleaned = price.replaceAll(RegExp(r'[^\d.]'), '');
        if (cleaned.isEmpty) return null;
        
        try {
          final parsed = double.parse(cleaned);
          if (parsed >= 0 && parsed < 1000000) return parsed;
        } catch (e) {
          print('Error parsing price string: $cleaned');
        }
      }
      return null;
    } catch (e) {
      print('Error in _parsePrice: $e');
      return null;
    }
  }

  double? _calculateAverage(double? a, double? b) {
    if (a == null || b == null) return null;
    return (a + b) / 2;
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'Unknown';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      return dateStr.split('T')[0].split('-').reversed.join('/');
    }
  }

  Future<void> _launchUrl(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  // New method to show attacks and abilities in a modal
  void _showAttacksAndAbilities() {
    final attacks = _additionalData?['attacks'] as List<dynamic>? ?? [];
    final abilities = _additionalData?['abilities'] as List<dynamic>? ?? [];

    if (attacks.isEmpty && abilities.isEmpty) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
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
            // Title
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Attacks & Abilities',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Divider(height: 1),
            // Content
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (abilities.isNotEmpty) ...[
                    Text(
                      'Abilities',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.purple.shade700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...abilities.map((ability) => _buildAbilityCard(ability)),
                    const SizedBox(height: 24),
                  ],
                  if (attacks.isNotEmpty) ...[
                    Text(
                      'Attacks',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...attacks.map((attack) => _buildAttackCard(attack)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // New widget to display ability cards
  Widget _buildAbilityCard(Map<String, dynamic> ability) {
    final name = ability['name'] as String? ?? 'Unknown';
    final text = ability['text'] as String? ?? '';
    final type = ability['type'] as String? ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    type.isNotEmpty ? type : 'Ability',
                    style: TextStyle(
                      color: Colors.purple.shade800,
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            if (text.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(text),
            ],
          ],
        ),
      ),
    );
  }

  // New widget to display attack cards
  Widget _buildAttackCard(Map<String, dynamic> attack) {
    final name = attack['name'] as String? ?? 'Unknown';
    final text = attack['text'] as String? ?? '';
    final damage = attack['damage'] as String? ?? '';
    final cost = attack['cost'] as List<dynamic>? ?? [];

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Energy cost icons
                if (cost.isNotEmpty)
                  Wrap(
                    spacing: 4,
                    children: (cost as List).map((energy) => 
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: _getTypeColor(energy),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            energy.substring(0, 1),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      )
                    ).toList(),
                  ),
                const SizedBox(width: 8),
                Text(
                  name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (damage.isNotEmpty)
                  Text(
                    damage,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade700,
                    ),
                  ),
              ],
            ),
            if (text.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(text),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Extract additional Pokemon-specific data to decide whether to show attacks button
    final attacks = _additionalData?['attacks'] as List<dynamic>? ?? [];
    final abilities = _additionalData?['abilities'] as List<dynamic>? ?? [];
    final hasAttacksOrAbilities = attacks.isNotEmpty || abilities.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: Text(widget.card.name)),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 80),
          child: Column(
            children: [
              Container(
                color: isDark ? Colors.black : Colors.white,
                height: MediaQuery.of(context).size.width * 1.0,
                child: Stack(
                  children: [
                    // Background gradient overlay
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              isDark ? Colors.black : Colors.white,
                              isDark ? Colors.black.withOpacity(0.7) : Colors.grey[100]!,
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Card image
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Container(
                          width: MediaQuery.of(context).size.width * 0.75,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: GestureDetector(
                            onTap: flipCard,
                            child: AnimatedBuilder(
                              animation: flipController,
                              builder: (context, child) {
                                final isFrontVisible = flipController.value < 0.5;
                                
                                return Transform(
                                  transform: Matrix4.identity()
                                    ..setEntry(3, 2, 0.001)
                                    ..rotateY(flipController.value * pi),
                                  alignment: Alignment.center,
                                  child: isFrontVisible 
                                    ? // Front of card - only build when visible
                                      Hero(
                                        tag: HeroTags.cardImage(widget.card.id, context: widget.heroContext),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(16),
                                          child: CachedNetworkImage(
                                            imageUrl: widget.card.largeImageUrl ?? widget.card.imageUrl,
                                            fit: BoxFit.contain,
                                            placeholder: (context, url) => Center(
                                              child: CircularProgressIndicator(
                                                valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
                                              ),
                                            ),
                                            errorWidget: (context, url, error) => Container(
                                              color: Colors.grey[900],
                                              child: const Center(child: Icon(Icons.broken_image, color: Colors.white, size: 50)),
                                            ),
                                          ),
                                        ),
                                      )
                                    : // Back of card - apply a second transform to maintain correct orientation
                                      Transform(
                                        transform: Matrix4.identity()..rotateY(pi),
                                        alignment: Alignment.center,
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(16),
                                          child: _buildCardBack(),
                                        ),
                                      ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Card title and set icon in a row
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.card.name,
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (widget.card.set.id.isNotEmpty) 
                          PokemonSetIcon(
                            setId: widget.card.set.id,
                            size: 32,
                            color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : null,
                          ),
                      ],
                    ),
                    if (widget.card.setName != null && widget.card.setName!.isNotEmpty)
                      Text(
                        widget.card.setName!,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    const SizedBox(height: 24),
                    _buildPricingSection(),
                    const SizedBox(height: 24),
                    _buildCardInfo(),
                    
                    // Add attacks & abilities button when available
                    if (hasAttacksOrAbilities) ...[
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _showAttacksAndAbilities,
                        icon: const Icon(Icons.bolt),
                        label: const Text('View Attacks & Abilities'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber.shade600,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 48),
                        ),
                      ),
                    ],
                    
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[900] : Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: _buildRecentSales(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FutureBuilder<CollectionService>(
        future: CollectionService.getInstance(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const SizedBox.shrink();

          return StreamBuilder<List<TcgCard>>(
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
                (c) => c.id == widget.card.id
              ) ?? false;

              return buildFAB(
                icon: isInCollection ? Icons.collections_bookmark : Icons.add,
                label: isInCollection ? 'Add to Binder' : 'Add to Collection',
                onPressed: isInCollection
                  ? () => showAddToBinderDialog(context)
                  : () => addToCollection(context),
              );
            },
          );
        },
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    // Preload the card back image to prevent flicker during animation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _precacheCardBackImage();
    });
  }

  // Add a dedicated method to preload card back with error handling
  Future<void> _precacheCardBackImage() async {
    try {
      await precacheImage(const AssetImage('assets/images/cardback.png'), context);
      print('Card back image precached successfully');
    } catch (e) {
      print('Error precaching card back image: $e');
    }
  }

  // Add this helper method to build the card back with proper fallback
  Widget _buildCardBack() {
    return Image.asset(
      'assets/images/cardback.png',
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        print('Error loading card back: $error');
        // Provide a solid color fallback with Pokemon branding
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0C3A8D), // Pokemon card back blue color
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.style, color: Colors.white, size: 48),
                const SizedBox(height: 12),
                Text(
                  'Pokémon',
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

  @override
  Future<void> addToCollection(BuildContext context) async {
    try {
      // Get services
      final storageService = Provider.of<StorageService>(context, listen: false);
      final appState = Provider.of<AppState>(context, listen: false);
      
      // Save the card
      await storageService.saveCard(widget.card);
      
      // Notify app state about the change
      appState.notifyCardChange();
      
      // Use our custom notification that shows from the bottom
      BottomNotification.show(
        context: context,
        title: 'Added to Collection',
        message: widget.card.name,
        icon: Icons.check_circle,
      );
    } catch (e) {
      if (mounted) {
        BottomNotification.show(
          context: context,
          title: 'Error',
          message: 'Failed to add card: $e',
          icon: Icons.error_outline,
          isError: true,
        );
      }
    }
  }

  Future<void> _onAddToCollectionPressed() async {
    setState(() => _isAddingToCollection = true);

    try {
      final storageService = Provider.of<StorageService>(context, listen: false);
      final appState = Provider.of<AppState>(context, listen: false);
      
      await storageService.saveCard(widget.card);
      appState.notifyCardChange();
      
      if (mounted) {
        setState(() => _isAddingToCollection = false);
        
        // Use our new bottom notification
        BottomNotification.show(
          context: context,
          title: 'Added to Collection',
          message: widget.card.name,
          icon: Icons.check_circle,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isAddingToCollection = false);
        BottomNotification.show(
          context: context,
          title: 'Error',
          message: 'Failed to add card: $e',
          icon: Icons.error_outline,
          isError: true,
        );
      }
    }
  }
}