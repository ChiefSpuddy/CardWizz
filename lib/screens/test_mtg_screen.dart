import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class TestMtgService extends StatefulWidget {
  const TestMtgService({Key? key}) : super(key: key);

  @override
  State<TestMtgService> createState() => _TestMtgServiceState();
}

class _TestMtgServiceState extends State<TestMtgService> {
  bool _isLoading = false;
  String _response = "";
  List<dynamic> _cards = [];

  Future<void> testSearch(String query) async {
    setState(() {
      _isLoading = true;
      _response = "Searching for: $query...";
    });

    try {
      // Format the query for Scryfall
      String searchQuery = query;
      if (query.startsWith('set.id:')) {
        final setCode = query.substring(7).trim();
        searchQuery = 'set:$setCode';
      }

      final url = Uri.parse('https://api.scryfall.com/cards/search?q=${Uri.encodeComponent(searchQuery)}');
      
      setState(() {
        _response += "\nURL: $url";
      });

      final response = await http.get(url);

      setState(() {
        _response += "\nStatus Code: ${response.statusCode}";
      });

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        final cards = jsonResponse['data'] as List;
        setState(() {
          _cards = cards;
          _response += "\nFound ${cards.length} cards";
          if (cards.isNotEmpty) {
            _response += "\nFirst card: ${cards[0]['name']}";
          }
        });
      } else {
        setState(() {
          _response += "\nError: ${response.body}";
        });
      }
    } catch (e) {
      setState(() {
        _response += "\nException: $e";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MTG API Test'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ElevatedButton(
              onPressed: () => testSearch('set:neo'),
              child: const Text('Test Neo Set'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => testSearch('set:one'),
              child: const Text('Test One Set'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => testSearch('set:mom'),
              child: const Text('Test Mom Set'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => testSearch('set.id:mom'),
              child: const Text('Test set.id:mom (our format)'),
            ),
            const SizedBox(height: 20),
            if (_isLoading)
              const CircularProgressIndicator()
            else
              SelectableText(
                _response,
                style: const TextStyle(fontFamily: 'monospace'),
              ),
            const SizedBox(height: 20),
            Text('Found ${_cards.length} cards:'),
            const SizedBox(height: 8),
            if (_cards.isNotEmpty)
              Column(
                children: _cards.take(5).map((card) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(card['name'] ?? 'Unknown'),
                      subtitle: Text(card['set_name'] ?? 'Unknown set'),
                      trailing: card['image_uris'] != null
                          ? Image.network(
                              card['image_uris']['small'],
                              width: 60,
                              height: 80,
                              errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
                            )
                          : const Icon(Icons.image_not_supported),
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }
}
