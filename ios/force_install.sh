#!/bin/bash

echo "🚀 Starting force install process for CardWizz dependencies..."

# Exit if any command fails
set -e

echo "🧹 Cleaning project..."
cd ..
flutter clean

echo "📥 Getting Flutter packages..."
flutter pub get

echo "🔄 Removing CocoaPods cache..."
cd ios
rm -rf Pods Podfile.lock
rm -rf ~/Library/Caches/CocoaPods/Pods/Release/Firebase/
rm -rf ~/Library/Caches/CocoaPods/Pods/Release/FirebaseAuth/

echo "📦 Updating CocoaPods repo..."
pod repo update

echo "⚙️ Installing pods with forced versions..."
pod install --repo-update

echo "✅ Done! Now run 'flutter run'"
