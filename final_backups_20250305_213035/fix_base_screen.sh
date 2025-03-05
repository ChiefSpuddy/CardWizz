#!/bin/bash
echo "Fixing base_card_details_screen.dart..."
sed -i '' 's/const Widget build/Widget build/g' lib/screens/base_card_details_screen.dart
sed -i '' 's/const void /void /g' lib/screens/base_card_details_screen.dart
sed -i '' 's/const @override/@override/g' lib/screens/base_card_details_screen.dart
echo "Done! Now run flutter run to verify."
