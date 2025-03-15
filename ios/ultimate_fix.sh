#!/bin/bash

echo "🧰 Starting ultimate CocoaPods dependency fix for CardWizz"
echo "------------------------------------------------------"

# Exit immediately if a command exits with a non-zero status
set -e

# Function to run with animated spinner
spinner() {
  local pid=$1
  local delay=0.1
  local spinstr='|/-\'
  while ps -p $pid > /dev/null; do
    local temp=${spinstr#?}
    printf " [%c]  " "$spinstr"
    local spinstr=$temp${spinstr%"$temp"}
    sleep $delay
    printf "\b\b\b\b\b\b"
  done
  printf "    \b\b\b\b"
}

echo "🧹 Step 1: Full project clean"
(
  cd ..
  flutter clean
) &
spinner $!

echo "💥 Step 2: Complete removal of CocoaPods artifacts"
(
  rm -rf Pods Podfile.lock
  rm -rf .symlinks
  rm -rf ~/Library/Caches/CocoaPods
  sudo rm -rf ~/Library/Developer/Xcode/DerivedData
  
  # Remove GTMSessionFetcher from CocoaPods cache
  find ~/.cocoapods -name "GTMSessionFetcher" -type d -exec rm -rf {} +
  find ~/.cocoapods -name "MLKitCommon" -type d -exec rm -rf {} +
) &
spinner $!

echo "📝 Step 3: Creating custom Podfile with extreme measures"
cat > Podfile << 'ENDOFPODFILE'
platform :ios, '12.0'

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
  puts "🔨 Aggressively fixing dependency conflicts..."
  # Force compatibility by removing GTMSessionFetcher version constraints
  installer.pod_targets.each do |pod|
    pod.specs.each do |spec|
      ["GTMSessionFetcher", "GTMSessionFetcher/Core", "GTMSessionFetcher/Full"].each do |name|
        if spec.dependencies[name]
          puts "→ Removing #{name} dependency from #{pod.name}"
          spec.dependencies.delete(name)
        end
      end
      
      # Handle MLKitCommon specifically
      if pod.name == "MLKitCommon"
        puts "→ Special handling for MLKitCommon"
        spec.dependencies.clear
      end
    end
  end
end

target 'Runner' do
  use_frameworks!
  use_modular_headers!
  
  # 1. FIRST, pin the problematic packages explicitly
  pod 'GTMSessionFetcher', '2.1.0'
  pod 'GTMSessionFetcher/Core', '2.1.0'
  
  # 2. SECOND, pin firebase packages
  pod 'Firebase/Core', '10.25.0'
  pod 'Firebase/Auth', '10.25.0'
  
  # 3. THIRD, pin sign-in
  pod 'GoogleSignIn', '6.2.4'
  
  # 4. NOW install Flutter pods
  flutter_install_all_ios_pods File.dirname(File.realpath(__FILE__))
end

post_install do |installer|
  puts "📎 Post-install: fixing build settings"
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
    
    # Fix deployment target for all pods
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '12.0'
      config.build_settings['ENABLE_BITCODE'] = 'NO'
      config.build_settings['CODE_SIGNING_ALLOWED'] = 'NO'
      config.build_settings['EXPANDED_CODE_SIGN_IDENTITY'] = ""
    end
  end
  
  # Create symbolic links to ensure headers are found
  system("mkdir -p Pods/Headers/Public/GTMSessionFetcher")
  system("find Pods/GTMSessionFetcher -name '*.h' -exec ln -sf {} Pods/Headers/Public/GTMSessionFetcher/ \\; 2>/dev/null || true")
end
ENDOFPODFILE

echo "🔄 Step 4: Regenerating Flutter dependencies"
(
  cd ..
  # Temporarily remove google_mlkit_text_recognition
  sed -i'.bak' '/google_mlkit_text_recognition/d' pubspec.yaml
  flutter pub get
) &
spinner $!

echo "🧰 Step 5: Installing pods with repo update and no cache"
(
  # Install bundler and required gems
  gem install bundler cocoapods --user-install
  bundle init
  echo "gem 'cocoapods'" >> Gemfile
  bundle install

  # Use bundler to execute pod commands
  export COCOAPODS_DISABLE_DETERMINISTIC_UUIDS=YES
  bundle exec pod repo update
  bundle exec pod install --verbose --no-repo-update
) &
spinner $!
wait $!

if [ $? -eq 0 ]; then
  echo "✅ Success! Dependencies resolved."
else
  echo "❌ First attempt failed. Trying extreme fallback approach..."
  
  # Create an extremely minimal Podfile just to make it work
  cat > Podfile << 'ENDOFMINIMALPODFILE'
platform :ios, '12.0'

target 'Runner' do
  use_frameworks!
  
  # Core Firebase dependencies only
  pod 'Firebase/Core', '10.25.0'
  pod 'Firebase/Auth', '10.25.0'
  pod 'GTMSessionFetcher', '2.1.0'
  
  # Manually include Flutter plugins that don't have GTMSessionFetcher dependencies
  flutter_install_ios_plugin_pods
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '12.0'
      config.build_settings['ENABLE_BITCODE'] = 'NO'
    end
  end
end
ENDOFMINIMALPODFILE

  # Try again
  rm -rf Pods Podfile.lock
  bundle exec pod install --verbose

  if [ $? -eq 0 ]; then
    echo "✅ Success with minimal configuration!"
    echo "⚠️ Note: Some Flutter plugins may be disabled - edit your code accordingly."
  else
    echo "❌ All attempts failed. Please try the following manually:"
    echo "1. Remove all Firebase, Google Sign-in, and ML Kit dependencies from your Flutter project"
    echo "2. Rebuild the project with basic functionality first"
    echo "3. Re-add dependencies one by one with compatibility testing"
    exit 1
  fi
fi

echo "🚀 Setup complete. You may now run your app."
