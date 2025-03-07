#!/bin/bash

echo "Fixing Card Arena imports..."

# Run flutter pub get to update dependencies
flutter pub get

# Create all necessary directories
mkdir -p /Users/sam.may/CardWizz/assets/animations
mkdir -p /Users/sam.may/CardWizz/assets/icons

# Run flutter clean to clear any cached builds
echo "Running flutter clean..."
flutter clean

# Run flutter pub get again
echo "Running flutter pub get again..."
flutter pub get

# Remove .dart_tool directory to force full rebuild
echo "Removing .dart_tool directory..."
rm -rf .dart_tool

# Try running the app
echo "Fixed imports! Now try running the app with: flutter run"

# Make script executable
chmod +x /Users/sam.may/CardWizz/fix_battle_imports.sh
