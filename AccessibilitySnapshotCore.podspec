Pod::Spec.new do |s|
  s.name             = 'AccessibilitySnapshotCore'
  s.version          = '0.6.0'
  s.summary          = 'Easy regression testing for iOS accessibility'

  s.homepage         = 'https://github.com/CashApp/AccessibilitySnapshot'
  s.license          = { :type => 'Apache License, Version 2.0', :file => 'LICENSE' }
  s.authors          = 'Square'
  s.source           = { :git => 'https://github.com/CashApp/AccessibilitySnapshot.git', :tag => s.version.to_s }

  s.swift_version = '5.0.1'

  s.ios.deployment_target = '13.0'

  s.source_files = 'Sources/AccessibilitySnapshot/Core/Swift/Classes/**/*.swift', 'Sources/AccessibilitySnapshot/Core/ObjC/**/*.{h,m}','Sources/AccessibilitySnapshot/Core/Swift/AccessibilityPreview/**/*.swift'
  s.public_header_files = 'Sources/AccessibilitySnapshot/Core/ObjC/include/*.h'
  s.resources = 'Sources/AccessibilitySnapshot/Core/Swift/Assets/**/*.{strings,xcassets}'
  s.resource_bundles = {
   'AccessibilitySnapshot' => ['Sources/AccessibilitySnapshot/Core/Swift/Assets/**/*.{strings,xcassets}']
  }
end
