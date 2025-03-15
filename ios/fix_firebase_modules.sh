#!/bin/bash

echo "🛠️ Fixing Firebase module map issues"

# Exit on error
set -e

echo "🧹 1. Cleaning project"
cd ..
flutter clean

echo "🧮 2. Updating Flutter dependencies"
flutter pub get

echo "🔄 3. Removing CocoaPods artifacts"
cd ios
rm -rf Pods Podfile.lock
rm -rf .symlinks

echo "⚙️ 4. Running pod install with clean caches"
# Clear CocoaPods cache
pod cache clean --all
# Update repos
pod repo update
# Install pods with fresh build
pod install --repo-update --verbose

if [ $? -ne 0 ]; then
  echo "❌ Pod install failed, trying one more approach..."
  
  # Modify Podfile.lock directly if it exists
  if [ -f "Podfile.lock" ]; then
    echo "📝 Attempting to fix Podfile.lock..."
    sed -i '' 's/HEADER_SEARCH_PATHS = /HEADER_SEARCH_PATHS = $(inherited) /g' Podfile.lock
  fi
  
  # Try one more install
  pod install
fi

echo "✅ Done! Run 'flutter run' to try building your app"
