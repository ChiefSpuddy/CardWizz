import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import '../services/purchase_service.dart';
import '../widgets/styled_toast.dart';

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
    
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Connecting to App Store...'),
          ],
        ),
      ),
    );
    
    try {
      // Attempt to make the purchase
      final success = await purchaseService.purchasePremium();
      
      // Close loading dialog
      if (context.mounted) Navigator.of(context).pop();
      
      if (context.mounted) {
        if (success) {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: StyledToast(
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
              content: StyledToast(
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
      if (context.mounted) Navigator.of(context).pop(); // Close loading dialog
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: StyledToast(
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

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with subscription title
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.diamond_outlined, color: Colors.white),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'CardWizz Premium Subscription',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Add prominent subscription info at the top
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Subscription Details:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '• Title: CardWizz Premium Subscription\n'
                    '• Length: Monthly subscription\n'
                    '• Price: \$2.99 USD per month\n'
                    '• Billing: Charged to Apple ID account\n'
                    '• Renewal: Automatically renews unless cancelled\n'
                    '• Cancellation: At least 24h before renewal',
                    style: TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Subscription details
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Monthly Auto-Renewable Subscription',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '\$2.99 USD per month',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Subscription automatically renews unless cancelled at least 24 hours before the end of the current period',
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Premium features list - updated list without unavailable features
                  const Text(
                    'Premium Features Included:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...[
                    '✨ Unlimited card collection (Free: 200)',  // Shortened text
                    '🔍 Unlimited card scanning (Free: 50/mo)',  // Shortened text
                    '📊 Advanced analytics and tracking',
                    '📈 Enhanced market data',
                    '📱 Multiple collections (Free: 4)',
                  ].map((feature) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, 
                          color: Theme.of(context).colorScheme.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            feature,
                            style: const TextStyle(fontSize: 13),  // Added size constraint
                          ),
                        ),
                      ],
                    ),
                  )),

                  const SizedBox(height: 16),
                  // Subscription information
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Theme.of(context).dividerColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Subscription Information:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '• Subscription length: 1 month\n'
                          '• Price: \$2.99 USD per month\n'
                          '• Payment charged to Apple ID account\n'
                          '• Subscription automatically renews unless cancelled\n'
                          '• Cancel anytime in App Store Settings',
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  // Required links
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _launchUrl('https://chiefspuddy.github.io/CardWizz/#terms-of-service'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            alignment: Alignment.center,
                          ),
                          child: const Text(
                            'Terms of Use',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _launchUrl('https://cardwizz.app/privacy'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            alignment: Alignment.center,
                          ),
                          child: const Text(
                            'Privacy Policy',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Action buttons
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Not Now'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      onPressed: () async {
                        final success = await _handlePurchase(context);
                        if (context.mounted) {
                          Navigator.pop(context, success);
                        }
                      },
                      icon: const Text('💎'),
                      label: const Text('Subscribe Now'),
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
