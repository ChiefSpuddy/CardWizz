import 'dart:math' show min, max, sin, pi;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/tcg_card.dart';
import '../services/tcg_api_service.dart';
import '../services/storage_service.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/currency_provider.dart';  // Add this import
import '../utils/hero_tags.dart';  // Add this import
import '../services/analytics_service.dart';  // Add this import
import '../services/ebay_api_service.dart';  // Add this import
import 'package:cached_network_image/cached_network_image.dart';  // Add this import if not present
import '../services/collection_service.dart';  // Add this import
import '../widgets/create_collection_sheet.dart';  // Add this import

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}

class CardDetailsScreen extends StatefulWidget {
  final TcgCard card;
  final String heroContext;  // Add this parameter
  final bool isFromBinder;  // Add this parameter
  final bool isFromCollection;  // Add this parameter

  const CardDetailsScreen({
    super.key,
    required this.card,
    this.heroContext = 'details',  // Default value
    this.isFromBinder = false,  // Add default value
    this.isFromCollection = false,  // Add default value
  });

  @override
  State<CardDetailsScreen> createState() => _CardDetailsScreenState();
}

class _CardDetailsScreenState extends State<CardDetailsScreen> with SingleTickerProviderStateMixin {
  late AnimationController _wobbleController;
  final _cardKey = GlobalKey();
  final _apiService = TcgApiService();
  final _ebayService = EbayApiService();  // Add this
  late final StorageService _storage;  // Add this field
  bool _isLoading = true;
  Map<String, dynamic>? _additionalData;
  List<Map<String, dynamic>>? _recentSales;  // Add this

  @override
  void initState() {
    super.initState();
    _storage = Provider.of<StorageService>(context, listen: false);
    _wobbleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _loadAdditionalData();
    _loadRecentSales();  // Add this
  }

  @override
  void dispose() {
    // Clear image cache when disposing
    CachedNetworkImage.evictFromCache(widget.card.imageUrl);
    _wobbleController.dispose();
    super.dispose();
  }

  void _wobbleCard() {
    _wobbleController.forward().then((_) => _wobbleController.reverse());
  }

