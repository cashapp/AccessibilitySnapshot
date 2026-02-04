import UIKit

// MARK: - FocusType

/// Indicates how an element can receive keyboard focus.
public enum FocusType: Equatable {
    /// Element is focusable via standard keyboard navigation (Tab key).
    /// Uses the UIFocus system.
    case keyboardNavigation
    
    /// Element is only focusable when Full Keyboard Access is enabled.
    /// Uses the accessibility hierarchy.
    case fullKeyboardAccessOnly
}

// MARK: - FocusableElement

/// Represents a focusable UI element detected for keyboard navigation.
public struct FocusableElement: Equatable {
    /// The frame of the focusable element in the root view's coordinate space.
    public let frame: CGRect

    /// A description of the element type (e.g., "UITextField", "UIButton").
    public let elementDescription: String
    
    /// The type of focus this element supports.
    public let focusType: FocusType

    public init(frame: CGRect, elementDescription: String, focusType: FocusType = .keyboardNavigation) {
        self.frame = frame
        self.elementDescription = elementDescription
        self.focusType = focusType
    }
}

// MARK: - FocusHierarchyParser

/// Parses focusable elements from a view hierarchy for keyboard navigation.
///
/// This parser identifies two types of focusable elements:
/// 1. **Keyboard Navigation**: Elements focusable via Tab key using the UIFocus system
///    (collection view cells, custom views with canBecomeFocused, text fields)
/// 2. **Full Keyboard Access Only**: Elements that require the FKA accessibility feature
///    (standard UIControls like buttons, switches, sliders)
public enum FocusHierarchyParser {
    /// Recursively finds all focusable elements in a view hierarchy.
    ///
    /// - Parameter view: The root view to search within.
    /// - Returns: An array of `FocusableElement` objects representing all focusable views,
    ///   with frames converted to the root view's coordinate space. Elements are ordered
    ///   by their position (top-to-bottom, left-to-right).
    public static func parseFocusableElements(in view: UIView) -> [FocusableElement] {
        var elements: [FocusableElement] = []

        // Parse all focusable elements, distinguishing between focus types
        parseHierarchy(in: view, root: view, elements: &elements)

        // Sort by position: top-to-bottom, left-to-right
        elements.sort { a, b in
            if abs(a.frame.minY - b.frame.minY) > 10 {
                return a.frame.minY < b.frame.minY
            }
            return a.frame.minX < b.frame.minX
        }

        return elements
    }

    // MARK: - Private Methods

    /// Parses the view hierarchy to find focusable elements.
    private static func parseHierarchy(
        in view: UIView,
        root: UIView,
        elements: inout [FocusableElement]
    ) {
        // Skip hidden views
        guard !view.isHidden, view.alpha > 0 else { return }
        
        // Check if this is a SwiftUI hosting view
        if isHostingView(view) {
            parseSwiftUIHostingView(view, root: root, elements: &elements)
            return
        }

        // Determine focus type for this view
        if let focusType = determineFocusType(for: view) {
            let frameInRoot = root.convert(view.bounds, from: view)
            if !isFrameCovered(frameInRoot, in: elements) {
                let description = String(describing: type(of: view))
                elements.append(FocusableElement(
                    frame: frameInRoot,
                    elementDescription: description,
                    focusType: focusType
                ))
            }
            // Don't recurse into children if this view is focusable
            return
        }

        // Recursively check subviews
        for subview in view.subviews {
            parseHierarchy(in: subview, root: root, elements: &elements)
        }
    }
    
    /// Checks if a view is a SwiftUI hosting view.
    private static func isHostingView(_ view: UIView) -> Bool {
        let viewType = String(describing: type(of: view))
        return viewType.contains("HostingView") ||
               (viewType.hasPrefix("_UI") && viewType.contains("Hosting"))
    }
    
