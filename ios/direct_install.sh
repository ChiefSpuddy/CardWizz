#!/bin/bash

echo "🚨 Starting emergency dependency fix for CardWizz"

# Exit on errors
set -e

echo "🧹 1. Performing full clean"
cd ..
flutter clean

echo "💥 2. Deleting all CocoaPods related files"
cd ios
rm -rf Pods Podfile.lock
rm -rf ~/.cocoapods/repos/trunk/Specs/c/c/6/MLKitCommon/
rm -rf ~/Library/Caches/CocoaPods/

echo "🔄 3. Regenerating Flutter plugin registrations"
cd ..
flutter pub get

echo "📋 4. Replacing Podfile content with fixed version"
cd ios
cat > Podfile << 'ENDOFPODFILE'
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

# This pre_install hook completely removes all GTMSessionFetcher dependencies
pre_install do |installer|
  puts "🔧 Removing all GTMSessionFetcher version requirements"
  # Process all pod targets
  installer.pod_targets.each do |pod|
    # For all specs in all pods
    pod.specs.each do |spec|
      # Remove all dependencies on GTMSessionFetcher
      ['GTMSessionFetcher/Core', 'GTMSessionFetcher'].each do |dep|
        if spec.dependencies.key?(dep)
          puts "→ Removing #{dep} dependency from #{pod.name}"
          spec.dependencies.delete(dep)
        end
      end
    end
  end
end

target 'Runner' do
  use_frameworks!
  use_modular_headers!

  # Manually include core pods with pinned versions
  pod 'Firebase/Core', '10.25.0'
  pod 'Firebase/Auth', '10.25.0'
  
  # Force our own version of GTMSessionFetcher before all other pods
  pod 'GTMSessionFetcher', '2.1.0', :modular_headers => true
  pod 'GTMSessionFetcher/Core', '2.1.0', :modular_headers => true
  
  # Force specific versions of dependency chain
  pod 'GoogleSignIn', '6.2.4'
  pod 'GoogleMLKit/TextRecognition', '3.2.0'
  
  # Install Flutter plugins
  flutter_install_all_ios_pods File.dirname(File.realpath(__FILE__))
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
    
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '12.0'
      config.build_settings['ENABLE_BITCODE'] = 'NO'
      config.build_settings['CODE_SIGNING_ALLOWED'] = 'NO'
    end
  end
end
ENDOFPODFILE

echo "📦 5. Running pod install with repo update"
pod repo update
pod install --repo-update

if [ $? -eq 0 ]; then
  echo "✅ Dependency installation successful!"
  exit 0
else
  echo "❌ First pod install attempt failed, trying alternative approach..."
  
  # Try an even more extreme approach
  rm -rf Pods Podfile.lock
  
  # Create a more aggressive Podfile
  cat > Podfile << 'ENDOFAGGRESSIVEPODFILE'
platform :ios, '12.0'

target 'Runner' do
  use_frameworks!
  
  # Force just the basic dependencies with specific versions
  pod 'GTMSessionFetcher', '2.1.0'
  pod 'Firebase/Core', '10.25.0'
  pod 'Firebase/Auth', '10.25.0'
  pod 'GoogleSignIn', '6.2.4'
  
  # Now install Flutter plugins
  flutter_parent_dir = File.expand_path(File.join('..', 'Flutter'), __FILE__)
  flutter_config = File.join(flutter_parent_dir, "Generated.xcconfig")
  flutter_root = ""
  File.foreach(flutter_config) do |line|
    matches = line.match(/FLUTTER_ROOT\=(.*)/)
    flutter_root = matches[1].strip if matches
  end
  require File.expand_path(File.join(flutter_root, 'packages', 'flutter_tools', 'bin', 'podhelper'), flutter_root)
  flutter_ios_podfile_setup
  flutter_install_all_ios_pods File.dirname(File.realpath(__FILE__))
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '12.0'
    end
  end
end
ENDOFAGGRESSIVEPODFILE

  echo "🔄 Trying pod install with alternative Podfile..."
  pod install
  
  if [ $? -eq 0 ]; then
    echo "✅ Second pod install attempt successful!"
    exit 0
  else
    echo "❌ Installation failed. Please check your Flutter and CocoaPods versions."
    exit 1
  fi
fi
