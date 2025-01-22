import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../providers/app_state.dart';

class SignInPrompt extends StatelessWidget {
  final String message;
  
  const SignInPrompt({
    super.key,
    this.message = 'Sign in to view your collection',
  });

  Future<void> _handleSignIn(BuildContext context) async {
    try {
      final user = await context.read<AppState>().signInWithApple();
      if (user == null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sign in failed')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.lock_outline,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          SignInWithAppleButton(
            onPressed: () => _handleSignIn(context),
            style: SignInWithAppleButtonStyle.black,
          ),
        ],
      ),
    );
  }
}
