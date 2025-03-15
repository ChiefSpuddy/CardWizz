#!/bin/bash

echo "🔧 Fixing Firebase non-modular headers issue"

# Exit on any error
set -e

# Setup paths
FIREBASE_MODULE_DIR="$PWD/Pods/Headers/Public/Firebase"
MODULE_MAP_FILE="$FIREBASE_MODULE_DIR/module.modulemap"
FIREBASE_UMBRELLA="$FIREBASE_MODULE_DIR/Firebase.h"

echo "📋 Creating directory structure..."
mkdir -p "$FIREBASE_MODULE_DIR"

echo "🔍 Checking Firebase.h exists..."
if [ ! -f "$FIREBASE_UMBRELLA" ]; then
  echo "⚠️ Firebase.h not found at $FIREBASE_UMBRELLA"
  FIREBASE_UMBRELLA="$PWD/Pods/Firebase/CoreOnly/Sources/Firebase.h"
  
  if [ -f "$FIREBASE_UMBRELLA" ]; then
    echo "📄 Found Firebase.h at $FIREBASE_UMBRELLA, creating symlink"
    ln -sf "$FIREBASE_UMBRELLA" "$FIREBASE_MODULE_DIR/Firebase.h"
  else
    echo "❌ Firebase.h not found, cannot continue"
    exit 1
  fi
fi

echo "📝 Creating module map for Firebase..."
cat > "$MODULE_MAP_FILE" << EOL
module Firebase {
  umbrella header "Firebase.h"
  export *
  module * { export * }
}
EOL

echo "📄 Creating .modulemap files for other Firebase modules"
for dir in $(find "$PWD/Pods/Headers/Public" -type d -name "Firebase*" | grep -v "Firebase$"); do
  module_name=$(basename "$dir")
  module_file="$dir/module.modulemap"

  if [ ! -f "$module_file" ]; then
    echo "  ➕ Creating module map for $module_name"
    mkdir -p "$dir"
    cat > "$module_file" << EOL
module $module_name {
  export *
  umbrella header "$module_name.h"
  module * { export * }
  
  link framework "Foundation"
  link framework "Security"
  link framework "SystemConfiguration"
  link framework "UIKit"
}
EOL
  fi
done

echo "🔍 Modifying firebase_auth source files to use @import..."
AUTH_DIR="$HOME/.pub-cache/hosted/pub.dev/firebase_auth-4.15.0/ios/Classes"

# Find all files that include Firebase.h
FILES_WITH_FIREBASE_IMPORT=$(grep -l "#import <Firebase/Firebase.h>" $(find "$AUTH_DIR" -name "*.h" -o -name "*.m") 2>/dev/null || echo "")

if [ -n "$FILES_WITH_FIREBASE_IMPORT" ]; then
  for file in $FILES_WITH_FIREBASE_IMPORT; do
    echo "  🔧 Fixing import in $file"
    sed -i.bak 's/#import <Firebase\/Firebase.h>/@import Firebase;/g' "$file"
    rm -f "${file}.bak"
  done
fi

echo "🧹 Updating project settings..."
# Add DEFINES_MODULE=YES to make Firebase accessible as a module
find "$PWD/Pods/Pods.xcodeproj" -name "*.pbxproj" -exec sed -i.bak 's/CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES = NO;/CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES = YES;/g' {} \;
find "$PWD/Pods/Pods.xcodeproj" -name "*.pbxproj" -exec sed -i.bak 's/DEFINES_MODULE = NO;/DEFINES_MODULE = YES;/g' {} \;
find "$PWD" -name "*.bak" -type f -delete

echo "✅ Firebase module fixes applied. Running pod install again..."
pod install

echo "🚀 Done! Now run 'flutter run' to build your app"
