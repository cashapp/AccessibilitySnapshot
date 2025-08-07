import XCTest
import UIKit.UIAccessibility

@testable import AccessibilitySnapshot



@available(iOS 17.0, *)
final class AccessibiliyAccessorTests: XCTestCase {

    func test_blockAccess() {
        for test in  [VariableSetObject(), OverrideObject()] {
            let label = test.accessibility.label
            XCTAssert(label == .block)
        }
    }
    
    class VariableSetObject: NSObject {
        override init() {
            super.init()
            self.isAccessibilityElement = true
            self.accessibilityLabel = .variable
            self.accessibilityLabelBlock =  { .block }
        }
    }

    class OverrideObject: NSObject {
        override var accessibilityLabel: String? {
            get { .variable }
            set {}
        }
        override var accessibilityLabelBlock: AXStringReturnBlock? {
            get { { .block } }
            set {}
        }
    }

}
extension String {
    static let variable = "Variable"
    static let block = "Block"
}
