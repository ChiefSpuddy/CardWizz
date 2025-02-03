import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/purchase_service.dart';
import 'navigation_service.dart';

class DialogService {
  static final DialogService _instance = DialogService._();
  bool _isDialogVisible = false;

  static DialogService get instance => _instance;
  DialogService._();

  Future<T?> showCustomDialog<T>(Widget dialog) async {
    if (!NavigationService.hasContext) {
      print('Cannot show dialog - no valid context');
      return null;
    }

    if (_isDialogVisible) {
      hideDialog();
    }

    _isDialogVisible = true;
    try {
      return await showDialog<T>(
        context: NavigationService.currentContext!,
        barrierDismissible: false,
        useRootNavigator: true,
        builder: (context) => WillPopScope(
          onWillPop: () async => false,
          child: dialog,
        ),
      );
    } catch (e) {
      print('Error showing dialog: $e');
      return null;
    } finally {
      _isDialogVisible = false;
    }
  }

  void hideDialog() {
    if (_isDialogVisible && NavigationService.hasContext) {
      Navigator.of(NavigationService.currentContext!).pop();
      _isDialogVisible = false;
    }
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
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 13,
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
