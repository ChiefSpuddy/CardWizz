import 'package:flutter/material.dart';
import '../services/dialog_service.dart';  // Update this import

class PriceUpdateDialog extends StatefulWidget {
  final int initialCurrent;
  final int initialTotal;

  // CRITICAL FIX: Remove the non-constant key from constructor
  const PriceUpdateDialog({
    Key? key,
    required this.initialCurrent,
    required this.initialTotal,
  }) : super(key: key);
  
  // Static method to update dialog progress using global instance tracking
  static final GlobalKey<_PriceUpdateDialogState> _dialogKey = GlobalKey<_PriceUpdateDialogState>();
  
  static void updateProgress(int current, int total) {
    final state = _dialogKey.currentState;
    if (state != null) {
      state._updateProgress(current, total);
    }
  }
  
  // Static getter for the key to use when creating the dialog
  static GlobalKey<_PriceUpdateDialogState> get dialogKey => _dialogKey;

  @override
  State<PriceUpdateDialog> createState() => _PriceUpdateDialogState();
}

class _PriceUpdateDialogState extends State<PriceUpdateDialog> {
  late int _current;
  late int _total;

  @override
  void initState() {
    super.initState();
    _current = widget.initialCurrent;
    _total = widget.initialTotal;
  }

  // Update progress from external calls
  void _updateProgress(int current, int total) {
    setState(() {
      _current = current;
      _total = total;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Calculate percentage (protect against division by zero)
    final progress = _total > 0 ? _current / _total : 0.0;
    final percentage = (progress * 100).round();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title and subtitle
            const Text(
              'Updating Card Prices',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Checking $_current of $_total cards',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            
            // Progress bar
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
              color: Theme.of(context).colorScheme.primary,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  '$percentage%',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            const Text(
              'Please wait, this might take a few minutes...',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
