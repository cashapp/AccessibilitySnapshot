Pod::Spec.new do |s|
  s.name             = 'AccessibilitySnapshot'
  s.version          = '0.6.0'
  s.summary          = 'Easy regression testing for iOS accessibility'

  s.homepage         = 'https://github.com/CashApp/AccessibilitySnapshot'
  s.license          = { :type => 'Apache License, Version 2.0', :file => 'LICENSE' }
  s.authors          = 'Square'
  s.source           = { :git => 'https://github.com/CashApp/AccessibilitySnapshot.git', :tag => s.version.to_s }

  s.swift_version = '5.0.1'

  s.ios.deployment_target = '13.0'

  s.default_subspecs = 'Core', 'SnapshotTesting'

  s.subspec 'Core' do |ss|
    ss.source_files = 'Sources/AccessibilitySnapshot/Core/Swift/Classes/**/*.swift', 'Sources/AccessibilitySnapshot/Core/ObjC/**/*.{h,m}'
    ss.public_header_files = 'Sources/AccessibilitySnapshot/Core/ObjC/include/*.h'
    ss.resources = 'Sources/AccessibilitySnapshot/Core/Swift/Assets/**/*.{strings,xcassets}'
    ss.resource_bundles = {
     'AccessibilitySnapshot' => ['Sources/AccessibilitySnapshot/Core/Swift/Assets/**/*.{strings,xcassets}']
    }
  end

  s.subspec 'iOSSnapshotTestCase' do |ss|
    ss.source_files = 'Sources/AccessibilitySnapshot/iOSSnapshotTestCase/**/*.{swift,h,m}'
    ss.public_header_files = [
      'Sources/AccessibilitySnapshot/iOSSnapshotTestCase/ObjC/include/*.h',
    ]

    ss.dependency 'AccessibilitySnapshot/Core'
    ss.dependency 'iOSSnapshotTestCase', '~> 8.0'
    ss.frameworks = 'XCTest'
    ss.weak_frameworks = 'XCTest'
  end

  s.subspec 'SnapshotTesting' do |ss|
    ss.source_files = 'Sources/AccessibilitySnapshot/SnapshotTesting/**/*.{swift,h,m}'

    ss.dependency 'AccessibilitySnapshot/Core'
    ss.dependency 'SnapshotTesting', '~> 1.0'
    ss.frameworks = 'XCTest'
    ss.weak_frameworks = 'XCTest'
  end
end
