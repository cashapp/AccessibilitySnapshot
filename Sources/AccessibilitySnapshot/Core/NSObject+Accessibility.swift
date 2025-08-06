import UIKit

@available(iOS 17.0, *)
extension NSObject  {
    
    var accessibility: AccessibilityAccessor {
        .init(object: self)
    }
    struct AccessibilityAccessor
    {
        weak var object: NSObject?
        
        var isElement: Bool {
            (object?.isAccessibilityElementBlock?() ?? object?.isAccessibilityElement) ?? false
        }
        var elements: [Any]? {
            object?.accessibilityElementsBlock?() ?? object?.accessibilityElements
        }
        var containerType: UIAccessibilityContainerType {
            (object?.accessibilityContainerTypeBlock?() ?? object?.accessibilityContainerType) ?? .none
        }
        var label: String? {
            object?.accessibilityLabelBlock?() ?? object?.accessibilityLabel
        }
        var value: String? {
            object?.accessibilityValueBlock?() ?? object?.accessibilityValue
        }
        var traits: UIAccessibilityTraits {
            (object?.accessibilityTraitsBlock?() ?? object?.accessibilityTraits) ?? .none
        }
        var hint: String? {
            object?.accessibilityHintBlock?() ?? object?.accessibilityValue
        }
        var Identifier: String? {
            object?.accessibilityIdentifierBlock?() ?? (object as? UIAccessibilityIdentification)?.accessibilityIdentifier
        }
        var activationPoint: CGPoint {
            return (object?.accessibilityActivationPointBlock?() ?? object?.accessibilityActivationPoint) ?? .zero
        }
        var frame: CGRect {
            return (object?.accessibilityFrameBlock?() ?? object?.accessibilityFrame) ?? .zero
        }
        var path: UIBezierPath? {
            return object?.accessibilityPathBlock?() ?? object?.accessibilityPath
        }
        var userInputLabels: [String]? {
            object?.accessibilityUserInputLabelsBlock?() ?? object?.accessibilityUserInputLabels
        }
        var customActions: [UIAccessibilityCustomAction]? {
            object?.accessibilityCustomActionsBlock?() ?? object?.accessibilityCustomActions
        }
        var customRotors: [UIAccessibilityCustomRotor]? {
            object?.accessibilityCustomRotorsBlock?() ?? object?.accessibilityCustomRotors
        }
        var customContent: [AXCustomContent]! {
            guard let provider = object as? AXCustomContentProvider else {  return [] }
            return provider.accessibilityCustomContentBlock??() ?? provider.accessibilityCustomContent
        }
    }
}
