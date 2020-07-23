Pod::Spec.new do |s|
  s.name             = 'AccessibilitySnapshot'
  s.version          = '0.3.2'
  s.summary          = 'Easy regression testing for iOS accessibility'

  s.homepage         = 'https://github.com/CashApp/AccessibilitySnapshot'
  s.license          = { :type => 'Apache License, Version 2.0', :file => 'LICENSE' }
  s.authors          = 'Square'
  s.source           = { :git => 'https://github.com/CashApp/AccessibilitySnapshot.git', :tag => s.version.to_s }

  s.swift_version = '5.0.1'

  s.ios.deployment_target = '10.0'

  s.default_subspecs = 'Core', 'iOSSnapshotTestCase'

  s.subspec 'Core' do |ss|
    ss.source_files = 'AccessibilitySnapshot/Core/Classes/**/*.{swift,h,m}'
    ss.public_header_files = [
      'AccessibilitySnapshot/Core/Classes/UIAccessibilityStatusUtility.h',
      'AccessibilitySnapshot/Core/Classes/UIView+DynamicTypeSnapshotting.h',
    ]
    ss.resource_bundles = {
     'AccessibilitySnapshot' => ['AccessibilitySnapshot/Core/Assets/**/*.{strings,xcassets}']
    }

    ss.dependency 'fishhook', '~> 0.2'
  end

  s.subspec 'iOSSnapshotTestCase' do |ss|
    ss.source_files = 'AccessibilitySnapshot/iOSSnapshotTestCase/Classes/**/*.{swift,h,m}'
    ss.public_header_files = [
      'AccessibilitySnapshot/iOSSnapshotTestCase/Classes/FBSnapshotTestCase_Accessibility.h',
    ]

    ss.dependency 'AccessibilitySnapshot/Core'
    ss.dependency 'iOSSnapshotTestCase', '~> 6.0'
  end

  s.frameworks = 'XCTest'
  s.weak_frameworks = 'XCTest'
end
