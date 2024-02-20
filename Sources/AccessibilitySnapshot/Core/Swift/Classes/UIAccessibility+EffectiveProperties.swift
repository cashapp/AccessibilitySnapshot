//
//  Copyright 2024 Block Inc.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import UIKit

// TODO: Do the block variants automatically account for the attributed versions into the non-attributed versions?

extension NSObject {

    var effectiveIsAccessibilityElement: Bool {
        #if swift(>=5.9)
        if #available(iOS 17.0, *) {
            return isAccessibilityElementBlock?() ?? isAccessibilityElement
        } else {
            return isAccessibilityElement
        }
        #else
        return isAccessibilityElement
        #endif
    }

    var effectiveAccessibilityLabel: String? {
        #if swift(>=5.9)
        if #available(iOS 17.0, *) {
            return accessibilityLabelBlock?() ?? accessibilityLabel
        } else {
            return accessibilityLabel
        }
        #else
        return accessibilityLabel
        #endif
    }

    var effectiveAccessibilityValue: String? {
        #if swift(>=5.9)
        if #available(iOS 17.0, *) {
            return accessibilityValueBlock?() ?? accessibilityValue
        } else {
            return accessibilityValue
        }
        #else
        return accessibilityValue
        #endif
    }

    var effectiveAccessibilityHint: String? {
        #if swift(>=5.9)
        if #available(iOS 17.0, *) {
            return accessibilityHintBlock?() ?? accessibilityHint
        } else {
            return accessibilityHint
        }
        #else
        return accessibilityHint
        #endif
    }

    var effectiveAccessibilityTraits: UIAccessibilityTraits {
        #if swift(>=5.9)
        if #available(iOS 17.0, *) {
            return accessibilityTraitsBlock?() ?? accessibilityTraits
        } else {
            return accessibilityTraits
        }
        #else
        return accessibilityTraits
        #endif
    }

    var effectiveAccessibilityLanguage: String? {
        #if swift(>=5.9)
        if #available(iOS 17.0, *) {
            return accessibilityLanguageBlock?() ?? accessibilityLanguage
        } else {
            return accessibilityLanguage
        }
        #else
        return accessibilityLanguage
        #endif
    }

    var effectiveAccessibilityUserInputLabels: [String]! {
        #if swift(>=5.9)
        if #available(iOS 17.0, *) {
            return accessibilityUserInputLabelsBlock?() ?? accessibilityUserInputLabels
        } else {
            return accessibilityUserInputLabels
        }
        #else
        return accessibilityUserInputLabels
        #endif
    }

    var effectiveAccessibilityElementsHidden: Bool {
        #if swift(>=5.9)
        if #available(iOS 17.0, *) {
            return accessibilityElementsHiddenBlock?() ?? accessibilityElementsHidden
        } else {
            return accessibilityElementsHidden
        }
        #else
        return accessibilityElementsHidden
        #endif
    }

    var effectiveAccessibilityRespondsToUserInteraction: Bool {
        #if swift(>=5.9)
        if #available(iOS 17.0, *) {
            return accessibilityRespondsToUserInteractionBlock?() ?? accessibilityRespondsToUserInteraction
        } else {
            return accessibilityRespondsToUserInteraction
        }
        #else
        return accessibilityRespondsToUserInteraction
        #endif
    }

    var effectiveAccessibilityViewIsModal: Bool {
        #if swift(>=5.9)
        if #available(iOS 17.0, *) {
            return accessibilityViewIsModalBlock?() ?? accessibilityViewIsModal
        } else {
            return accessibilityViewIsModal
        }
        #else
        return accessibilityViewIsModal
        #endif
    }

    var effectiveShouldGroupAccessibilityChildren: Bool {
        #if swift(>=5.9)
        if #available(iOS 17.0, *) {
            return accessibilityShouldGroupAccessibilityChildrenBlock?() ?? shouldGroupAccessibilityChildren
        } else {
            return shouldGroupAccessibilityChildren
        }
        #else
        return shouldGroupAccessibilityChildren
        #endif
    }

    var effectiveAccessibilityElements: [Any]? {
        #if swift(>=5.9)
        if #available(iOS 17.0, *) {
            return accessibilityElementsBlock?() ?? accessibilityElements
        } else {
            return accessibilityElements
        }
        #else
        return accessibilityElements
        #endif
    }

    var effectiveAccessibilityContainerType: UIAccessibilityContainerType {
        #if swift(>=5.9)
        if #available(iOS 17.0, *) {
            return accessibilityContainerTypeBlock?() ?? accessibilityContainerType
        } else {
            return accessibilityContainerType
        }
        #else
        return accessibilityContainerType
        #endif
    }

    var effectiveAccessibilityActivationPoint: CGPoint {
        #if swift(>=5.9)
        if #available(iOS 17.0, *) {
            return accessibilityActivationPointBlock?() ?? accessibilityActivationPoint
        } else {
            return accessibilityActivationPoint
        }
        #else
        return accessibilityActivationPoint
        #endif
    }

    var effectiveAccessibilityFrame: CGRect {
        #if swift(>=5.9)
        if #available(iOS 17.0, *) {
            return accessibilityFrameBlock?() ?? accessibilityFrame
        } else {
            return accessibilityFrame
        }
        #else
        return accessibilityFrame
        #endif
    }

    var effectiveAccessibilityPath: UIBezierPath? {
        #if swift(>=5.9)
        if #available(iOS 17.0, *) {
            return accessibilityPathBlock?() ?? accessibilityPath
        } else {
            return accessibilityPath
        }
        #else
        return accessibilityPath
        #endif
    }

    var effectiveAccessibilityCustomActions: [UIAccessibilityCustomAction]? {
        #if swift(>=5.9)
        if #available(iOS 17.0, *) {
            return accessibilityCustomActionsBlock?() ?? accessibilityCustomActions
        } else {
            return accessibilityCustomActions
        }
        #else
        return accessibilityCustomActions
        #endif
    }

}
