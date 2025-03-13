import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../l10n/app_localizations.dart';
import '../utils/privacy_test_helper.dart';

class PrivacySettingsScreen extends StatelessWidget {
  const PrivacySettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.translate('privacySettings')),
        actions: [
          if (const bool.fromEnvironment('dart.vm.product') == false)
            IconButton(
              icon: const Icon(Icons.bug_report),
              onPressed: () async {
                final isValid = await PrivacyTestHelper.verifyPrivacySettings();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isValid 
                            ? 'Privacy settings verified ✓'
                            : 'Privacy settings verification failed ✗'
                      ),
                      backgroundColor: isValid ? Colors.green : Colors.red,
                    ),
                  );
                }
              },
            ),
        ],
      ),
      body: ListView(
        children: [
          const SizedBox(height: 16),
          // Data Collection Section
          _buildSection(
            context,
            title: 'Data Collection',
            children: [
              SwitchListTile(
                title: const Text('Analytics Collection'),
                subtitle: const Text('Help improve the app by sharing anonymous usage data'),
                value: appState.analyticsEnabled,
                onChanged: (value) => appState.setAnalyticsEnabled(value),
              ),
              SwitchListTile(
                title: const Text('Search History'),
                subtitle: const Text('Save your recent searches'),
                value: appState.searchHistoryEnabled,
                onChanged: (value) => appState.setSearchHistoryEnabled(value),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Privacy Controls
          _buildSection(
            context,
            title: 'Privacy Controls',
            children: [
              SwitchListTile(
                title: const Text('Profile Visibility'),
                subtitle: const Text('Allow others to see your collection'),
                value: appState.profileVisible,
                onChanged: (value) => appState.setProfileVisibility(value),
              ),
              SwitchListTile(
                title: const Text('Price Information'),
                subtitle: const Text('Show card prices in your collection'),
                value: appState.showPrices,
                onChanged: (value) => appState.setShowPrices(value),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Data Management
          _buildSection(
            context,
            title: 'Data Management',
            children: [
              ListTile(
                title: const Text('Export My Data'),
                leading: const Icon(Icons.download),
                onTap: () => appState.exportUserData(),
              ),
              ListTile(
                title: const Text('Clear Search History'),
                leading: const Icon(Icons.history),
                onTap: () => appState.clearSearchHistory(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          const Divider(height: 1),
          ...children,
        ],
      ),
    );
  }
}
