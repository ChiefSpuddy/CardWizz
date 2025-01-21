import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  bool _showEmail = false;
  // Temporary mock data until Firebase is integrated
  final bool _isSignedIn = false;
  final String _mockEmail = 'user@example.com';
  final String _currentAvatar = 'assets/avatars/avatar1.png';
  final String _username = 'TestUser';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    );
    _animationController.forward();
    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Widget _buildProfileCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).primaryColor,
                  Theme.of(context).primaryColor.withOpacity(0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Column(
              children: [
                // Avatar Section with Edit Button
                Stack(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark ? Colors.grey[800] : Colors.white,
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                      child: ClipOval(
                        child: _currentAvatar != null
                            ? Image.asset(
                                _currentAvatar!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Icon(
                                  Icons.person,
                                  size: 50,
                                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                                ),
                              )
                            : Icon(
                                Icons.person,
                                size: 50,
                                color: isDark ? Colors.grey[400] : Colors.grey[600],
                              ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Username Section
                Column(
                  children: [
                    Text(
                      _username ?? 'Set username',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Email Display with Toggle
          if (_isSignedIn)
            Padding(
              padding: const EdgeInsets.all(16),
              child: ListTile(
                leading: Icon(Icons.email, color: isDark ? Colors.white : Theme.of(context).primaryColor),
                title: const Text('Email'),
                subtitle: _showEmail ? Text(_mockEmail) : const Text('Hidden'),
                trailing: IconButton(
                  icon: Icon(_showEmail ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _showEmail = !_showEmail),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.3,
              child: Lottie.asset(
                'assets/animations/background.json',
                fit: BoxFit.cover,
                repeat: true,
                frameRate: FrameRate(30),
                controller: _animationController,
              ),
            ),
          ),
          SafeArea(
            child: _isSignedIn
                ? ListView(
                    children: [
                      _buildProfileCard(context),
                      // Settings Section
                      Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Column(
                          children: [
                            ListTile(
                              leading: const Icon(Icons.palette),
                              title: const Text('Theme'),
                              trailing: Switch(
                                value: Theme.of(context).brightness == Brightness.dark,
                                onChanged: (_) {
                                  // TODO: Implement theme switching
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.account_circle,
                          size: 100,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Sign in to view your profile',
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () {
                            // TODO: Implement sign in
                          },
                          child: const Text('Sign In'),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}