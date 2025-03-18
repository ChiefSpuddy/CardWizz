import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/purchase_service.dart';
import 'navigation_service.dart';
import '../widgets/price_update_dialog.dart';  // Add this import

class DialogService {
  // If it's meant to be a singleton or used with dependency injection:
  DialogService();
  
  static final DialogService _instance = DialogService._internal();
  static DialogService get instance => _instance;

  DialogService._internal();

  BuildContext? _dialogContext;
  bool _isDialogVisible = false;
  
  // Add streams for progress and completion notifications
  final _progressController = StreamController<double>.broadcast();
  final _completeController = StreamController<String>.broadcast();
  
  // Expose streams
  Stream<double> get progressStream => _progressController.stream;
  Stream<String> get completeStream => _completeController.stream;

  // Required to set context from main app
  void setContext(BuildContext context) {
    _dialogContext = context;
  }

  // Fix the showProgressDialog method to not use unsupported parameters
  void showProgressDialog(
    BuildContext context, {
    required String title,
    required String message,
    bool showPercentage = false,
  }) {
    _dialogContext = context;
    
    // Dismiss any existing dialogs first
    if (_isDialogVisible) {
      hideDialog();
    }

    _isDialogVisible = true;
    
    // Show price update dialog with supported parameters only
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PriceUpdateDialog(
        key: PriceUpdateDialog.dialogKey,
        initialCurrent: 0,
        initialTotal: 100,
        // Remove title and message parameters as they're not supported
      ),
    ).then((_) {
      _isDialogVisible = false;
    });
  }

  // Notify about progress updates
  void notifyProgress(double progressValue) {
    _progressController.add(progressValue);
    
    // Update dialog if it exists
    if (_isDialogVisible && progressValue >= 0 && progressValue <= 1) {
      PriceUpdateDialog.updateProgress((progressValue * 100).toInt(), 100);
    }
  }

  // Notify about completion
  void notifyComplete(String message) {
    _completeController.add(message);
    hideDialog();
  }
  
  // Fix dialog display issues
  void showPriceUpdateDialog(int current, int total) {
    final context = _dialogContext;
    if (context == null) return;

    // Don't show if already visible
    if (_isDialogVisible) {
      // Just update the existing dialog
      PriceUpdateDialog.updateProgress(current, total);
      return;
    }

    // Dismiss any existing dialogs first to prevent stacking
    if (_isDialogVisible) {
      hideDialog();
    }

    _isDialogVisible = true;
    
    // Show new dialog and ensure it's displayed by using showDialog directly
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => PriceUpdateDialog(
          key: PriceUpdateDialog.dialogKey,  // CRITICAL FIX: Use the static key getter
          initialCurrent: current,
          initialTotal: total,
        ),
      ).then((_) {
        _isDialogVisible = false;
      });
    });
  }

  // Improved hide dialog method
  void hideDialog() {
    if (!_isDialogVisible) return;
    
    final context = _dialogContext;
    if (context != null) {
      Navigator.of(context, rootNavigator: true).popUntil((route) {
        return route.settings.name != 'dialog';
      });
      _isDialogVisible = false;
    }
  }

  // Clean up resources when no longer needed
  void dispose() {
    _progressController.close();
    _completeController.close();
  }

  bool get isDialogVisible => _isDialogVisible;

  static void showPremiumDialog(BuildContext context, {
    required String title,
    required String message,
    VoidCallback? onUpgrade,
  }) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.secondary.withOpacity(0.8),
                  ],
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.diamond_outlined, color: Colors.white, size: 40),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  ...['✨ Store over 250 cards', '📊 Advanced analytics', '🔔 Price alerts']  // Updated text here
                      .map((feature) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  color: Theme.of(context).colorScheme.primary,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  feature,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                          )),
                  const SizedBox(height: 16),
                  Text(
                    '\$2.99',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    height: 45,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(25),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF4CAF50),  // Material Green
                          Color(0xFF66BB6A),  // Lighter Green
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.3),
                          spreadRadius: 1,
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        // Use purchasePremium instead of subscribe
                        context.read<PurchaseService>().purchasePremium();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        shadowColor: Colors.transparent,
                        elevation: 0,
                      ),
                      child: const Text(
                        'Subscribe Now',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Maybe Later',
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey[400] // Lighter in dark mode
                            : Colors.grey[800], // Much darker in light mode
                        fontSize: 14,
                        fontWeight: FontWeight.w500, // Slightly bolder
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
