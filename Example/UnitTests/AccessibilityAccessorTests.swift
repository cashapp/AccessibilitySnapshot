import XCTest
import UIKit.UIAccessibility
@testable import AccessibilitySnapshot


@available(iOS 17.0, *)
final class AccessibilityAccessorTests: XCTestCase {
    
    private var testView: UIView!
    private var mockCustomContentProvider: MockCustomContentProvider!
    
    override func setUp() {
        super.setUp()
        testView = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        mockCustomContentProvider = MockCustomContentProvider()
        
    }
    
    override func tearDown() {
        testView = nil
        mockCustomContentProvider = nil
        super.tearDown()
    }
    
   
    
    // MARK: - iOS 17 Block-Based Tests
    
    @available(iOS 17.0, *)
    func testIsElement_PreferBlock() {
        testView.isAccessibilityElement = false
        testView.isAccessibilityElementBlock = { true }
        XCTAssertTrue(testView.isAccessibilityElement)
    }
    
    @available(iOS 17.0, *)
    func testElements_PreferBlock() {
        final class Element: NSObject {
             override init() {
                super.init()
                isAccessibilityElement = true
            }
        }
        
        let fallback = Element()
        let block = Element()
        testView.accessibilityElementsBlock = { [block] }
        testView.accessibilityElements = [fallback]
        XCTAssertEqual(testView.accessibilityElements?.first as? Element, block)
    }
    
    @available(iOS 17.0, *)
    func testContainerType_DOES_NOT_PreferBlock() {
        testView.accessibilityContainerType = .landmark
        
        // for some reason this is never used or even called
        testView.accessibilityContainerTypeBlock = {
            XCTFail("This never gets called")
            return .list
        }
        
        
        XCTAssertEqual(testView.accessibilityContainerType, .landmark)
    }
    
    @available(iOS 17.0, *)
    func testLabel_PreferBlock() {
        testView.accessibilityLabel = "Fallback Label"
        testView.accessibilityLabelBlock = { "Block Label" }
        XCTAssertEqual(testView.accessibilityLabel, "Block Label")
    }
    
    @available(iOS 17.0, *)
    func testValue_PreferBlock() {
        testView.accessibilityValue = "Fallback Value"
        testView.accessibilityValueBlock = { "Block Value" }
        XCTAssertEqual(testView.accessibilityValue, "Block Value")
    }
    
    @available(iOS 17.0, *)
    func testTraits_PreferBlock() {
        testView.accessibilityTraitsBlock = { .link }
        testView.accessibilityTraits = .button
        XCTAssertEqual(testView.accessibilityTraits, .link)
    }
    
    @available(iOS 17.0, *)
    func testHint_PreferBlock() {
        testView.accessibilityHintBlock = { "Block Hint" }
        testView.accessibilityHint = "Fallback Hint"
        XCTAssertEqual(testView.accessibilityHint, "Block Hint")
    }
    
    @available(iOS 17.0, *)
    func testIdentifier_PreferBlock() {
        testView.accessibilityIdentifierBlock = { "Block ID" }
        testView.accessibilityIdentifier = "Fallback ID"
        XCTAssertEqual(testView.accessibilityIdentifier, "Block ID")
    }
    
    @available(iOS 17.0, *)
    func testActivationPoint_PreferBlock() {
        testView.accessibilityActivationPoint = .zero
        testView.accessibilityActivationPointBlock = { CGPoint(x: 10, y: 20) }
        XCTAssertEqual(testView.accessibilityActivationPoint, CGPoint(x: 10, y: 20))
    }
    
    @available(iOS 17.0, *)
    func testFrame_PreferBlock() {
        testView.accessibilityFrame = .zero
        let blockFrame = CGRect(x: 10, y: 20, width: 100, height: 200)
        testView.accessibilityFrameBlock = { blockFrame }
        XCTAssertEqual(testView.accessibilityFrame, blockFrame)
    }
    
    @available(iOS 17.0, *)
    func testPath_PreferBlock() {
        let fallbackPath = UIBezierPath(rect: CGRect(x: 0, y: 0, width: 50, height: 50))
        let blockPath = UIBezierPath(rect: CGRect(x: 10, y: 10, width: 30, height: 30))
        testView.accessibilityPath = fallbackPath
        testView.accessibilityPathBlock = { blockPath }
        XCTAssertEqual(testView.accessibilityPath?.bounds, blockPath.bounds)
    }
    
    @available(iOS 17.0, *)
    func testUserInputLabels_PreferBlock() {
        testView.accessibilityUserInputLabelsBlock = { ["Block"] }
        testView.accessibilityUserInputLabels = ["Fallback"]
        XCTAssertEqual(testView.accessibilityUserInputLabels, ["Block"])
    }
    
    @available(iOS 17.0, *)
    func testCustomActions_PreferBlock() {
        let fallbackAction = UIAccessibilityCustomAction(name: "Fallback", target: self, selector: #selector(dummyAction))
        let blockAction = UIAccessibilityCustomAction(name: "Block", target: self, selector: #selector(dummyAction))
        testView.accessibilityCustomActions = [fallbackAction]
        testView.accessibilityCustomActionsBlock = { [blockAction] }
        XCTAssertEqual(testView.accessibilityCustomActions?.first?.name, "Block")
    }
    
    @available(iOS 17.0, *)
    func testCustomRotors_PreferBlock() {
        let fallbackRotor = UIAccessibilityCustomRotor(name: "Fallback") { _ in return nil }
        let blockRotor = UIAccessibilityCustomRotor(name: "Block") { _ in return nil }
        testView.accessibilityCustomRotors = [fallbackRotor]
        testView.accessibilityCustomRotorsBlock = { [blockRotor] }
        XCTAssertEqual(testView.accessibilityCustomRotors?.first?.name, "Block")
    }
    
    @available(iOS 17.0, *)
    func testCustomContent_DoesNotPerferBlock() {
        let fallbackContent = [AXCustomContent(label: "Fallback", value: "Value")]
        let blockContent = [AXCustomContent(label: "Block", value: "Value")]
        mockCustomContentProvider.accessibilityCustomContent = fallbackContent
        mockCustomContentProvider.accessibilityCustomContentBlock = {
            blockContent }
        
        // We manage our own variables for AXCustomContent, so there is no automatic preference
        XCTAssertEqual(mockCustomContentProvider.accessibilityCustomContent.first?.label, "Fallback")
        XCTAssertEqual(mockCustomContentProvider.accessibilityCustomContentBlock?()?.first?.label, "Block")

    }
    
    @objc private func dummyAction() {}
}



@available(iOS 17.0, *)
private class MockCustomContentProvider: NSObject, AXCustomContentProvider {
    var accessibilityCustomContent: [AXCustomContent]! = []
    var accessibilityCustomContentBlock: AXCustomContentReturnBlock?
}
