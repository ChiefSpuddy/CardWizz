import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import 'package:provider/provider.dart';
import '../models/tcg_card.dart';
import 'package:cached_network_image/cached_network_image.dart'; // Use this directly
import '../utils/notification_manager.dart'; // Add this import for NotificationManager

class AddToCollectionScreen extends StatefulWidget {
  final TcgCard card;

  const AddToCollectionScreen({super.key, required this.card});

  @override
  State<AddToCollectionScreen> createState() => _AddToCollectionScreenState();
}

class _AddToCollectionScreenState extends State<AddToCollectionScreen> {
  bool _isLoading = false;

  Future<void> _addToCollection() async {
    setState(() => _isLoading = true);
    
    try {
      final storage = context.read<StorageService>();
      await storage.addCard(widget.card);
      
      if (mounted) {
        // REPLACE with NotificationManager
        NotificationManager.success(
          context,
          message: 'Card added to collection'
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        // REPLACE with NotificationManager
        NotificationManager.error(
          context,
          message: e.toString()
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add to Collection'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: 0.7,
              child: CachedNetworkImage(
                imageUrl: widget.card.imageUrl ?? '',
                fit: BoxFit.contain,
                placeholder: (context, url) => Container(
                  color: Colors.grey[800],
                  child: const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[800],
                  child: const Center(
                    child: Icon(Icons.broken_image, color: Colors.white60),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.card.name,
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '${widget.card.setName} - ${widget.card.number}/${widget.card.setTotal ?? "???"}',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading ? null : _addToCollection,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Add to Collection'),
            ),
          ],
        ),
      ),
    );
  }
}
