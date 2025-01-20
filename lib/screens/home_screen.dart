import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CardWizz'),
        actions: [
          IconButton(
            icon: const Icon(Icons.brightness_6),
            onPressed: () {
              context.read<AppState>().toggleTheme();
            },
          ),
        ],
      ),
      body: const Center(
        child: Text(
          'Welcome to CardWizz',
          style: TextStyle(fontSize: 24),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // We'll implement card creation later
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Add Card coming soon!')),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
