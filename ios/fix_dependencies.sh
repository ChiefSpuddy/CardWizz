#!/bin/bash

echo "🚀 Starting aggressive dependency resolution for CardWizz..."

# Exit on error
set -e

echo "🧹 Deep cleaning the project..."
cd ..
flutter clean

echo "📦 Removing cached CocoaPods..."
rm -rf ~/.cocoapods/repos
rm -rf ~/Library/Caches/CocoaPods
rm -rf ~/Library/Developer/Xcode/DerivedData
pod deintegrate

echo "🗑️ Removing all CocoaPods artifacts..."
cd ios
rm -rf Pods 
rm -rf Podfile.lock
rm -rf .symlinks
rm -rf Flutter/Flutter.podspec

echo "🔄 Generating fresh Flutter plugins..."
cd ..
flutter pub get

echo "✏️ Patching GoogleMLKit podspecs in CocoaPods cache..."
find ~/Library/Caches/CocoaPods -name "*.podspec.json" -exec grep -l "GTMSessionFetcher" {} \; | while read file; do
  echo "Patching $file"
  sed -i '' 's/"GTMSessionFetcher\/Core.*"/"GTMSessionFetcher\/Core", ">= 1.1.0"/g' "$file"
done

echo "⚙️ Updating CocoaPods repo..."
cd ios
pod repo update

echo "📥 Installing pods with fixed dependencies..."
export COCOAPODS_DISABLE_DETERMINISTIC_UUIDS=YES
pod install --repo-update

if [ $? -eq 0 ]; then
  echo "✅ Pod installation successful!"
else
  echo "❌ Pod installation failed. Trying alternate approach..."
  
  # Create a direct override of the problematic podspec
  MLKIT_COMMON_PATH=~/.cocoapods/repos/trunk/Specs/c/c/6/MLKitCommon/8.0.0
  if [ -d "$MLKIT_COMMON_PATH" ]; then
    echo "🔧 Directly overriding MLKitCommon podspec..."
    cd "$MLKIT_COMMON_PATH"
    cp MLKitCommon.podspec.json MLKitCommon.podspec.json.backup
    sed -i '' 's/"GTMSessionFetcher\/Core.*"/"GTMSessionFetcher\/Core", ">= 1.1.0"/g' MLKitCommon.podspec.json
  fi
  
  echo "🔄 Clearing CocoaPods cache..."
  pod cache clean --all
  
  echo "🧪 Final attempt at pod installation..."
  cd ~/CardWizz/ios
  pod install --repo-update
fi

echo "📱 Run 'flutter run' to launch the app"
