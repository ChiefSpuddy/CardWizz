#!/bin/bash

echo "🔄 Updating CocoaPods repositories..."
pod repo update

echo "🧹 Cleaning old pods..."
rm -rf Pods Podfile.lock

echo "📦 Installing pods with repo update..."
pod install --repo-update

echo "✅ Done! If successful, you can now run 'flutter run'"
