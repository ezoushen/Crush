Pod::Spec.new do |s|
  s.name             = 'Crush'
  s.version          = '0.1.10'
  s.summary          = 'Dancing with Core Data'
  s.description      = 'Code with Core Data in a Swifty way'
  s.homepage         = 'https://github.com/ezoushen/Crush'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'ezoushen' => 'ytshen@seekrtech.com' }
  s.source           = { :git => 'https://github.com/ezoushen/Crush.git', :tag => s.version.to_s }
  s.swift_version = '5.0'
  s.ios.deployment_target = '11.0'
  s.source_files = 'Sources/Crush/**/*'
  s.frameworks = 'CoreData'
  s.platforms = { :ios => "11.0", :watchos => "4.0"}
end
