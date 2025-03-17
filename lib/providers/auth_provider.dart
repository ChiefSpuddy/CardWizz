// ...existing code...

// Make sure both sign-in methods update the auth state in the same way
Future<void> signInWithGoogle() async {
  // ...existing code...
  
  // Make sure the state update happens here, similar to Apple sign-in
  notifyListeners(); // Or similar state update mechanism
}

// ...existing code...
