import UIKit

extension NSObject  {
    
    private struct LegacySelectors {
        static let identifier = "accessibilityIdentifier"
    }
    
    private struct BlockSelectors {
        static let isElement = "isAccessibilityElementBlock"
        static let elements = "accessibilityElementsBlock"
        static let containerType = "accessibilityContainerTypeBlock"
        static let label = "accessibilityLabelBlock"
        static let value = "accessibilityValueBlock"
        static let traits = "accessibilityTraitsBlock"
        static let hint = "accessibilityHintBlock"
        static let identifier = "accessibilityIdentifierBlock"
        static let activationPoint = "accessibilityActivationPointBlock"
        static let frame = "accessibilityFrameBlock"
        static let path = "accessibilityPathBlock"
        static let userInputLabels = "accessibilityUserInputLabelsBlock"
        static let customActions = "accessibilityCustomActionsBlock"
        static let customRotors = "accessibilityCustomRotorsBlock"
        static let customContent = "accessibilityCustomContentBlock"
    }
    
    var accessibility: AccessibilityAccessor {
        .init(object: self)
    }
    
    struct AccessibilityAccessor {
        weak var object: NSObject?
        
        var isElement: Bool {
            if #available(iOS 17.0, *), let object, object.responds(to: Selector(BlockSelectors.isElement)) {
                return object.isAccessibilityElementBlock?() ?? object.isAccessibilityElement
            }
            return object?.isAccessibilityElement ?? false
        }
        
        var elements: [Any]? {
            if #available(iOS 17.0, *), let object, object.responds(to: Selector(BlockSelectors.elements)) {
                return object.accessibilityElementsBlock?() ?? object.accessibilityElements
            }
            return object?.accessibilityElements
        }
        
        var containerType: UIAccessibilityContainerType {
            if #available(iOS 17.0, *), let object, object.responds(to: Selector(BlockSelectors.containerType)) {
                return object.accessibilityContainerTypeBlock?() ?? object.accessibilityContainerType
            }
            return object?.accessibilityContainerType ?? .none
        }
        
        var label: String? {
            if #available(iOS 17.0, *), let object, object.responds(to: Selector(BlockSelectors.label)) {
                return object.accessibilityLabelBlock?() ?? object.accessibilityLabel
            }
            return object?.accessibilityLabel
        }
        
        var value: String? {
            if #available(iOS 17.0, *), let object, object.responds(to: Selector(BlockSelectors.value)) {
                return object.accessibilityValueBlock?() ?? object.accessibilityValue
            }
            return object?.accessibilityValue
        }
        
        var traits: UIAccessibilityTraits {
            if #available(iOS 17.0, *), let object, object.responds(to: Selector(BlockSelectors.traits)) {
                return object.accessibilityTraitsBlock?() ?? object.accessibilityTraits
            }
            return object?.accessibilityTraits ?? .none
        }
        
        var hint: String? {
            if #available(iOS 17.0, *), let object, object.responds(to: Selector(BlockSelectors.hint)) {
                return object.accessibilityHintBlock?() ?? object.accessibilityHint
            }
            return object?.accessibilityHint
        }
        
        var identifier: String? {
            if #available(iOS 17.0, *), let object, object.responds(to: Selector(BlockSelectors.identifier)) {
                if let identifier = object.accessibilityIdentifierBlock?() {
                    return identifier
                }
            }
            if let identification = object as? UIAccessibilityIdentification {
                return identification.accessibilityIdentifier
            }
            // Despite UIAccessibilityIdentification declaring conformance on NSObject the above cast often fails on objects that have a valid identifier.
            if let object, object.responds(to: Selector(LegacySelectors.identifier)) {
                return object.perform(Selector(LegacySelectors.identifier))?.takeUnretainedValue() as? String
            }
            return nil
        }
        
        var activationPoint: CGPoint {
            if #available(iOS 17.0, *), let object, object.responds(to: Selector(BlockSelectors.activationPoint)) {
                return object.accessibilityActivationPointBlock?() ?? object.accessibilityActivationPoint
            }
            return object?.accessibilityActivationPoint ?? .zero
        }
        
        var frame: CGRect {
            if #available(iOS 17.0, *), let object, object.responds(to: Selector(BlockSelectors.frame)) {
                return object.accessibilityFrameBlock?() ?? object.accessibilityFrame
            }
            return object?.accessibilityFrame ?? .zero
        }
        
        var path: UIBezierPath? {
            if #available(iOS 17.0, *), let object, object.responds(to: Selector(BlockSelectors.path)) {
                return object.accessibilityPathBlock?() ?? object.accessibilityPath
            }
            return object?.accessibilityPath
        }
        
        var userInputLabels: [String]? {
            if #available(iOS 17.0, *), let object, object.responds(to: Selector(BlockSelectors.userInputLabels)) {
                return object.accessibilityUserInputLabelsBlock?() ?? object.accessibilityUserInputLabels
            }
            return object?.accessibilityUserInputLabels
        }
        
        var customActions: [UIAccessibilityCustomAction]? {
            if #available(iOS 17.0, *), let object, object.responds(to: Selector(BlockSelectors.customActions)) {
                return object.accessibilityCustomActionsBlock?() ?? object.accessibilityCustomActions
            }
            return object?.accessibilityCustomActions
        }
        
        var customRotors: [UIAccessibilityCustomRotor]? {
            if #available(iOS 17.0, *), let object, object.responds(to: Selector(BlockSelectors.customRotors)) {
                return object.accessibilityCustomRotorsBlock?() ?? object.accessibilityCustomRotors
            }
            return object?.accessibilityCustomRotors
        }
        
        @available(iOS 14.0, *)
        var customContent: [AXCustomContent]! {
            if #available(iOS 17.0, *), 
                let provider = object as? AXCustomContentProvider {
                return provider.accessibilityCustomContentBlock??() ?? provider.accessibilityCustomContent
            }
            if let provider = object as? AXCustomContentProvider {
                return provider.accessibilityCustomContent
            }
            return []
        }
    }
}
