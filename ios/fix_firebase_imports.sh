#!/bin/bash

echo "🔧 Fixing Firebase import issues"

# Exit on error
set -e

# Get the plugin directory
AUTH_PLUGIN_DIR="$HOME/.pub-cache/hosted/pub.dev/firebase_auth-4.15.0/ios/Classes"

echo "📋 1. Reverting @import changes back to #import"
find "$AUTH_PLUGIN_DIR" -name "*.h" -o -name "*.m" | xargs grep -l "@import Firebase;" | while read file; do
  echo "  🔄 Reverting import in $file"
  sed -i.bak 's/@import Firebase;/#import <Firebase\/Firebase.h>/g' "$file"
  rm -f "${file}.bak"
done

echo "🔧 2. Updating build settings for firebase_auth module"
# Set up an Objective-C header file to bridge Firebase
mkdir -p "Pods/Headers/Private/firebase_auth"
cat > "Pods/Headers/Private/firebase_auth/Firebase_umbrella.h" << EOL
// Firebase umbrella header for firebase_auth

#import <Foundation/Foundation.h>

// Import Firebase.h
#ifndef FIREBASE_UMBRELLA_H
#define FIREBASE_UMBRELLA_H

#import <Firebase/Firebase.h>

#endif // FIREBASE_UMBRELLA_H
EOL

# Update the Podfile
echo "📝 3. Updating Podfile to allow non-modular includes"
cat > Podfile.additions << EOL

# Added for Firebase compatibility
post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      # Enable non-modular headers for all targets
      config.build_settings['CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES'] = 'YES'
      
      # Add symbol visibility setting
      config.build_settings['GCC_SYMBOLS_PRIVATE_EXTERN'] = 'YES'
      
      # Explicitly set DEFINES_MODULE for firebase_auth
      if target.name == 'firebase_auth'
        config.build_settings['DEFINES_MODULE'] = 'YES'
      end
    end
  end
end
EOL

# Check if the addition is already in the Podfile
if ! grep -q "CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES" Podfile; then
  cat Podfile.additions >> Podfile
  rm -f Podfile.additions
fi

echo "🧹 4. Cleaning CocoaPods artifacts"
rm -rf Pods/firebase_auth
rm -rf Pods/FirebaseAuth
rm -rf Pods/FirebaseCore
rm -rf Pods/FirebaseCoreInternal
rm -rf Pods/Firebase
rm -f Podfile.lock

echo "📦 5. Reinstalling pods"
pod install --repo-update

echo "🛠️ 6. Applying additional compatibility fixes"
# Create a module map for Firebase
FIREBASE_HEADERS="Pods/Headers/Public/Firebase"
mkdir -p "$FIREBASE_HEADERS"

# Create a modulemap for Firebase
if [ -d "$FIREBASE_HEADERS" ]; then
  echo "📝 Creating explicit module map for Firebase"
  
  # Locate Firebase.h
  FIREBASE_H_PATH=""
  for path in \
    "Pods/Firebase/CoreOnly/Sources/Firebase.h" \
    "Pods/FirebaseCore/Firebase/Core/Public/Firebase.h" \
    "Pods/FirebaseCore/FirebaseCore/Sources/Public/Firebase.h" \
    "Pods/Headers/Public/Firebase/Firebase.h"; do
    if [ -f "$path" ]; then
      FIREBASE_H_PATH="$path"
      break
    fi
  done

  if [ -n "$FIREBASE_H_PATH" ]; then
    echo "🔍 Found Firebase.h at: $FIREBASE_H_PATH"
    
    # Create symlink if needed
    if [ ! -f "$FIREBASE_HEADERS/Firebase.h" ]; then
      ln -sf "$FIREBASE_H_PATH" "$FIREBASE_HEADERS/Firebase.h"
    fi
    
    # Create module map
    cat > "$FIREBASE_HEADERS/module.modulemap" << EOL
module Firebase {
  umbrella header "Firebase.h"
  export *
}
EOL
    echo "✅ Created Firebase module map"
  else
    echo "⚠️ Couldn't find Firebase.h, skipping module map creation"
  fi
else
  echo "⚠️ Firebase headers directory not found"
fi

echo "✅ Done! Now run 'flutter run' to build your app"
