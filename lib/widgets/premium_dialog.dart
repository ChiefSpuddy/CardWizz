import 'package:flutter/material.dart';

class PremiumDialog extends StatelessWidget {
  const PremiumDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: const Row(
              children: [
                Icon(Icons.diamond_outlined, color: Colors.white),
                SizedBox(width: 8),
                Text(
                  'Unlock Premium',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  'CardWizz Premium - Monthly Subscription',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  '\$2.99 per month - Auto-renewable subscription',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                const Text(
                  'With Premium, you get:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...['✨ Unlimited card collection (Free: 200 cards)',
                    '🔍 Unlimited card scanning (Free: 50/month)',
                    '📊 Advanced analytics and price tracking',
                    '📱 Custom themes and background refresh',
                    '💾 Cloud backup and restore',
                    '📈 Enhanced real-time market data']
                    .map((feature) => ListTile(
                          leading: const Icon(Icons.check_circle, color: Colors.green),
                          title: Text(feature),
                          dense: true,
                          visualDensity: VisualDensity.compact,
                        )),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '\$2.99/month',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Auto-renewable, cancel anytime',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Theme.of(context).dividerColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Subscription Information',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '• Monthly subscription period\n'
                        '• Subscription price: \$2.99 USD per month\n'
                        '• Payment charged to Apple ID account\n'
                        '• Auto-renews unless cancelled 24h before renewal\n'
                        '• Manage subscriptions in App Store Settings\n'
                        '• Cancel anytime to stop future renewals',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () => launchUrl(
                        Uri.parse('https://chiefspuddy.github.io/CardWizz/#privacy-policy'),
                        mode: LaunchMode.externalApplication,
                      ),
                      child: Text(localizations.translate('privacyPolicy')),
                    ),
                    const SizedBox(width: 16),
                    TextButton(
                      onPressed: () => launchUrl(
                        Uri.parse('https://chiefspuddy.github.io/CardWizz/#terms-of-service'),
                        mode: LaunchMode.externalApplication,
                      ),
                      child: const Text('Terms of Service'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Maybe Later'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/profile');
                    },
                    child: const Text('UPGRADE NOW'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
