#!/bin/bash

echo "🔧 Fixing Firebase module redefinition issue"

# Exit on error
set -e

# Find and remove duplicated module definition
DUPLICATE_MODULE_PATH="Pods/Firebase/CoreOnly/Sources/module.modulemap"

if [ -f "$DUPLICATE_MODULE_PATH" ]; then
  echo "🗑️ Removing duplicate module definition: $DUPLICATE_MODULE_PATH"
  rm "$DUPLICATE_MODULE_PATH"
  echo "✅ Removed duplicate module map"
else
  echo "🔍 No duplicate module map found at $DUPLICATE_MODULE_PATH"
fi

# Check for any other module.modulemap files that might be causing conflicts
for MODULE_MAP in $(find "Pods" -name "module.modulemap" | grep -i firebase); do
  echo "Found module map: $MODULE_MAP"
  # If we need to keep this map but modify it, we could do that here
done

# Ensure our main module.modulemap is correct
FIREBASE_HEADERS="Pods/Headers/Public/Firebase"
if [ -d "$FIREBASE_HEADERS" ]; then
  echo "📝 Creating correct module map for Firebase"
  cat > "$FIREBASE_HEADERS/module.modulemap" << EOL
module Firebase {
  umbrella header "Firebase.h"
  export *
}
EOL
  echo "✅ Updated Firebase module map"
else
  echo "⚠️ Firebase headers directory not found"
fi

echo "🏗️ Rebuilding project..."
cd ..
flutter clean
cd ios
pod install

echo "🚀 Done! Now run 'flutter run' to build your app"
