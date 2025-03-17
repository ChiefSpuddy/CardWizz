import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../services/auth_service.dart';
import 'package:cardwizz/screens/home_screen.dart';
import '../services/logging_service.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({Key? key}) : super(key: key);

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  bool _isLoading = false;

  // Handle Google sign-in with clear status updates
  Future<void> _handleGoogleSignIn(BuildContext context) async {
    // Prevent multiple sign-in attempts
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      LoggingService.debug("🔍 SIGNIN: Starting Google sign-in process");
      
      final authService = AuthService();
      await authService.initialize();
      
      final user = await authService.signInWithGoogle();
      
      LoggingService.debug("🔍 SIGNIN: Sign-in complete, user: ${user?.id}");
      
      // Clear loading state if navigation fails for some reason
      setState(() {
        _isLoading = false;
      });
      
      if (user != null && mounted) {
        LoggingService.debug("🔍 SIGNIN: User logged in, navigating to home");
        
        // First try direct navigation using AuthService helper
        authService.navigateToHome(context);
        
        // Log that navigation was attempted
        LoggingService.debug("🔍 SIGNIN: Navigation command executed");
      } else {
        LoggingService.debug("🔍 SIGNIN: No user returned or widget unmounted");
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sign in failed. Please try again.')),
          );
        }
      }
    } catch (error) {
      LoggingService.error("🔍 SIGNIN: Error during Google sign-in: $error");
      
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sign-in error: ${error.toString()}')),
        );
      }
    }
  }

  // Direct navigation for testing
  void _directNavigateToHome(BuildContext context) {
    LoggingService.debug("🔍 SIGNIN: Starting direct navigation");
    
    try {
      // Try a different navigation approach for testing
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed('/home');
        LoggingService.debug("🔍 SIGNIN: Direct named navigation executed");
      });
    } catch (e) {
      LoggingService.error("🔍 SIGNIN: Direct navigation failed: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign In'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: () => _directNavigateToHome(context),
            tooltip: 'Debug: Go to home',
          ),
        ],
      ),
      body: Stack(
        children: [
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Welcome to CardWizz',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Google Sign In Button (fixed to not use missing asset)
                  ElevatedButton.icon(
                    icon: const Icon(Icons.login), // Use an icon instead of the missing image
                    label: const Text('Sign in with Google'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: _isLoading ? null : () => _handleGoogleSignIn(context),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Add sign in with Apple button (placeholder)
                  ElevatedButton.icon(
                    icon: const Icon(Icons.apple),
                    label: const Text('Sign in with Apple'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {
                      // Existing Apple sign-in code
                    },
                  ),
                  
                  const SizedBox(height: 24),
                  
                  if (!_isLoading) TextButton(
                    onPressed: () => _directNavigateToHome(context),
                    child: const Text('Debug: Navigate to Home'),
                  ),
                ],
              ),
            ),
          ),
          
          // Show loading overlay when signing in
          if (_isLoading)
            Container(
              color: Colors.black45,
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Signing in...',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