    /// Parses a SwiftUI hosting view using the UIFocusSystem.
    private static func parseSwiftUIHostingView(
        _ hostingView: UIView,
        root: UIView,
        elements: inout [FocusableElement]
    ) {
        // Query the focus system for all focusable items in this hosting view
        var focusItems = hostingView.focusItems(in: hostingView.bounds)
        
        // iOS 18+ changed where focus items are exposed - check subviews recursively
        if focusItems.isEmpty {
            func findFocusItems(in view: UIView) -> [UIFocusItem] {
                var items = view.focusItems(in: view.bounds)
                for subview in view.subviews {
                    items.append(contentsOf: findFocusItems(in: subview))
                }
                return items
            }
            focusItems = findFocusItems(in: hostingView)
        }
        
        // Build a map of focus item frames for later matching
        // This allows us to use correct focus frames for accessibility elements
        var focusFrameMap: [(frame: CGRect, canFocus: Bool)] = []
        
        // Find scroll view to get correct coordinate conversion
        func findScrollView(in view: UIView) -> UIScrollView? {
            if let sv = view as? UIScrollView { return sv }
            for sub in view.subviews {
                if let sv = findScrollView(in: sub) { return sv }
            }
            return nil
        }
        let scrollView = findScrollView(in: hostingView)
        
        // The coordinate source for focus items
        // Focus items from hosting view are in scroll content coordinates if there's a scroll view
        let coordinateSource: UIView = scrollView ?? hostingView
        
        for item in focusItems {
            // Skip segment controls children
            if let itemView = item as? UIView, itemView.superview is UISegmentedControl {
                continue
            }
            
            // Convert from scroll content coordinates (or hosting view if no scroll)
            let frameInRoot = root.convert(item.frame, from: coordinateSource)
            
            guard !frameInRoot.isEmpty else { continue }
            
                focusFrameMap.append((frame: frameInRoot, canFocus: item.canBecomeFocused))
            
            // Only add focusable items here - non-focusable will be handled via accessibility
            if item.canBecomeFocused {
                guard !isFrameCovered(frameInRoot, in: elements) else { continue }
                
                let description: String
                let itemTypeName = String(describing: type(of: item))
                if let itemView = item as? UIView {
                    description = String(describing: type(of: itemView))
                } else if itemTypeName.contains("FocusableViewResponderItem") {
                    description = "FocusableView"
                } else {
                    description = itemTypeName
                }
                
                elements.append(FocusableElement(
                    frame: frameInRoot,
                    elementDescription: description,
                    focusType: .keyboardNavigation
                ))
            }
        }
        
        // Parse accessibility elements, using focus frames when available
        parseSwiftUIAccessibility(in: hostingView, root: root, elements: &elements, focusFrameMap: focusFrameMap)
        
        // Also parse UIKit subviews within the hosting view for FKA-only controls
        // (UISegmentedControl, UISlider, UISwitch, etc.)
        parseUIKitSubviews(in: hostingView, root: root, elements: &elements)
    }
    
    /// Parses UIKit subviews within a SwiftUI hosting view for FKA-only controls.
    private static func parseUIKitSubviews(
        in view: UIView,
        root: UIView,
        elements: inout [FocusableElement]
    ) {
        for subview in view.subviews {
            // Skip scroll indicators
            let viewType = String(describing: type(of: subview))
            if viewType.contains("ScrollIndicator") {
                continue
            }
            
            // Check if this UIKit view is FKA-focusable
            if let focusType = determineFocusType(for: subview) {
                let frameInRoot = root.convert(subview.bounds, from: subview)
                if !isFrameCovered(frameInRoot, in: elements) {
                    let description = String(describing: type(of: subview))
                    elements.append(FocusableElement(
                        frame: frameInRoot,
                        elementDescription: description,
                        focusType: focusType
                    ))
                }
            }
            
            // Recurse into subviews
            parseUIKitSubviews(in: subview, root: root, elements: &elements)
        }
    }
    
    /// Parses SwiftUI accessibility elements for FKA-only focusable items.
    private static func parseSwiftUIAccessibility(
        in view: UIView,
        root: UIView,
        elements: inout [FocusableElement],
        focusFrameMap: [(frame: CGRect, canFocus: Bool)]
    ) {
        // Check accessibility elements
        if let accessibilityElements = view.accessibilityElements {
            for element in accessibilityElements {
                parseAccessibilityElement(element, root: root, elements: &elements, focusFrameMap: focusFrameMap)
            }
        }
        
        // Recurse into subviews
        for subview in view.subviews {
            parseSwiftUIAccessibility(in: subview, root: root, elements: &elements, focusFrameMap: focusFrameMap)
        }
    }
    
