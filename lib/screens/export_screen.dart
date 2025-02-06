
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/collection_service.dart';
import '../services/premium_service.dart';
import '../widgets/premium_dialog.dart';
import '../models/tcg_card.dart';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:share_plus/share_plus.dart';

class ExportScreen extends StatefulWidget {
  const ExportScreen({super.key});

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  bool _isLoading = false;
  String? _selectedFormat;
  final _formats = ['CSV', 'eBay CSV', 'JSON'];

  Future<void> _exportCollection() async {
    if (_selectedFormat == null) return;

    final premium = context.read<PremiumService>();
    if (!premium.hasBulkImport) {
      showDialog(
        context: context,
        builder: (_) => const PremiumDialog(),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final collection = await CollectionService().getAllCards();
      final exportData = await _formatExportData(collection);
      final file = await _saveExportFile(exportData);
      
      if (!mounted) return;
      
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'My Card Collection Export',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<String> _formatExportData(List<TcgCard> cards) async {
    switch (_selectedFormat) {
      case 'CSV':
        return _formatCSV(cards);
      case 'eBay CSV':
        return _formatEbayCSV(cards);
      case 'JSON':
        return _formatJSON(cards);
      default:
        throw Exception('Unknown format');
    }
  }

  String _formatCSV(List<TcgCard> cards) {
    final buffer = StringBuffer();
    // Add headers
    buffer.writeln('Name,Set,Number,Condition,Price,Quantity');
    
    // Add card data
    for (final card in cards) {
      buffer.writeln(
        '${card.name},${card.set},${card.number},${card.condition},${card.price},${card.quantity}'
      );
    }
    
    return buffer.toString();
  }

  String _formatEbayCSV(List<TcgCard> cards) {
    final buffer = StringBuffer();
    // Add eBay template headers
    buffer.writeln('Action,Category,Title,Condition,Price,Quantity,Description');
    
    for (final card in cards) {
      final condition = _mapConditionToEbay(card.condition);
      final description = _generateEbayDescription(card);
      
      buffer.writeln(
        'Add,183454,${card.name} - ${card.set} Pokemon Card #${card.number},'
        '$condition,${card.price},${card.quantity},"$description"'
      );
    }
    
    return buffer.toString();
  }

  String _formatJSON(List<TcgCard> cards) {
    return jsonEncode(cards.map((c) => c.toJson()).toList());
  }

  String _mapConditionToEbay(String condition) {
    final conditionMap = {
      'Mint': '1000',
      'Near Mint': '2000',
      'Excellent': '3000',
      'Good': '4000',
      'Light Played': '5000',
      'Played': '6000',
      'Poor': '7000',
    };
    return conditionMap[condition] ?? '3000';
  }

  String _generateEbayDescription(TcgCard card) {
    return '''
Pokemon Trading Card Game
Card: ${card.name}
Set: ${card.set}
Number: ${card.number}
Condition: ${card.condition}

Features:
- Authentic Pokemon Trading Card
- ${card.rarity} Rarity
${card.holographic ? '- Holographic Finish' : ''}
${card.reverseHolo ? '- Reverse Holographic' : ''}

Shipping from a smoke-free environment.
Cards are carefully packaged to ensure safe delivery.
''';
  }

  Future<File> _saveExportFile(String data) async {
    final dir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final extension = _selectedFormat?.toLowerCase().replaceAll(' ', '_') ?? 'txt';
    final file = File('${dir.path}/collection_export_$timestamp.$extension');
    return file.writeAsString(data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Export Collection')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Export Format',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedFormat,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Select Format',
                      ),
                      items: _formats.map((format) {
                        return DropdownMenuItem(
                          value: format,
                          child: Text(format),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _selectedFormat = value);
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _exportCollection,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Export Collection'),
            ),
          ],
        ),
      ),
    );
  }
}