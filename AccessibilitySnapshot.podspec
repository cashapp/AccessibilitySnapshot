Pod::Spec.new do |s|
  s.name             = 'AccessibilitySnapshot'
  s.version          = '0.3.0'
  s.summary          = 'Easy regression testing for iOS accessibility'

  s.homepage         = 'https://github.com/CashApp/AccessibilitySnapshot'
  s.license          = { :type => 'Apache License, Version 2.0', :file => 'LICENSE' }
  s.authors          = 'Square'
  s.source           = { :git => 'https://github.com/CashApp/AccessibilitySnapshot.git', :tag => s.version.to_s }

  s.swift_version = '5.0.1'

  s.ios.deployment_target = '10.0'

  s.source_files = 'AccessibilitySnapshot/Classes/**/*.{swift,h,m}'
  s.public_header_files = [
    'AccessibilitySnapshot/Classes/FBSnapshotTestCase_Accessibility.h',
    'AccessibilitySnapshot/Classes/UIAccessibilityStatusUtility.h',
    'AccessibilitySnapshot/Classes/UIView+DynamicTypeSnapshotting.h',
  ]

  s.resource_bundles = {
   'AccessibilitySnapshot' => ['AccessibilitySnapshot/Assets/**/*.{strings,xcassets}']
  }

  s.frameworks = 'XCTest'
  s.weak_frameworks = 'XCTest'

  s.dependency 'iOSSnapshotTestCase', '~> 6.0'
  s.dependency 'fishhook', '~> 0.2'
end
