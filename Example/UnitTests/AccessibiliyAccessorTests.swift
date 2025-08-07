import XCTest
@testable import AccessibilitySnapshot



final class TestView: UIView {
    override var accessibilityIdentifier: String? {
        get { super.accessibilityIdentifier }
        set { super.accessibilityIdentifier = newValue }
    }
}

@available(iOS 14.0, *)
final class AccessibilityAccessorTests: XCTestCase {
    
    private var testView: UIView!
    private var mockCustomContentProvider: MockCustomContentProvider!
    private var legacyCustomContentProvider: LegacyCustomContentProvider!
    
    override func setUp() {
        super.setUp()
        testView = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        if #available(iOS 17.0, *) {
            mockCustomContentProvider = MockCustomContentProvider()
        }
        legacyCustomContentProvider = LegacyCustomContentProvider()
    }
    
    override func tearDown() {
        testView = nil
        mockCustomContentProvider = nil
        legacyCustomContentProvider = nil
        super.tearDown()
    }
    
    // MARK: - iOS 16 Compatibility Tests
    
    func testIsElement_Legacy() {
        testView.isAccessibilityElement = true
        XCTAssertTrue(testView.accessibility.isElement)
        
        testView.isAccessibilityElement = false
        XCTAssertFalse(testView.accessibility.isElement)
    }
    
    func testElements_Legacy() {
        let elements: [Any] = [UIView(), UILabel()]
        testView.accessibilityElements = elements
        XCTAssertEqual(testView.accessibility.elements?.count, 2)
        
        testView.accessibilityElements = nil
        XCTAssertNil(testView.accessibility.elements)
    }
    
    func testContainerType_Legacy() {
        testView.accessibilityContainerType = .list
        XCTAssertEqual(testView.accessibility.containerType, .list)
        
        testView.accessibilityContainerType = .none
        XCTAssertEqual(testView.accessibility.containerType, .none)
    }
    
    func testLabel_Legacy() {
        testView.accessibilityLabel = "Test Label"
        XCTAssertEqual(testView.accessibility.label, "Test Label")
        
        testView.accessibilityLabel = nil
        XCTAssertNil(testView.accessibility.label)
    }
    
    func testValue_Legacy() {
        testView.accessibilityValue = "Test Value"
        XCTAssertEqual(testView.accessibility.value, "Test Value")
        
        testView.accessibilityValue = nil
        XCTAssertNil(testView.accessibility.value)
    }
    
    func testTraits_Legacy() {
        testView.accessibilityTraits = .button
        XCTAssertEqual(testView.accessibility.traits, .button)
        
        testView.accessibilityTraits = [.button, .selected]
        XCTAssertEqual(testView.accessibility.traits, [.button, .selected])
    }
    
    func testHint_Legacy() {
        testView.accessibilityHint = "Test Hint"
        XCTAssertEqual(testView.accessibility.hint, "Test Hint")
        
        testView.accessibilityHint = nil
        XCTAssertNil(testView.accessibility.hint)
    }
    
    func testIdentifier_Legacy() {
        testView.accessibilityIdentifier = "TestID"
        XCTAssertEqual(testView.accessibility.identifier, "TestID")
        
        testView.accessibilityIdentifier = nil
        XCTAssertNil(testView.accessibility.identifier)
    }
    
    func testActivationPoint_Legacy() {
        let point = CGPoint(x: 10, y: 20)
        testView.accessibilityActivationPoint = point
        XCTAssertEqual(testView.accessibility.activationPoint, point)
        
        testView.accessibilityActivationPoint = .zero
        XCTAssertEqual(testView.accessibility.activationPoint, .zero)
    }
    
    func testFrame_Legacy() {
        let frame = CGRect(x: 10, y: 20, width: 100, height: 200)
        testView.accessibilityFrame = frame
        XCTAssertEqual(testView.accessibility.frame, frame)
        
        testView.accessibilityFrame = .zero
        XCTAssertEqual(testView.accessibility.frame, .zero)
    }
    
    func testPath_Legacy() {
        let path = UIBezierPath(rect: CGRect(x: 0, y: 0, width: 50, height: 50))
        testView.accessibilityPath = path
        XCTAssertEqual(testView.accessibility.path?.bounds, path.bounds)
        
        testView.accessibilityPath = nil
        XCTAssertNil(testView.accessibility.path)
    }
    
    func testUserInputLabels_Legacy() {
        let labels = ["Label1", "Label2"]
        testView.accessibilityUserInputLabels = labels
        XCTAssertEqual(testView.accessibility.userInputLabels, labels)
        
        testView.accessibilityUserInputLabels = nil
        XCTAssertNil(testView.accessibility.userInputLabels)
    }
    
    func testCustomActions_Legacy() {
        let action = UIAccessibilityCustomAction(name: "Action", target: self, selector: #selector(dummyAction))
        testView.accessibilityCustomActions = [action]
        XCTAssertEqual(testView.accessibility.customActions?.count, 1)
        XCTAssertEqual(testView.accessibility.customActions?.first?.name, "Action")
        
        testView.accessibilityCustomActions = nil
        XCTAssertNil(testView.accessibility.customActions)
    }
    
    func testCustomRotors_Legacy() {
        let rotor = UIAccessibilityCustomRotor(name: "Rotor") { _ in return nil }
        testView.accessibilityCustomRotors = [rotor]
        XCTAssertEqual(testView.accessibility.customRotors?.count, 1)
        XCTAssertEqual(testView.accessibility.customRotors?.first?.name, "Rotor")
        
        testView.accessibilityCustomRotors = nil
        XCTAssertNil(testView.accessibility.customRotors)
    }
    
    func testCustomContent_Legacy() {
        let content = [AXCustomContent(label: "Label", value: "Value")]
        legacyCustomContentProvider.accessibilityCustomContent = content
        XCTAssertEqual(legacyCustomContentProvider.accessibility.customContent.count, 1)
        XCTAssertEqual(legacyCustomContentProvider.accessibility.customContent.first?.label, "Label")
        
        legacyCustomContentProvider.accessibilityCustomContent = []
        XCTAssertEqual(legacyCustomContentProvider.accessibility.customContent.count, 0)
    }
    
    func testNilObjectBehavior() {
        let accessor = NSObject.AccessibilityAccessor(object: nil)
        
        XCTAssertFalse(accessor.isElement)
        XCTAssertNil(accessor.elements)
        XCTAssertEqual(accessor.containerType, .none)
        XCTAssertNil(accessor.label)
        XCTAssertNil(accessor.value)
        XCTAssertEqual(accessor.traits, .none)
        XCTAssertNil(accessor.hint)
        XCTAssertNil(accessor.identifier)
        XCTAssertEqual(accessor.activationPoint, .zero)
        XCTAssertEqual(accessor.frame, .zero)
        XCTAssertNil(accessor.path)
        XCTAssertNil(accessor.userInputLabels)
        XCTAssertNil(accessor.customActions)
        XCTAssertNil(accessor.customRotors)
        XCTAssertEqual(accessor.customContent.count, 0)
    }
    
    // MARK: - iOS 17 Block-Based Tests
    
    @available(iOS 17.0, *)
    func testIsElement_PreferBlock() {
        testView.isAccessibilityElement = false
        testView.isAccessibilityElementBlock = { true }
        XCTAssertTrue(testView.accessibility.isElement)
    }
    
    @available(iOS 17.0, *)
    func testElements_PreferBlock() {
        let fallbackElements: [UIAccessibilityElement] = [.init()]
        let blockElements: [UIAccessibilityElement] = [.init()]
        testView.accessibilityElements = fallbackElements
        testView.accessibilityElementsBlock = { blockElements }
        XCTAssertEqual(testView.accessibility.elements as? [UIAccessibilityElement], blockElements )
    }
    
    @available(iOS 17.0, *)
    func testContainerType_PreferBlock() {
        testView.accessibilityContainerType = .landmark
        testView.accessibilityContainerTypeBlock = { .list }
        XCTAssertEqual(testView.accessibility.containerType, .list)
    }
    
    @available(iOS 17.0, *)
    func testLabel_PreferBlock() {
        testView.accessibilityLabel = "Fallback Label"
        testView.accessibilityLabelBlock = { "Block Label" }
        XCTAssertEqual(testView.accessibility.label, "Block Label")
    }
    
    @available(iOS 17.0, *)
    func testValue_PreferBlock() {
        testView.accessibilityValue = "Fallback Value"
        testView.accessibilityValueBlock = { "Block Value" }
        XCTAssertEqual(testView.accessibility.value, "Block Value")
    }
    
    @available(iOS 17.0, *)
    func testTraits_PreferBlock() {
        testView.accessibilityTraits = .button
        testView.accessibilityTraitsBlock = { .link }
        XCTAssertEqual(testView.accessibility.traits, .link)
    }
    
    @available(iOS 17.0, *)
    func testHint_PreferBlock() {
        testView.accessibilityHint = "Fallback Hint"
        testView.accessibilityHintBlock = { "Block Hint" }
        XCTAssertEqual(testView.accessibility.hint, "Block Hint")
    }
    
    @available(iOS 17.0, *)
    func testIdentifier_PreferBlock() {
        testView.accessibilityIdentifier = "Fallback ID"
        testView.accessibilityIdentifierBlock = { "Block ID" }
        XCTAssertEqual(testView.accessibility.identifier, "Block ID")
    }
    
    @available(iOS 17.0, *)
    func testActivationPoint_PreferBlock() {
        testView.accessibilityActivationPoint = .zero
        testView.accessibilityActivationPointBlock = { CGPoint(x: 10, y: 20) }
        XCTAssertEqual(testView.accessibility.activationPoint, CGPoint(x: 10, y: 20))
    }
    
    @available(iOS 17.0, *)
    func testFrame_PreferBlock() {
        testView.accessibilityFrame = .zero
        let blockFrame = CGRect(x: 10, y: 20, width: 100, height: 200)
        testView.accessibilityFrameBlock = { blockFrame }
        XCTAssertEqual(testView.accessibility.frame, blockFrame)
    }
    
    @available(iOS 17.0, *)
    func testPath_PreferBlock() {
        let fallbackPath = UIBezierPath(rect: CGRect(x: 0, y: 0, width: 50, height: 50))
        let blockPath = UIBezierPath(rect: CGRect(x: 10, y: 10, width: 30, height: 30))
        testView.accessibilityPath = fallbackPath
        testView.accessibilityPathBlock = { blockPath }
        XCTAssertEqual(testView.accessibility.path?.bounds, blockPath.bounds)
    }
    
    @available(iOS 17.0, *)
    func testUserInputLabels_PreferBlock() {
        testView.accessibilityUserInputLabels = ["Fallback"]
        testView.accessibilityUserInputLabelsBlock = { ["Block"] }
        XCTAssertEqual(testView.accessibility.userInputLabels, ["Block"])
    }
    
    @available(iOS 17.0, *)
    func testCustomActions_PreferBlock() {
        let fallbackAction = UIAccessibilityCustomAction(name: "Fallback", target: self, selector: #selector(dummyAction))
        let blockAction = UIAccessibilityCustomAction(name: "Block", target: self, selector: #selector(dummyAction))
        testView.accessibilityCustomActions = [fallbackAction]
        testView.accessibilityCustomActionsBlock = { [blockAction] }
        XCTAssertEqual(testView.accessibility.customActions?.first?.name, "Block")
    }
    
    @available(iOS 17.0, *)
    func testCustomRotors_PreferBlock() {
        let fallbackRotor = UIAccessibilityCustomRotor(name: "Fallback") { _ in return nil }
        let blockRotor = UIAccessibilityCustomRotor(name: "Block") { _ in return nil }
        testView.accessibilityCustomRotors = [fallbackRotor]
        testView.accessibilityCustomRotorsBlock = { [blockRotor] }
        XCTAssertEqual(testView.accessibility.customRotors?.first?.name, "Block")
    }
    
    @available(iOS 17.0, *)
    func testCustomContent_PreferBlock() {
        let fallbackContent = [AXCustomContent(label: "Fallback", value: "Value")]
        let blockContent = [AXCustomContent(label: "Block", value: "Value")]
        mockCustomContentProvider.accessibilityCustomContent = fallbackContent
        mockCustomContentProvider.accessibilityCustomContentBlock = { blockContent }
        XCTAssertNotNil(mockCustomContentProvider.accessibilityCustomContentBlock)
        XCTAssertEqual(mockCustomContentProvider.accessibility.customContent.first?.label, "Block")
    }
    
    @objc private func dummyAction() {}
}

@available(iOS 14.0, *)
private class LegacyCustomContentProvider: NSObject, AXCustomContentProvider {
    var accessibilityCustomContent: [AXCustomContent]! = []
}

@available(iOS 14.0, *)
private class MockCustomContentProvider: NSObject, AXCustomContentProvider {
    var accessibilityCustomContent: [AXCustomContent]! = []
    var accessibilityCustomContentBlock: AXCustomContentReturnBlock?
}
