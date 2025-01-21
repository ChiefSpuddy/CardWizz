import 'package:flutter/material.dart';
import '../models/custom_collection.dart';
import '../services/collection_service.dart';
import '../models/tcg_card.dart';
import 'custom_collection_detail_screen.dart';

class CustomCollectionsScreen extends StatelessWidget {
  const CustomCollectionsScreen({super.key});

  Future<void> _createCollection(BuildContext context) async {
    final service = await CollectionService.getInstance();
    final formKey = GlobalKey<FormState>();
    String name = '';
    String description = '';

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Collection'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (value) => value?.isEmpty == true ? 'Required' : null,
                onSaved: (value) => name = value ?? '',
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Description'),
                onSaved: (value) => description = value ?? '',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context, false),
          ),
          TextButton(
            child: const Text('Create'),
            onPressed: () {
              if (formKey.currentState?.validate() == true) {
                formKey.currentState?.save();
                Navigator.pop(context, true);
              }
            },
          ),
        ],
      ),
    );

    if (result == true && context.mounted) {
      try {
        await service.createCustomCollection(name, description);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to create collection')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<CollectionService>(
      future: CollectionService.getInstance(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final service = snapshot.data!;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Custom Collections'),
            actions: [
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => _createCollection(context),
              ),
            ],
          ),
          body: StreamBuilder<List<CustomCollection>>(
            stream: service.getCustomCollectionsStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final collections = snapshot.data ?? [];
              if (collections.isEmpty) {
                return const Center(
                  child: Text('No custom collections yet'),
                );
              }

              return ListView.builder(
                itemCount: collections.length,
                itemBuilder: (context, index) {
                  final collection = collections[index];
                  return _CollectionCard(collection: collection);
                },
              );
            },
          ),
        );
      },
    );
  }
}

class _CollectionCard extends StatelessWidget {
  final CustomCollection collection;

  const _CollectionCard({required this.collection});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CustomCollectionDetailScreen(collection: collection),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                collection.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (collection.description.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(collection.description),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  Text('${collection.cardIds.length} cards'),
                  const Spacer(),
                  if (collection.totalValue != null)
                    Text(
                      '€${collection.totalValue!.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
