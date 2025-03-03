import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../models/tcg_card.dart';
import '../providers/app_state.dart';

class DebugCollectionScreen extends StatefulWidget {
  const DebugCollectionScreen({Key? key}) : super(key: key);

  @override
  State<DebugCollectionScreen> createState() => _DebugCollectionScreenState();
}

class _DebugCollectionScreenState extends State<DebugCollectionScreen> {
  List<TcgCard> _cards = [];
  bool _isLoading = true;
  String? _errorMessage;
  String? _userStatus;

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  Future<void> _loadCards() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final storageService = Provider.of<StorageService>(context, listen: false);
      final authService = Provider.of<AuthService>(context, listen: false);
      
      _userStatus = 'User ID: ${storageService.currentUserId}\n'
          'Is authenticated: ${authService.isAuthenticated}\n'
          'Card count: ${storageService.cardCount}';
      
      final cards = await storageService.getCards();
      
      setState(() {
        _cards = cards;
        _isLoading = false;
      });
      
      debugPrint('Direct card load found ${cards.length} cards');
      for (final card in cards) {
        debugPrint('Card: ${card.id} - ${card.name}');
      }
      
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
      debugPrint('Error loading cards: $e');
    }
  }

  Future<void> _forceFixCards() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final storageService = Provider.of<StorageService>(context, listen: false);
      
      // Fix: Force user initialization
      final authService = Provider.of<AuthService>(context, listen: false);
      if (authService.currentUser != null) {
        debugPrint('Forcing user initialization with ID: ${authService.currentUser!.id}');
        storageService.setCurrentUser(authService.currentUser!.id);
      } else {
        debugPrint('No authenticated user found');
      }
      
      // Debug and fix cards
      await storageService.debugAndFixCards();
      
      // Reload cards
      final cards = await storageService.getCards();
      setState(() {
        _cards = cards;
        _isLoading = false;
      });
      
      debugPrint('After fix found ${cards.length} cards');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Card fix complete. Found ${cards.length} cards.'),
          backgroundColor: Colors.green,
        ),
      );
      
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
      debugPrint('Error fixing cards: $e');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _forceSessionRestore() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final appState = Provider.of<AppState>(context, listen: false);
      
      // Force session restore
      await appState.restoreLastSession();
      
      // Show progress
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Restoring last session...'),
          duration: Duration(seconds: 1),
        ),
      );
      
      // Wait a moment to ensure everything is initialized
      await Future.delayed(const Duration(seconds: 1));
      
      // Reload cards
      await _loadCards();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Session restored with ${_cards.length} cards'),
          backgroundColor: Colors.green,
        ),
      );
      
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
      debugPrint('Error restoring session: $e');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Collection'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCards,
          ),
          IconButton(
            icon: const Icon(Icons.healing),
            onPressed: _forceFixCards,
            tooltip: 'Force Fix Cards',
          ),
          IconButton(
            icon: const Icon(Icons.restore),
            onPressed: _forceSessionRestore,
            tooltip: 'Restore Last Session',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading cards',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _errorMessage!,
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    if (_userStatus != null)
                      Container(
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'User Status',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            Text(_userStatus!),
                          ],
                        ),
                      ),
                    Expanded(
                      child: _cards.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.format_list_bulleted,
                                    size: 64,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No cards found',
                                    style: Theme.of(context).textTheme.titleLarge,
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Try adding a card from the search screen',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              itemCount: _cards.length,
                              itemBuilder: (context, index) {
                                final card = _cards[index];
                                return ListTile(
                                  leading: card.imageUrl.isNotEmpty
                                      ? Image.network(
                                          card.imageUrl,
                                          width: 50,
                                          errorBuilder: (_, __, ___) =>
                                              const Icon(Icons.broken_image),
                                        )
                                      : const Icon(Icons.image),
                                  title: Text(card.name),
                                  subtitle: Text(
                                      '${card.setName} - ${card.number}\nID: ${card.id}'),
                                  isThreeLine: true,
                                );
                              },
                            ),
                    ),
                  ],
                ),
      floatingActionButton: _cards.isNotEmpty
          ? FloatingActionButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Collection Details'),
                    content: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Total Cards: ${_cards.length}'),
                          const Divider(),
                          ..._cards.map((card) => Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Text('• ${card.name} (${card.id})'),
                              )),
                        ],
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                );
              },
              child: const Icon(Icons.info_outline),
            )
          : null,
    );
  }
}
