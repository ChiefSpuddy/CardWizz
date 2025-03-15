#!/bin/bash

echo "🔧 Starting comprehensive Firebase fix script"

# Exit on error
set -e

echo "🧹 Cleaning Flutter project"
cd ..
flutter clean

echo "♻️ Regenerating Flutter dependencies"
flutter pub get

echo "🧯 Removing all CocoaPods artifacts"
cd ios
rm -rf Pods Podfile.lock
rm -rf .symlinks
rm -rf ~/Library/Developer/Xcode/DerivedData/*Runner*

echo "🩺 Fixing firebase_auth imports"
AUTH_PLUGIN_DIR="$HOME/.pub-cache/hosted/pub.dev/firebase_auth-4.15.0/ios/Classes"

# Make sure imports use standard #import format, not @import
find "$AUTH_PLUGIN_DIR" -name "*.h" -o -name "*.m" | while read file; do
  # Replace @import Firebase with #import <Firebase/Firebase.h>
  sed -i.bak 's/@import Firebase;/#import <Firebase\/Firebase.h>/g' "$file"
  # Also check for other variations
  sed -i.bak 's/@import FirebaseAuth;/#import <FirebaseAuth\/FirebaseAuth.h>/g' "$file"
  rm -f "${file}.bak"
done

echo "📝 Updating Podfile with fixes"
cat > Podfile << 'EOL'
platform :ios, '12.0'

ENV['COCOAPODS_DISABLE_STATS'] = 'true'

project 'Runner', {
  'Debug' => :debug,
  'Profile' => :release,
  'Release' => :release,
}

def flutter_root
  generated_xcode_build_settings_path = File.expand_path(File.join('..', 'Flutter', 'Generated.xcconfig'), __FILE__)
  unless File.exist?(generated_xcode_build_settings_path)
    raise "#{generated_xcode_build_settings_path} must exist. If you're running pod install manually, make sure flutter pub get is executed first"
  end

  File.foreach(generated_xcode_build_settings_path) do |line|
    matches = line.match(/FLUTTER_ROOT\=(.*)/)
    return matches[1].strip if matches
  end
  raise "FLUTTER_ROOT not found in #{generated_xcode_build_settings_path}. Try deleting Generated.xcconfig, then run flutter pub get"
end

require File.expand_path(File.join('packages', 'flutter_tools', 'bin', 'podhelper'), flutter_root)

flutter_ios_podfile_setup

pre_install do |installer|
  puts "🔨 Fixing dependency conflicts..."
  
  # Force compatibility for Firebase modules
  installer.pod_targets.each do |pod|
    # For all specs in all pods
    pod.specs.each do |spec|
      # Allow non-modular includes for all Firebase modules
      if spec.name.start_with?('Firebase') || spec.name.start_with?('Google')
        def spec.build_settings 
          settings = super || {}
          settings['CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES'] = 'YES'
          settings['DEFINES_MODULE'] = 'YES'
          return settings
        end
      end
    end
  end
end

target 'Runner' do
  use_frameworks!
  use_modular_headers!

  # Force specific versions of problematic dependencies
  pod 'GTMSessionFetcher', '2.1.0'
  pod 'GTMSessionFetcher/Core', '2.1.0'
  pod 'GoogleSignIn', '6.2.4'

  # Install Flutter plugins
  flutter_install_all_ios_pods File.dirname(File.realpath(__FILE__))
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
    
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '12.0'
      
      # These build settings help with Firebase compatibility
      config.build_settings['CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES'] = 'YES'
      config.build_settings['APPLICATION_EXTENSION_API_ONLY'] = 'NO'
      config.build_settings['BUILD_LIBRARY_FOR_DISTRIBUTION'] = 'YES'
      
      # Ensure we can find headers
      if !config.build_settings['HEADER_SEARCH_PATHS'].nil?
        config.build_settings['HEADER_SEARCH_PATHS'] += ' ${PODS_ROOT}/Firebase/CoreOnly/Sources'
      else
        config.build_settings['HEADER_SEARCH_PATHS'] = '$(inherited) ${PODS_ROOT}/Firebase/CoreOnly/Sources'
      end
    end
  end
  
  # Remove duplicate module maps that cause conflicts
  system('find "${PODS_ROOT}" -name "module.modulemap" -path "*/Firebase/CoreOnly/Sources/*" -delete')
end
EOL

echo "📦 Installing pods with clean configuration"
pod install

echo "🛠️ Post-installation module map and header fixes"
# Ensure we don't have duplicate module maps
find "Pods" -name "module.modulemap" -path "*/Firebase/CoreOnly/Sources/*" -delete

# Create a consistent Firebase module map
mkdir -p "Pods/Headers/Public/Firebase"
cat > "Pods/Headers/Public/Firebase/module.modulemap" << EOL
module Firebase {
  umbrella header "Firebase.h"
  export *
}
EOL

# Ensure Firebase.h is available
if [ ! -f "Pods/Headers/Public/Firebase/Firebase.h" ]; then
  if [ -f "Pods/Firebase/CoreOnly/Sources/Firebase.h" ]; then
    cp "Pods/Firebase/CoreOnly/Sources/Firebase.h" "Pods/Headers/Public/Firebase/Firebase.h"
  fi
fi

echo "✅ All fixes have been applied"
echo "🚀 Now run 'flutter run' to build your app"