  Future<void> _loadAdditionalData() async {
    try {
      final data = await _apiService.getCardDetails(widget.card.id);
      if (mounted) {
        setState(() {
          _additionalData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadRecentSales() async {
    try {
      final sales = await _ebayService.getRecentSales(
        widget.card.name,
        setName: widget.card.setName,
        number: widget.card.number,  // Add card number
      );
      if (mounted) {
        setState(() => _recentSales = sales.take(5).toList());
      }
    } catch (e) {
      print('Error loading recent sales: $e');
    }
  }

  Future<void> _addToCollection(BuildContext context) async {
    try {
      final service = Provider.of<StorageService>(context, listen: false);
      await service.saveCard(widget.card);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added ${widget.card.name} to collection'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to add card'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
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
  final minValue = values.reduce(min);
  final maxValue = values.reduce(max);
  final range = maxValue - minValue;
  
  // Use 20% of the range for padding instead of starting at 0
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
          padding: const EdgeInsets.only(right: 16, top: 8), // Add padding to prevent overlap
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
                  axisNameSize: 24, // Add space between title and chart
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 64, // Increased from 60 to give more space
                    interval: (maxY - minY) / 2, // Show only 3 labels
                    getTitlesWidget: (value, meta) {
                      // Calculate if this is bottom, middle, or top value
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
                    interval: max(1, (pricePoints.length / 3).ceil()).toDouble(), // Show fewer labels
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index >= 0 && index < pricePoints.length &&
                          index % 2 == 0) { // Only show every other label
                        final date = DateTime.now().subtract(
                          Duration(days: (pricePoints.length - 1 - index) * 7)
                        );
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}',
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
              minY: minY.toDouble(), // Ensure double
              maxY: maxY.toDouble(), // Ensure double
              lineTouchData: LineTouchData(
                enabled: true,
                touchTooltipData: LineTouchTooltipData(
                  tooltipBgColor: Theme.of(context).cardColor,
                  tooltipRoundedRadius: 8,
                  tooltipMargin: 28, // Increased margin to show above finger
                  tooltipPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  tooltipHorizontalAlignment: FLHorizontalAlignment.center,
                  tooltipHorizontalOffset: 0,
                  getTooltipItems: (spots) {
                    return spots.map((spot) {
                      final index = spot.x.toInt();
                      final date = DateTime.now().subtract(
                        Duration(days: (pricePoints.length - 1 - index) * 7)
                      );
                      return LineTooltipItem(
                        '${currencyProvider.formatValue(spot.y)}\n${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}',
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
                touchSpotThreshold: 20,
                getTouchLineStart: (_, __) => double.infinity,
                getTouchLineEnd: (_, __) => double.infinity,
                touchCallback: (event, response) {
                  if (event is FlTapUpEvent || event is FlPanEndEvent) {
                    setState(() {}); // Trigger rebuild to update dots
                  }
                },
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
                    checkToShowDot: (spot, barData) {
                      // Show dots at start, end, and every other point
                      return spot.x == 0 || 
                             spot.x == barData.spots.length - 1 || 
                             spot.x.toInt() % 2 == 0 ||
                             (barData.showingIndicators?.contains(spot.x.toInt()) ?? false);
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

Widget _buildPriceInfo(Map<String, dynamic> prices) {
  final currencyProvider = context.watch<CurrencyProvider>();
  
  // Extract and format price data
  final currentPrice = prices['market'] ?? prices['averageSellPrice'];
  final lowPrice = prices['low'] ?? prices['lowPrice'];
  final highPrice = prices['high'] ?? prices['highPrice'];
  final avg30 = prices['avg30'];
  final avg7 = prices['avg7'];
  final avg1 = prices['avg1'];
  
  // Calculate price changes
  double? calculateChange(double? current, double? previous) {
    if (current == null || previous == null) return null;
    return ((current - previous) / previous) * 100;
  }

  final day1Change = calculateChange(currentPrice, avg1);
  final day7Change = calculateChange(currentPrice, avg7);
  final day30Change = calculateChange(currentPrice, avg30);

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Price ranges
      _buildPriceRow(
        'Current Price',
        currentPrice,
        isHighlight: true,
      ),
      if (lowPrice != null && highPrice != null) ...[
        const Divider(height: 24),
        Row(
          children: [
            Expanded(
              child: _buildPriceDetail(
                'Low',
                lowPrice,
                subtitle: '24h',
                textColor: Colors.red.shade700,
              ),
            ),
            Expanded(
              child: _buildPriceDetail(
                'High',
                highPrice,
                subtitle: '24h',
                textColor: Colors.green.shade700,
              ),
            ),
          ],
        ),
      ],

      // Price changes
      if (day1Change != null || day7Change != null || day30Change != null) ...[
        const Divider(height: 24),
        Text(
          'Price Changes',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            if (day1Change != null)
              Expanded(
                child: _buildPriceChange('24h', day1Change),
              ),
            if (day7Change != null)
              Expanded(
                child: _buildPriceChange('7d', day7Change),
              ),
            if (day30Change != null)
              Expanded(
                child: _buildPriceChange('30d', day30Change),
              ),
          ],
        ),
      ],
    ],
  );
}

Widget _buildPriceDetail(String label, double value, {
  String? subtitle,
  Color? textColor,
}) {
  final currencyProvider = context.watch<CurrencyProvider>();
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
        ),
      ),
      const SizedBox(height: 4),
      Text(
        currencyProvider.formatValue(value),
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
      if (subtitle != null)
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
          ),
        ),
    ],
  );
}

Widget _buildPriceChange(String period, double change) {
  final isPositive = change >= 0;
  final color = isPositive ? Colors.green.shade600 : Colors.red.shade600;
  
  return Column(
    children: [
      Text(
        period,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
        ),
      ),
      const SizedBox(height: 4),
      Text(
        '${isPositive ? '+' : ''}${change.toStringAsFixed(1)}%',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    ],
  );
}

Widget _buildPricingSection() {
  if (_isLoading) {
    return const Center(child: CircularProgressIndicator());
  }

  if (_additionalData == null) {
    return const Center(child: Text('Price data unavailable'));
  }

  final isDark = Theme.of(context).brightness == Brightness.dark;
  final prices = _additionalData!['tcgplayer']?['prices']?['normal'] ?? 
                _additionalData!['cardmarket']?['prices'] ??
                {};

  // Early validation of price data
  if (prices.isEmpty || (prices['market'] == null && prices['averageSellPrice'] == null)) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Text('No price data available'),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _launchUrl(_additionalData!['cardmarket']?['url'] ?? 
                    'https://www.cardmarket.com/en/Pokemon/Products/Search?searchString=${Uri.encodeComponent(widget.card.name)}'),
                  icon: const Icon(Icons.shopping_cart),
                  label: const Text('Cardmarket'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? Colors.green[700] : Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _launchUrl(_apiService.getEbaySearchUrl(
                    widget.card.name,
                    setName: widget.card.setName,
                  )),
                  icon: const Icon(Icons.search),
                  label: const Text('eBay'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0064D2),
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
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
          _buildPriceChart(prices),
          const Divider(height: 32),
          _buildPriceInfo(prices),  // Remove spread operator
          const SizedBox(height: 24),
        ],
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _launchUrl(_additionalData!['cardmarket']?['url'] ?? 
                  'https://www.cardmarket.com/en/Pokemon/Products/Search?searchString=${Uri.encodeComponent(widget.card.name)}'),
                icon: const Icon(Icons.shopping_cart),
                label: const Text('Cardmarket'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? Colors.green[700] : Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _launchUrl(_apiService.getEbaySearchUrl(
                  widget.card.name,
                  setName: widget.card.setName,
                )),
                icon: const Icon(Icons.search),
                label: const Text('eBay'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0064D2),
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ],
    ),
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

  Future<void> _launchUrl(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  Widget _buildDetailRow(String label, String? value) {  // Make value parameter nullable
    if (value == null || value.isEmpty) return const SizedBox.shrink();  // Skip empty values
    
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

  Widget _buildCardInfo() {
    final card = widget.card;
    final setInfo = _additionalData?['set'] ?? {};
    final legalities = _additionalData?['legalities'] as Map<dynamic, dynamic>? ?? {};

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
          Text(
            'Card Information',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildDetailRow('Number', '${card.number} / ${setInfo['printedTotal'] ?? 'Unknown'}'),
          const Divider(),
          _buildDetailRow('Rarity', card.rarity ?? 'Unknown'),
          const Divider(),
          _buildDetailRow('Set', card.setName),
          if (setInfo['releaseDate'] != null) ...[
            const Divider(),
            _buildDetailRow(
              'Release Date', 
              _formatDate(setInfo['releaseDate']?.toString())
            ),
          ],
          if (setInfo['series'] != null) ...[
            const Divider(),
            _buildDetailRow('Series', setInfo['series']),
          ],
          if (legalities.isNotEmpty) ...[
            const Divider(),
            _buildDetailRow(
              'Format', 
              legalities.entries
                  .where((e) => e.value == 'Legal')
                  .map((e) => e.key.toString())
                  .join(', ')
                  .capitalize()
            ),
          ],
          if (_additionalData?['supertype'] != null) ...[
            const Divider(),
            _buildDetailRow('Type', _additionalData!['supertype']),
          ],
          if (_additionalData?['subtypes'] != null && 
              (_additionalData!['subtypes'] as List).isNotEmpty) ...[
            const Divider(),
            _buildDetailRow(
              'Subtypes',
              (_additionalData!['subtypes'] as List).join(', ')
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPriceHistory() {
    final currencyProvider = context.watch<CurrencyProvider>();
    final stats = AnalyticsService.getCardPriceStats(widget.card);
    if (stats.isEmpty) return const SizedBox.shrink();

    final pricePoints = widget.card.priceHistory;
    if (pricePoints.isEmpty) return const SizedBox.shrink();

    // Calculate price changes for different periods
    final changes = AnalyticsService.calculatePriceChanges(widget.card);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Price History',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Price change indicators
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: changes.entries.map((entry) {
                final isPositive = entry.value >= 0;
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: (isPositive ? Colors.green : Colors.red)
                        .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        entry.key,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${isPositive ? '+' : ''}${entry.value.toStringAsFixed(1)}%',
                        style: TextStyle(
                          color: isPositive ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            
            const SizedBox(height: 24),
            
            // Price statistics
            Row(
              children: [
                _buildPriceStat(
                  'Min',
                  currencyProvider.formatValue(stats['minimum']),
                ),
                _buildPriceStat(
                  'Avg',
                  currencyProvider.formatValue(stats['average']),
                ),
                _buildPriceStat(
                  'Max',
                  currencyProvider.formatValue(stats['maximum']),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Price chart
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  // ...existing chart configuration...
                  lineBarsData: [
                    LineChartBarData(
                      spots: pricePoints.asMap().entries.map((e) {
                        return FlSpot(
                          e.key.toDouble(),
                          e.value.price,
                        );
                      }).toList(),
                      isCurved: true,
                      // ...existing line configuration...
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

  Widget _buildPriceStat(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentSales() {
    final currencyProvider = context.watch<CurrencyProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    if (_recentSales == null) {
      return const SizedBox(
        height: 100,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    if (_recentSales!.isEmpty) {
      return const SizedBox(
        height: 100,
        child: Center(
          child: Text('No recent sales data available'),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Sales',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Last 30 Days',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ..._recentSales!.map((sale) => Material( // Wrap with Material
          color: Colors.transparent,
          child: InkWell( // Add InkWell
            onTap: () => _launchUrl(sale['link'] ?? ''), // Use 'link' instead of 'url'
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[850] : Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).dividerColor.withOpacity(0.1),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: GestureDetector(  // Add this wrapper
                      onTap: () {
                        if (sale['url'] != null) {
                          _launchUrl(sale['url']);
                        }
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            sale['title'],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade600.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: Colors.green.shade600.withOpacity(0.2),
                                  ),
                                ),
                                child: Text(
                                  sale['condition'] ?? 'Unknown',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.green.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              if (sale['soldDate'] != null) ...[
                                const SizedBox(width: 8),
                                Text(
                                  _formatSaleDate(sale['soldDate']),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    currencyProvider.formatValue(
                      double.parse(sale['price'].toString()),
                    ),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        )).toList(),
        const SizedBox(height: 16),
        SizedBox(
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
        ),
      ],
    );
  }

  String _formatSaleDate(String dateStr) {
    final date = DateTime.parse(dateStr);
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}';
    }
  }

  Future<void> _showAddToBinderDialog(BuildContext context) async {
    final service = await CollectionService.getInstance();
    final collections = await service.getCustomCollections();
    
    if (collections.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('No Binders'),
          content: const Text('Create a binder first to add cards to it.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                _showCreateBinderDialog(context);
              },
              child: const Text('Create Binder'),
            ),
          ],
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add to Binder',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: collections.length,
                itemBuilder: (context, index) {
                  final collection = collections[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: collection.color,
                      child: const Icon(Icons.collections_bookmark, color: Colors.white),
                    ),
                    title: Text(collection.name),
                    subtitle: Text('${collection.cardIds.length} cards'),
                    onTap: () async {
                      Navigator.pop(context);
                      await service.addCardToCollection(collection.id, widget.card.id);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Added to ${collection.name}')),
                        );
                      }
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _showCreateBinderDialog(context);
                },
                icon: const Icon(Icons.add),
                label: const Text('Create New Binder'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showCreateBinderDialog(BuildContext context) async {
    final service = await CollectionService.getInstance();
    final nameController = TextEditingController();
    Color selectedColor = Colors.blue;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Binder'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Binder Name'),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Colors.blue,
                Colors.green,
                Colors.red,
                Colors.purple,
                Colors.orange,
                Colors.teal,
              ].map((color) => InkWell(
                onTap: () => setState(() => selectedColor = color),
                child: CircleAvatar(
                  backgroundColor: color,
                  child: selectedColor == color ? const Icon(Icons.check, color: Colors.white) : null,
                ),
              )).toList(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (result == true && nameController.text.isNotEmpty && context.mounted) {
      await service.createCustomCollection(
        nameController.text,
        '',
        color: selectedColor,
      );
      // After creating, show the binder selection dialog again
      if (context.mounted) {
        _showAddToBinderDialog(context);
      }
    }

    nameController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(title: Text(widget.card.name)),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 80),
          child: Column(
            children: [
              Container(
                color: isDark ? Colors.black : Colors.grey[100],
                height: MediaQuery.of(context).size.width * 1.2, // Reduced from 1.4
                padding: const EdgeInsets.symmetric(vertical: 24), // Add padding
                child: Center( // Center the card
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.7, // Card width
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: GestureDetector(
                      onTapDown: (_) => _wobbleCard(),
                      child: AnimatedBuilder(
                        animation: _wobbleController,
                        builder: (context, child) {
                          return Transform.rotate(
                            angle: sin(_wobbleController.value * pi) * 0.02,
                            child: child,
                          );
                        },
                        child: Hero(
                          tag: HeroTags.cardImage(widget.card.id, context: widget.heroContext),
                          child: ClipRRect( // Add rounded corners
                            borderRadius: BorderRadius.circular(12),
                            child: CachedNetworkImage(
                              imageUrl: widget.card.imageUrl,
                              fit: BoxFit.contain,
                              errorWidget: (context, url, error) => Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.broken_image_outlined,
                                      size: 48,
                                      color: Theme.of(context).colorScheme.error,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Failed to load image',
                                      style: TextStyle(
                                        color: Theme.of(context).colorScheme.error,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    TextButton(
                                      onPressed: () {
                                        CachedNetworkImage.evictFromCache(widget.card.imageUrl);
                                        setState(() {}); // Trigger rebuild to retry loading
                                      },
                                      child: const Text('Retry'),
                                    ),
                                  ],
                                ),
                              ),
                              placeholder: (context, url) => const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                              fadeInDuration: const Duration(milliseconds: 300),
                              fadeOutDuration: const Duration(milliseconds: 300),
                              maxHeightDiskCache: 800,
                              memCacheHeight: 800,
                              cacheKey: '${widget.card.id}_${widget.card.imageUrl.hashCode}',
                              errorListener: (error) {
                                print('Error loading image: ${widget.card.imageUrl} - $error');
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.card.name,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildPricingSection(),
                    const SizedBox(height: 24),
                    _buildCardInfo(),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[900] : Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: _buildRecentSales(),
                    ),
                    // We'll use widget.card.priceHistory.isNotEmpty check directly here
                    if (widget.card.priceHistory.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey[900] : Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: _buildPriceHistory(),
                      ),
                    ],
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
            stream: _storage.watchCards(),
            builder: (context, cardsSnapshot) {
              // If we're viewing from collection or binder, show "Add to Binder"
              if (widget.isFromCollection || widget.isFromBinder) {
                return _buildFAB(
                  icon: Icons.collections_bookmark,
                  label: 'Add to Binder',
                  onPressed: () => _showAddToBinderDialog(context),
                );
              }

              // Otherwise check if card is in collection
              final isInCollection = cardsSnapshot.data?.any(
                (c) => c.id == widget.card.id
              ) ?? false;

              return _buildFAB(
                icon: isInCollection ? Icons.collections_bookmark : Icons.add,
                label: isInCollection ? 'Add to Binder' : 'Add to Collection',
                onPressed: isInCollection 
                  ? () => _showAddToBinderDialog(context)
                  : () => _addToCollection(context),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildFAB({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(23),
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).colorScheme.secondary,
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withOpacity(0.4),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: FloatingActionButton.extended(
        onPressed: onPressed,
        backgroundColor: Colors.transparent,
        elevation: 0,
        icon: Icon(icon, size: 20),
        label: Text(
          label,
          style: const TextStyle(fontSize: 14),
        ),
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'Unknown';
    try {
      final date = DateTime.parse(dateStr);
      // Format as DD/MM/YYYY with leading zeros
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      return dateStr.split('T')[0].split('-').reversed.join('/');  // Fallback format
    }
  }

  double? _calculateAverage(double? a, double? b) {
    if (a == null || b == null) return null;
    return (a + b) / 2;
  }
}
