import 'dart:math' show min, max;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/tcg_card.dart';
import '../services/tcg_api_service.dart';
import '../services/storage_service.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}

class CardDetailsScreen extends StatefulWidget {
  final TcgCard card;

  const CardDetailsScreen({
    super.key,
    required this.card,
  });

  @override
  State<CardDetailsScreen> createState() => _CardDetailsScreenState();
}

class _CardDetailsScreenState extends State<CardDetailsScreen> {
  final _apiService = TcgApiService();
  bool _isLoading = true;
  Map<String, dynamic>? _additionalData;

  @override
  void initState() {
    super.initState();
    _loadAdditionalData();
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
    if (prices.isEmpty) return const SizedBox.shrink();
    
    final pricePoints = [
      {'label': '30d Avg', 'value': prices['avg30']},
      {'label': '7d Avg', 'value': prices['avg7']},
      {'label': 'Current', 'value': prices['market'] ?? prices['averageSellPrice']},
    ].where((p) => p['value'] != null).toList();

    if (pricePoints.length < 2) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Find min and max for better scaling
    final values = pricePoints.map((p) => p['value'] as num).toList();
    final minY = (values.reduce(min) * 0.9);
    final maxY = (values.reduce(max) * 1.1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Price Trend',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: (maxY - minY) / 5,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                  strokeWidth: 1,
                ),
              ),
              titlesData: FlTitlesData(
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        '€${value.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                          fontSize: 10,
                        ),
                      );
                    },
                    reservedSize: 50,
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index >= 0 && index < pricePoints.length) {
                        return Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: Text(
                            pricePoints[index]['label'] as String,
                            style: TextStyle(
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        );
                      }
                      return const Text('');
                    },
                  ),
                ),
              ),
              minY: minY,
              maxY: maxY,
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  tooltipBgColor: isDark ? Colors.grey[800]! : Colors.white,
                  getTooltipItems: (spots) {
                    return spots.map((spot) {
                      return LineTooltipItem(
                        '€${spot.y.toStringAsFixed(2)}',
                        TextStyle(
                          color: isDark ? Colors.white : Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    }).toList();
                  },
                ),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: List.generate(pricePoints.length, (index) {
                    return FlSpot(
                      index.toDouble(),
                      (pricePoints[index]['value'] as num).toDouble(),
                    );
                  }),
                  isCurved: true,
                  color: isDark ? Colors.green[300] : Colors.green[600],
                  barWidth: 3,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) {
                      return FlDotCirclePainter(
                        radius: 6,
                        color: isDark ? Colors.green[300]! : Colors.green[600]!,
                        strokeWidth: 2,
                        strokeColor: isDark ? Colors.black : Colors.white,
                      );
                    },
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    color: (isDark ? Colors.green[300] : Colors.green[600])?.withOpacity(0.2),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Update the price rows to show only available information
  List<Widget> _buildPriceInfo(Map<String, dynamic> prices) {
    final relevantPrices = {
      'Market Price': prices['market'] ?? prices['averageSellPrice'],
      'Lowest Price': prices['low'] ?? prices['lowPrice'],
      '30 Day Average': prices['avg30'] ?? prices['avg1'],
    };

    return relevantPrices.entries
        .where((e) => e.value != null)
        .map((e) => _buildPriceRow(e.key, e.value))
        .toList();
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
            ..._buildPriceInfo(prices),
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

  Widget _buildPriceRow(String label, dynamic price) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            '€${(price as num).toStringAsFixed(2)}',
            style: const TextStyle(
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: Text(widget.card.name)),
      body: SingleChildScrollView(
        child: Padding(  // Add padding here
          padding: const EdgeInsets.only(bottom: 80), // Space for FAB
          child: Column(
            children: [
              Container(
                color: isDark ? Colors.black : Colors.grey[100],
                child: Hero(
                  tag: 'card_${widget.card.id}',
                  child: Image.network(
                    widget.card.imageUrl,
                    fit: BoxFit.contain,
                    height: 400,
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
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addToCollection(context),
        icon: const Icon(Icons.add_to_photos),
        label: const Text('Add to Collection'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
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
}
