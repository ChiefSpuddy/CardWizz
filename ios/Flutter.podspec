Pod::Spec.new do |s|
  s.name             = 'Flutter'
  s.version          = '1.0.0'
  s.summary          = 'A UI toolkit for beautiful and fast apps.'
  s.homepage         = 'https://flutter.dev'
  s.license          = { :type => 'MIT' }
  s.author           = { 'Flutter Dev Team' => 'flutter-dev@googlegroups.com' }
  s.source           = { :git => 'https://github.com/flutter/engine', :tag => s.version.to_s }
  s.ios.deployment_target = '12.0'
  s.vendored_frameworks = 'Flutter.framework'
  s.source_files = 'Flutter.framework/Headers/*.h'
  s.public_header_files = 'Flutter.framework/Headers/*.h'
  s.weak_frameworks = 'UIKit', 'Foundation'
end
