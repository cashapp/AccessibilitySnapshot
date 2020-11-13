Pod::Spec.new do |s|
  s.name             = 'AccessibilitySnapshot'
  s.version          = '0.4.0'
  s.summary          = 'Easy regression testing for iOS accessibility'

  s.homepage         = 'https://github.com/CashApp/AccessibilitySnapshot'
  s.license          = { :type => 'Apache License, Version 2.0', :file => 'LICENSE' }
  s.authors          = 'Square'
  s.source           = { :git => 'https://github.com/CashApp/AccessibilitySnapshot.git', :tag => s.version.to_s }

  s.swift_version = '5.0.1'

  s.ios.deployment_target = '12.0'

  s.default_subspecs = 'Core', 'SnapshotTesting'

  s.subspec 'Core' do |ss|
    ss.source_files = 'Sources/AccessibilitySnapshotCore/Classes/**/*.swift', 'Sources/AccessibilitySnapshotCore-ObjC/**/*.{h,m}'
    ss.public_header_files = 'Sources/AccessibilitySnapshotCore-ObjC/include/*.h'
    ss.resource_bundles = {
     'AccessibilitySnapshot' => ['Sources/AccessibilitySnapshotCore/Assets/**/*.{strings,xcassets}']
    }
  end

  s.subspec 'iOSSnapshotTestCase' do |ss|
    ss.source_files = 'Sources/AccessibilitySnapshot/iOSSnapshotTestCase/**/*.{swift,h,m}'
    ss.public_header_files = [
      'Sources/AccessibilitySnapshot/iOSSnapshotTestCase/FBSnapshotTestCase_Accessibility.h',
    ]

    ss.dependency 'AccessibilitySnapshot/Core'
    ss.dependency 'iOSSnapshotTestCase', '~> 6.0'
  end

  s.subspec 'SnapshotTesting' do |ss|
    ss.source_files = 'Sources/AccessibilitySnapshot/SnapshotTesting/**/*.{swift,h,m}'

    ss.dependency 'AccessibilitySnapshot/Core'
    ss.dependency 'SnapshotTesting', '~> 1.0'
  end

  s.frameworks = 'XCTest'
  s.weak_frameworks = 'XCTest'
end