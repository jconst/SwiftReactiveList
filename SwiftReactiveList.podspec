Pod::Spec.new do |s|
  s.name             = "SwiftReactiveList"
  s.version          = "0.1.0"
  s.summary          = "Table and collection view controllers that automatically populates themselves, and animate the insertion and deletion of rows/items."
  
  s.homepage         = "https://github.com/jconst/SwiftReactiveList"
  s.license          = "MIT"
  s.author           = { "Joseph Constantakis" => "jcon5294@gmail.com" }
  s.source           = { :git => "https://github.com/jconst/SwiftReactiveList.git", :tag => s.version.to_s }
  
  s.platform              = :ios, '9.0'
  s.ios.deployment_target = '8.0'
  s.requires_arc          = true

  s.source_files = 'Source'

  s.framework = 'UIKit'
  s.dependency 'ReactiveCocoa', '>= 4.0'
end
