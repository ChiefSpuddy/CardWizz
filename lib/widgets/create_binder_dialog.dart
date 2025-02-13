import 'package:flutter/material.dart';
import '../services/collection_service.dart';

class CreateBinderDialog extends StatefulWidget {
  /// Shows a dialog to create a new binder.
  /// Returns the ID of the created collection as String, or null if cancelled.
  final String? cardToAdd;

  const CreateBinderDialog({
    super.key,
    this.cardToAdd,
  });

  @override
  State<CreateBinderDialog> createState() => _CreateBinderDialogState();
}

class _CreateBinderDialogState extends State<CreateBinderDialog> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  Color _selectedColor = const Color(0xFF90CAF9);

  // Expanded color palette
  final _binderColors = const [
    // Blues
    Color(0xFF90CAF9),
    Color(0xFF42A5F5),
    Color(0xFF1976D2),
    // Greens
    Color(0xFF81C784),
    Color(0xFF66BB6A),
    Color(0xFF388E3C),
    // Oranges & Yellows
    Color(0xFFFFB74D),
    Color(0xFFFFA726),
    Color(0xFFFBC02D),
    // Reds & Pinks
    Color(0xFFE57373),
    Color(0xFFF06292),
    Color(0xFFEC407A),
    // Purples
    Color(0xFFBA68C8),
    Color(0xFF9575CD),
    Color(0xFF7E57C2),
    // Others
    Color(0xFF4DB6AC),
    Color(0xFF26A69A),
    Color(0xFF78909C),
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: isDark ? Colors.grey[900] : Colors.grey[50],  // Add this
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Create New Binder',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  hintText: 'Enter binder name',
                  border: OutlineInputBorder(),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                  hintText: 'Enter description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 24),
              Text(
                'Choose Color',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              Container(
                constraints: BoxConstraints(
                  maxHeight: mediaQuery.size.height * 0.25,  // Reduced from 0.3
                ),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),  // Add this
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 6,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: _binderColors.length,
                  itemBuilder: (context, index) {
                    final color = _binderColors[index];
                    final isSelected = _selectedColor == color;
                    final isLightColor = ThemeData.estimateBrightnessForColor(color) == Brightness.light;
                    
                    return GestureDetector(
                      onTap: () => setState(() => _selectedColor = color),
                      child: Container(
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? Colors.white : Colors.transparent,
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: color.withOpacity(0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: isSelected
                            ? Icon(
                                Icons.check,
                                color: isLightColor ? Colors.black87 : Colors.white,
                                size: 20,
                              )
                            : null,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, null),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).primaryColor,
                          Theme.of(context).colorScheme.secondary,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).primaryColor.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: FilledButton(
                      onPressed: () async {
                        if (_nameController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please enter a binder name')),
                          );
                          return;
                        }

                        try {
                          final service = await CollectionService.getInstance();
                          final collectionId = await service.createCustomCollection(
                            _nameController.text.trim(),
                            _descriptionController.text.trim(),
                            color: _selectedColor,
                          );

                          // Add card if one was specified
                          if (widget.cardToAdd != null) {
                            await service.addCardToCollection(collectionId, widget.cardToAdd!);
                          }

                          if (!mounted) return;
                          Navigator.of(context).pop(collectionId);
                        } catch (e) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(e.toString())),
                          );
                        }
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                      child: const Text(
                        'Create',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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