    /// Parses an accessibility element for FKA focusability.
    private static func parseAccessibilityElement(
        _ element: Any,
        root: UIView,
        elements: inout [FocusableElement],
        focusFrameMap: [(frame: CGRect, canFocus: Bool)]
    ) {
        guard let obj = element as? NSObject else { return }
        
        // Skip UIViews - they're handled by the main hierarchy parser
        if obj is UIView { return }

        let traits = obj.accessibilityTraits
        let respondsToInteraction = obj.accessibilityRespondsToUserInteraction
        
        let hasInteractiveTrait = traits.contains(.button) ||
            traits.contains(.link) ||
            traits.contains(.adjustable) ||
            traits.contains(.keyboardKey)

        if respondsToInteraction && hasInteractiveTrait {
            let screenFrame = obj.accessibilityFrame
            guard !screenFrame.isNull && !screenFrame.isEmpty else { return }

            // Convert from screen coordinates to root view coordinates
            var frameInRoot = root.convert(screenFrame, from: nil)
            
            // Try to find the closest matching focus frame (same X and size, closest Y)
            // Focus frames have correct coordinates, accessibility frames may have scroll offset
            let candidates = focusFrameMap.filter { focus in
                abs(focus.frame.minX - frameInRoot.minX) < 2 &&
                abs(focus.frame.width - frameInRoot.width) < 2 &&
                abs(focus.frame.height - frameInRoot.height) < 2
            }
            
            // Find the closest by Y distance
            if let matchingFocus = candidates.min(by: { a, b in
                abs(a.frame.minY - frameInRoot.minY) < abs(b.frame.minY - frameInRoot.minY)
            }) {
                // Skip if this matches a focusable item (already added as keyboard-navigation)
                if matchingFocus.canFocus {
                    return
                }
                // Use the correct frame from the focus system
                frameInRoot = matchingFocus.frame
            }
            
            guard !isFrameCovered(frameInRoot, in: elements) else { return }
            
            let description = obj.accessibilityLabel ?? String(describing: type(of: obj))
            elements.append(FocusableElement(
                frame: frameInRoot,
                elementDescription: description,
                focusType: .fullKeyboardAccessOnly
            ))
        }

        // Recursively check nested accessibility elements
        if let nestedElements = obj.accessibilityElements {
            for nested in nestedElements {
                parseAccessibilityElement(nested, root: root, elements: &elements, focusFrameMap: focusFrameMap)
            }
        }
    }

    /// Determines the focus type for a UIKit view.
    private static func determineFocusType(for view: UIView) -> FocusType? {
        guard view.isUserInteractionEnabled else { return nil }
        
        // UISegmentedControl is FKA-only
        if view is UISegmentedControl {
            return .fullKeyboardAccessOnly
        }
        
        // Check UIFocus system (Tab key navigation)
        if view.canBecomeFocused {
            return .keyboardNavigation
        }
        
        // Check first responder capability (text fields, search bars)
        if view.canBecomeFirstResponder {
            return .keyboardNavigation
        }
        
        // Check accessibility for FKA elements
        if isAccessibilityFocusable(view) {
            return .fullKeyboardAccessOnly
        }

        return nil
    }
    
    /// Checks if a view is focusable via accessibility (FKA).
    private static func isAccessibilityFocusable(_ view: UIView) -> Bool {
        let traits = view.accessibilityTraits
        
        let hasInteractiveTrait = traits.contains(.button) ||
            traits.contains(.link) ||
            traits.contains(.adjustable) ||
            traits.contains(.keyboardKey)
        
        if hasInteractiveTrait {
            return true
        }
        
        if view.isAccessibilityElement && view.accessibilityRespondsToUserInteraction {
            return true
        }
        
        return false
    }

    /// Checks if a frame is already covered by existing elements.
    private static func isFrameCovered(_ frame: CGRect, in elements: [FocusableElement]) -> Bool {
        elements.contains { existing in
            existing.frame == frame ||
            existing.frame.contains(frame) ||
            frame.contains(existing.frame) ||
            significantOverlap(existing.frame, frame)
        }
    }

    /// Checks if two frames have significant overlap.
    private static func significantOverlap(_ frame1: CGRect, _ frame2: CGRect) -> Bool {
        let intersection = frame1.intersection(frame2)
        guard !intersection.isNull else { return false }

        let intersectionArea = intersection.width * intersection.height
        let smallerArea = min(frame1.width * frame1.height, frame2.width * frame2.height)

        guard smallerArea > 0 else { return false }
        return intersectionArea / smallerArea > 0.5
    }
}
