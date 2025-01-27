import 'package:flutter/material.dart';
import '../services/collection_service.dart';

class CreateCollectionSheet extends StatefulWidget {
  const CreateCollectionSheet({super.key});

  @override
  State<CreateCollectionSheet> createState() => _CreateCollectionSheetState();
}

class _CreateCollectionSheetState extends State<CreateCollectionSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isCreating = false;

  final List<Color> _binderColors = [
    const Color(0xFF90CAF9),  // Light Blue
    const Color(0xFFF48FB1),  // Pink
    const Color(0xFFA5D6A7),  // Light Green
    const Color(0xFFFFCC80),  // Orange
    const Color(0xFFE1BEE7),  // Purple
    const Color(0xFFBCAAA4),  // Brown
  ];

  Color _selectedColor = const Color(0xFF90CAF9);

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _createCollection() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isCreating = true);

    try {
      final service = await CollectionService.getInstance();
      await service.createCustomCollection(
        _nameController.text,
        _descriptionController.text,
        color: _selectedColor,  // Pass the selected color
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Created binder "${_nameController.text}"')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to create binder')),
        );
      }
    }

    if (mounted) {
      setState(() => _isCreating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
         16, 16, 16,
        MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                'Create Binder',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    hintText: 'e.g., Favorite Cards, Wants, Trading',
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Please enter a name';
                    return null;
                  },
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                    hintText: 'What kind of cards belong in this binder?',
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Binder Color',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _binderColors.map((color) => 
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    onTap: () => setState(() => _selectedColor = color),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: color == _selectedColor
                            ? Theme.of(context).colorScheme.primary
                            : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: color == _selectedColor
                        ? Icon(
                            Icons.check,
                            color: ThemeData.estimateBrightnessForColor(color) == Brightness.light
                              ? Colors.black
                              : Colors.white,
                          )
                        : null,
                    ),
                  ),
                ),
              ).toList(),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _isCreating ? null : _createCollection,
            child: _isCreating
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Create Binder'),
          ),
        ],
      ),
    );
  }
}
