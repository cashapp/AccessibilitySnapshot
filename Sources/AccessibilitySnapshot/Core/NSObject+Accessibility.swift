import UIKit

extension NSObject  {
    
    private struct PrivateSelectors {
        static let traitsForKey = "_accessibilityValueForKey:"
    }
    
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
    
    // Block Based API is preferred if its set, even if it returns nil.
    struct AccessibilityAccessor {
        weak var object: NSObject?
        
        var isElement: Bool {
            if #available(iOS 17.0, *),
               let object, object.responds(to: Selector(BlockSelectors.isElement)),
               let block = object.isAccessibilityElementBlock  {
                return block()
            }
            return object?.isAccessibilityElement ?? false
        }
        
        var elements: [Any]? {
            if #available(iOS 17.0, *),
               let object, object.responds(to: Selector(BlockSelectors.elements)),
                let block = object.accessibilityElementsBlock {
                return block()
            }
            return object?.accessibilityElements
        }
        
        var containerType: UIAccessibilityContainerType {
            if #available(iOS 17.0, *) {
                if let object, object.responds(to: Selector(BlockSelectors.containerType)){

                    if let block = object.accessibilityContainerTypeBlock {
                        return block()
                    }
                }
            }
            return object?.accessibilityContainerType ?? .none
        }
        
        var label: String? {
            if #available(iOS 17.0, *),
               let object, object.responds(to: Selector(BlockSelectors.label)),
               let block = object.accessibilityLabelBlock {
                return block()
            }
            return object?.accessibilityLabel
        }
        
        var value: String? {
            if #available(iOS 17.0, *),
               let object, object.responds(to: Selector(BlockSelectors.value)),
                let block = object.accessibilityValueBlock {
                return block()
            }
            return object?.accessibilityValue
        }
        
        var traits: UIAccessibilityTraits {
            if #available(iOS 17.0, *),
               let object, object.responds(to: Selector(BlockSelectors.traits)),
               let block = object.accessibilityTraitsBlock {
                return block()
            }
            return object?.accessibilityTraits ?? .none
        }
        
        var hint: String? {
            if #available(iOS 17.0, *),
               let object, object.responds(to: Selector(BlockSelectors.hint)),
            let block = object.accessibilityHintBlock {
                return block()
            }
            return object?.accessibilityHint
        }
        
        var identifier: String? {
            if #available(iOS 17.0, *), let object,
               object.responds(to: Selector(BlockSelectors.identifier)),
               let block = object.accessibilityIdentifierBlock {
                return block()
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
            if #available(iOS 17.0, *),
               let object, object.responds(to: Selector(BlockSelectors.activationPoint)),
               let block = object.accessibilityActivationPointBlock {
                return block()
            }
            return object?.accessibilityActivationPoint ?? .zero
        }
        
        var frame: CGRect {
            if #available(iOS 17.0, *),
               let object, object.responds(to: Selector(BlockSelectors.frame)),
               let block = object.accessibilityFrameBlock  {
                return block()
            }
            return object?.accessibilityFrame ?? .zero
        }
        
        var path: UIBezierPath? {
            if #available(iOS 17.0, *),
               let object, object.responds(to: Selector(BlockSelectors.path)),
            let block = object.accessibilityPathBlock {
                return block()
            }
            return object?.accessibilityPath
        }
        
        var userInputLabels: [String]? {
            if #available(iOS 17.0, *),
               let object, object.responds(to: Selector(BlockSelectors.userInputLabels)),
            let block = object.accessibilityUserInputLabelsBlock {
                return block()
            }
            return object?.accessibilityUserInputLabels
        }
        
        var customActions: [UIAccessibilityCustomAction]? {
            if #available(iOS 17.0, *), let object,
               object.responds(to: Selector(BlockSelectors.customActions)),
            let block = object.accessibilityCustomActionsBlock {
                return block()
            }
            return object?.accessibilityCustomActions
        }
        
        var customRotors: [UIAccessibilityCustomRotor]? {
            if #available(iOS 17.0, *),
               let object, object.responds(to: Selector(BlockSelectors.customRotors)),
               let block = object.accessibilityCustomRotorsBlock {
                return block()
            }
            return object?.accessibilityCustomRotors
        }
        
        @available(iOS 14.0, *)
        var customContent: [AXCustomContent]! {
            if #available(iOS 17.0, *), 
                let provider = object as? AXCustomContentProvider,
            let block = provider.accessibilityCustomContentBlock {
                return block?() ?? provider.accessibilityCustomContent
            }
            if let provider = object as? AXCustomContentProvider {
                return provider.accessibilityCustomContent
            }
            return []
        }
    }
}
