import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import '../services/purchase_service.dart';
import '../services/logging_service.dart';
import 'dart:async'; // Add this import for Timer

class PremiumDialog extends StatelessWidget {
  const PremiumDialog({super.key});

  Future<void> _launchUrl(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  Future<bool> _handlePurchase(BuildContext context) async {
    final purchaseService = Provider.of<PurchaseService>(context, listen: false);
    
    // Pop the current dialog
    Navigator.pop(context);
    
    // Create a dialog context variable that can be closed in case of cancellation
    BuildContext? loadingDialogContext;
    
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        loadingDialogContext = dialogContext;
        return const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Connecting to App Store...'),
            ],
          ),
        );
      },
    );
    
    // Create a flag to track whether purchase completed
    bool purchaseCompleted = false;
    
    // Define the listener function before it's used
    void _onPurchaseUpdated(bool isPurchaseInProgress) {
      LoggingService.debug('Purchase progress update: $isPurchaseInProgress');
      if (!isPurchaseInProgress && loadingDialogContext != null) {
        // Close dialog when purchase is no longer in progress
        Navigator.of(loadingDialogContext!).pop();
        loadingDialogContext = null;
        purchaseService.removePurchaseListener(_onPurchaseUpdated);
      }
    }
    
    // Add a timeout to automatically close dialog after 10 seconds
    Timer? timeoutTimer = Timer(const Duration(seconds: 10), () {
      if (loadingDialogContext != null && !purchaseCompleted) {
        // Close dialog if it's still open after timeout
        LoggingService.debug('Purchase dialog timeout reached - closing dialog');
        Navigator.of(loadingDialogContext!).pop();
        loadingDialogContext = null;
        purchaseService.removePurchaseListener(_onPurchaseUpdated);
        
        // Show timeout message if context is still valid
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: _buildToast(
                context: context,
                title: 'Purchase Timed Out',
                subtitle: 'The subscription process was canceled or timed out.',
                icon: Icons.timer_off_outlined,
                backgroundColor: Colors.orange,
              ),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.transparent,
              elevation: 0,
            ),
          );
        }
      }
    });
    
    try {
      // Register purchase listener immediately to detect cancellations
      purchaseService.addPurchaseListener(_onPurchaseUpdated);
      LoggingService.debug('Starting premium purchase process');
      
      // Attempt to make the purchase
      bool? success = await purchaseService.purchasePremium() as bool?;
      purchaseCompleted = true;
      LoggingService.debug('Purchase completed with result: $success');
      
      // Cancel timeout timer
      timeoutTimer.cancel();
      
      // Purchase completed (whether successful or cancelled)
      purchaseService.removePurchaseListener(_onPurchaseUpdated);
      
      // Close loading dialog if it's still showing
      if (loadingDialogContext != null) {
        Navigator.of(loadingDialogContext!).pop();
        loadingDialogContext = null;
      }
      
      // If purchase was cancelled or returned null, treat as failed
      if (success == null) {
        success = false;
      }
      
      if (context.mounted) {
        if (success) {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: _buildToast(
                context: context, 
                title: 'Premium Activated!',
                subtitle: 'Thank you for your support. Enjoy all premium features!',
                icon: Icons.check_circle_outline,
                backgroundColor: Colors.green,
              ),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.transparent,
              elevation: 0,
            ),
          );
          return true;
        } else {
          // Purchase was canceled or failed
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: _buildToast(
                context: context,
                title: 'Subscription Not Completed',
                subtitle: 'Premium subscription was not purchased',
                icon: Icons.info_outline,
                backgroundColor: Colors.orange,
              ),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.transparent,
              elevation: 0,
            ),
          );
          return false;
        }
      }
      return false;
    } catch (e) {
      // Handle errors
      LoggingService.debug('Error during purchase: $e');
      purchaseCompleted = true;
      timeoutTimer.cancel();
      
      if (loadingDialogContext != null) {
        Navigator.of(loadingDialogContext!).pop(); // Close loading dialog
      }
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: _buildToast(
              context: context,
              title: 'Subscription Error',
              subtitle: 'Could not process subscription. Please try again later.',
              icon: Icons.error_outline,
              backgroundColor: Colors.red,
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
        );
      }
      return false;
    }
  }

  // Helper method to build toast notifications
  Widget _buildToast({
    required BuildContext context, 
    required String title, 
    required String subtitle,
    required IconData icon,
    required Color backgroundColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    
    // Get screen size to help with constraining content
    final screenSize = MediaQuery.of(context).size;
    final maxHeight = screenSize.height * 0.8; // Limit maximum height to 80% of screen

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: maxHeight,
          maxWidth: screenSize.width * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Premium header with gradient and illustration - Further reduced height
            Container(
              height: 140, // Reduced from 160 to 140
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colorScheme.primary,
                    colorScheme.secondary,
                  ],
                ),
              ),
              child: Stack(
                children: [
                  // Background pattern for visual interest
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _PremiumPatternPainter(
                        primaryColor: Colors.white.withOpacity(0.15),
                      ),
                    ),
                  ),
                  // Title and diamond icon - More compact layout
                  Padding(
                    padding: const EdgeInsets.all(16.0), // Reduced from 20 to 16
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min, // Add this to ensure minimal height
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.diamond_outlined,
                                color: Colors.white,
                                size: 24, // Reduced from 26 to 24
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'CardWizz Premium',
                                style: TextStyle(
                                  fontSize: 20, // Reduced from 22 to 20
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10), // Reduced from 12 to 10
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14, // Reduced from 16 to 14
                                vertical: 6, // Reduced from 8 to 6
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14), // Reduced from 16 to 14
                              ),
                              child: Text(
                                '\$0.99/month',
                                style: TextStyle(
                                  fontSize: 18, // Reduced from 20 to 18
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            // Move this pill to the right side of the price
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10, // Reduced from 12 to 10
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(10), // Reduced from 12 to 10
                              ),
                              child: const Text(
                                'Auto-renews',
                                style: TextStyle(
                                  fontSize: 10, // Reduced from 11 to 10
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Make the content scrollable to prevent overflow
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0), // Reduced from 24,20,24,0 to 20,16,20,0
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Premium Features',
                      style: theme.textTheme.titleMedium?.copyWith( // Changed from titleLarge to titleMedium
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12), // Reduced from 16 to 12
                    ...[
                      _buildFeatureRow(
                        context,
                        icon: Icons.collections_bookmark,
                        title: 'Unlimited Card Collection',
                        subtitle: 'No more 200 card limit',
                        gradient: LinearGradient(
                          colors: [Colors.purple.shade300, Colors.purple.shade500],
                        ),
                      ),
                      _buildFeatureRow(
                        context,
                        icon: Icons.camera_alt,
                        title: 'Unlimited Scanning',
                        subtitle: 'Scan as many cards as you want',
                        gradient: LinearGradient(
                          colors: [Colors.blue.shade300, Colors.blue.shade500],
                        ),
                      ),
                      _buildFeatureRow(
                        context,
                        icon: Icons.analytics,
                        title: 'Advanced Analytics',
                        subtitle: 'Detailed portfolio insights',
                        gradient: LinearGradient(
                          colors: [Colors.green.shade300, Colors.green.shade500],
                        ),
                      ),
                      _buildFeatureRow(
                        context,
                        icon: Icons.folder_special,
                        title: 'Multiple Collections',
                        subtitle: 'Create unlimited custom binders',
                        gradient: LinearGradient(
                          colors: [Colors.orange.shade300, Colors.orange.shade500],
                        ),
                      ),
                      _buildFeatureRow(
                        context,
                        icon: Icons.trending_up,
                        title: 'Enhanced Market Data',
                        subtitle: 'See detailed price trends',
                        gradient: LinearGradient(
                          colors: [Colors.red.shade300, Colors.red.shade500],
                        ),
                      ),
                    ],
                    
                    const SizedBox(height: 12), // Reduced from 16 to 12
                    
                    // Subscription information in a more compact format
                    Container(
                      padding: const EdgeInsets.all(12), // Reduced from 16 to 12
                      decoration: BoxDecoration(
                        color: isDark 
                            ? colorScheme.surfaceVariant.withOpacity(0.3)
                            : colorScheme.surfaceVariant.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(14), // Reduced from 16 to 14
                        border: Border.all(
                          color: colorScheme.outline.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min, // Add this to ensure minimal height
                        children: [
                          Text(
                            'Subscription Details',
                            style: theme.textTheme.titleSmall?.copyWith( // Changed from titleMedium to titleSmall
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8), // Reduced from 12 to 8
                          const Text(
                            '• Monthly subscription at \$0.99 USD\n'
                            '• Automatically renews unless cancelled\n'
                            '• Payment charged to Apple ID account\n'
                            '• Cancel anytime in App Store settings\n'
                            '• Cancel at least 24 hours before renewal',
                            style: TextStyle(height: 1.3, fontSize: 12), // Reduced height and font size
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 12), // Reduced from 16 to 12
                    
                    // Legal links in a more compact row
                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min, // Center the row contents
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildLegalLink(
                            context,
                            'Terms of Use',
                            'https://chiefspuddy.github.io/CardWizz/#terms-of-service',
                          ),
                          Container(
                            height: 12, // Reduced from 16 to 12
                            width: 1,
                            margin: const EdgeInsets.symmetric(horizontal: 12), // Reduced from 16 to 12
                            color: colorScheme.outline.withOpacity(0.5),
                          ),
                          _buildLegalLink(
                            context,
                            'Privacy Policy',
                            'https://cardwizz.app/privacy',
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 16), // Reduced from 20 to 16
                  ],
                ),
              ),
            ),

            // Action buttons with better styling
            Container(
              padding: const EdgeInsets.all(16), // Reduced from 20 to 16
              decoration: BoxDecoration(
                color: isDark
                    ? colorScheme.surfaceVariant.withOpacity(0.3)
                    : colorScheme.surfaceVariant.withOpacity(0.2),
                border: Border(
                  top: BorderSide(
                    color: colorScheme.outline.withOpacity(0.2),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          vertical: 10, // Reduced from 12 to 10
                          horizontal: 8, // Reduced from 12 to 8
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10), // Reduced from 12 to 10
                        ),
                      ),
                      child: Text(
                        'Not Now',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: () async {
                        final success = await _handlePurchase(context);
                        if (context.mounted) {
                          Navigator.pop(context, success);
                        }
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        padding: const EdgeInsets.symmetric(vertical: 10), // Reduced from 12 to 10
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10), // Reduced from 12 to 10
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(
                            Icons.diamond_outlined, 
                            size: 16, // Reduced from 18 to 16
                          ),
                          SizedBox(width: 6), // Reduced from 8 to 6
                          Text(
                            'Subscribe Now',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14, // Reduced from 15 to 14
                            ),
                          ),
                        ],
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
  
  Widget _buildFeatureRow(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Gradient gradient,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0), // Reduced from 14 to 10
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon with gradient background
          Container(
            padding: const EdgeInsets.all(6), // Reduced from 8 to 6
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(8), // Reduced from 10 to 8
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 18, // Reduced from 20 to 18
            ),
          ),
          const SizedBox(width: 10), // Reduced from 12 to 10
          // Feature details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min, // Add this to ensure minimal height
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13, // Reduced from 14 to 13
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11, // Reduced from 12 to 11
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildLegalLink(BuildContext context, String text, String url) {
    return InkWell(
      onTap: () => _launchUrl(url),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12, // Reduced from 13
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

// Custom painter to create decorative background patterns
class _PremiumPatternPainter extends CustomPainter {
  final Color primaryColor;
  
  _PremiumPatternPainter({required this.primaryColor});
  
  @override
  void paint(Canvas canvas, Size size) {
    // Draw geometric shapes
    final paint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    
    // Draw circles and diamonds in a pattern
    for (int i = 0; i < 5; i++) {
      for (int j = 0; j < 5; j++) {
        final x = -20 + (i * size.width / 3);
        final y = -20 + (j * size.height / 3);
        
        // Alternate between circles and diamonds
        if ((i + j) % 2 == 0) {
          canvas.drawCircle(Offset(x, y), 20, paint);
        } else {
          final path = Path()
            ..moveTo(x, y - 20)
            ..lineTo(x + 20, y)
            ..lineTo(x, y + 20)
            ..lineTo(x - 20, y)
            ..close();
          canvas.drawPath(path, paint);
        }
      }
    }
  }
  
  @override
  bool shouldRepaint(_PremiumPatternPainter oldDelegate) => false;
}
