//
//  Copyright 2020 Square Inc.
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

import SnapshotTesting

extension Snapshotting where Value == UIView, Format == String {
    
    public enum AccessibilityFields: CaseIterable {
        case description
        case hint
        case language
        case shape
        case activationPoint
        case customActions
        
        public static var defaultFields: [AccessibilityFields] = [ .description, .hint ]
        
        internal func line(for marker: AccessibilityMarker) -> String? {
            switch self {
            case .description:
                if marker.description.isEmpty {
                    return "Description is Empty"
                }
                
                return "Description: \(marker.description)"
                
            case .hint:
                guard let hint = marker.hint, hint.isEmpty == false else {
                    return "Hint is Empty"
                }
                
                return "Hint: \(hint)"
                
            case .language:
                guard let language = marker.accessibilityLanguage, language.isEmpty == false else {
                    return "Language is Empty"
                }
                
                return "Language: \(language)"
                
            case .shape:
                switch marker.shape {
                case .frame(let frame):
                    return "Shape: Frame (x:\(frame.minX), y:\(frame.minY), w:\(frame.width), h:\(frame.height))"
                    
                case .path:
                    return "Shape: Path"
                }
                
            case .activationPoint:
                return "Activation Point: \(marker.activationPoint.x), \(marker.activationPoint.y)"
                
            case .customActions:
                if marker.customActions.isEmpty {
                    return "Custom Actions: None"
                }
                
                return "Custom Actions:\n\(marker.customActions.joined(separator: "\n"))"
            }
        }
    }
    
    /// Snapshots the approximation of the description that VoiceOver will read for the element(s) in the supplied view.
    ///
    /// By default, will capture the description and hint.
    public static var accessibilityDescription: Snapshotting {
        return accessibilityDescription()
    }
    
    /// Snapshots the approximation of the description that VoiceOver will read for the element(s) in the supplied view.
    ///
    /// - parameter fields: Which fileds do you want to be included in the snapshot? By default, will capture the description and hint.
    public static func accessibilityDescription(
        fields: [Snapshotting.AccessibilityFields] = AccessibilityFields.defaultFields
    ) -> Snapshotting<UIView, String> {
        return Snapshotting(
            pathExtension: "txt",
            diffing: .lines,
            snapshot: { view in
                
                // Force a layout pass after the view is in the hierarchy so that the conversion to screen coordinates
                // works correctly.
                view.setNeedsLayout()
                view.layoutIfNeeded()
                
                let markers = AccessibilityHierarchyParser().parseAccessibilityElements(in: view)
                
                let mapMarkerToDescription: (AccessibilityMarker) -> String = { marker in
                    let output = fields
                        .map { $0.line(for: marker) }
                        .compactMap { $0 }
                        .joined(separator: "\n")
                    
                    if output.isEmpty {
                        return "No Fields"
                    }
                    
                    return output
                }
                
                switch markers.count {
                case 0:
                    return "No Markers"
                    
                case 1:
                    return markers.map(mapMarkerToDescription).joined()
                    
                default:
                    return """
                    Found \(markers.count) marker(s)

                    \(markers.map(mapMarkerToDescription).joined(separator: "\n\n"))
                    """
                }
            }
        )
    }
    
}

extension Snapshotting where Value == UIView, Format == UIImage {

    /// Snapshots the current view with colored overlays of each accessibility element it contains, as well as an
    /// approximation of the description that VoiceOver will read for each element.
    public static var accessibilityImage: Snapshotting {
        return .accessibilityImage()
    }

    /// Snapshots the current view with colored overlays of each accessibility element it contains, as well as an
    /// approximation of the description that VoiceOver will read for each element.
    ///
    /// - parameter showActivationPoints: When to show indicators for elements' accessibility activation points.
    /// Defaults to showing activation points only when they are different than the default activation point for that
    /// element.
    /// - parameter useMonochromeSnapshot: Whether or not the snapshot of the `view` should be monochrome. Using a
    /// monochrome snapshot makes it more clear where the highlighted elements are, but may make it difficult to
    /// read certain views. Defaults to `true`.
    /// - parameter drawHierarchyInKeyWindow: Whether or not to draw the view hierachy in the key window, rather than
    /// rendering the view's layer. This enables the rendering of `UIAppearance` and `UIVisualEffect`s.
    /// - parameter markerColors: The array of colors which will be chosen from when creating the overlays
    public static func accessibilityImage(
        showActivationPoints activationPointDisplayMode: ActivationPointDisplayMode = .whenOverridden,
        useMonochromeSnapshot: Bool = true,
        drawHierarchyInKeyWindow: Bool = false,
        markerColors: [UIColor] = []
    ) -> Snapshotting {
        guard isRunningInHostApplication else {
            fatalError("Accessibility snapshot tests cannot be run in a test target without a host application")
        }

        return Snapshotting<UIView, UIImage>
            .image(drawHierarchyInKeyWindow: drawHierarchyInKeyWindow)
            .pullback { view in
                let containerView = AccessibilitySnapshotView(
                    containedView: view,
                    viewRenderingMode: drawHierarchyInKeyWindow ? .drawHierarchyInRect : .renderLayerInContext,
                    markerColors: markerColors,
                    activationPointDisplayMode: activationPointDisplayMode
                )

                let window = UIWindow(frame: UIScreen.main.bounds)
                window.makeKeyAndVisible()
                containerView.center = window.center
                window.addSubview(containerView)

                containerView.parseAccessibility(useMonochromeSnapshot: useMonochromeSnapshot)
                containerView.sizeToFit()

                return containerView
            }
    }

    /// Snapshots the current view using the specified content size category to test Dynamic Type.
    ///
    /// This method has been marked internal since it is still under development. Once it has been completed, it should
    /// be made `public`.
    ///
    /// - parameter contentSizeCategory: The content size category to use in the snapshot
    static func image(
        at contentSizeCategory: UIContentSizeCategory
    ) -> Snapshotting {
        return Snapshotting<UIView, UIImage>.image(
            traits: .init(preferredContentSizeCategory: contentSizeCategory)
        )
    }

    /// Snapshots the current view simulating the way it will appear with Smart Invert Colors enabled.
    public static var imageWithSmartInvert: Snapshotting {
       func postNotification() {
            NotificationCenter.default.post(
                name: UIAccessibility.invertColorsStatusDidChangeNotification,
                object: nil,
                userInfo: nil
            )
        }

        return Snapshotting<UIImage, UIImage>.image.pullback { view in
            let requiresWindow = (view.window == nil && !(view is UIWindow))

            if requiresWindow {
                let window = UIApplication.shared.keyWindow ?? UIWindow(frame: UIScreen.main.bounds)
                window.addSubview(view)
            }

            view.layoutIfNeeded()

            let statusUtility = UIAccessibilityStatusUtility()
            statusUtility.mockInvertColorsStatus()
            postNotification()

            let renderer = UIGraphicsImageRenderer(bounds: view.bounds)
            let image = renderer.image { context in
                view.drawHierarchyWithInvertedColors(in: view.bounds, using: context)
            }

            statusUtility.unmockStatuses()
            postNotification()

            if requiresWindow {
                view.removeFromSuperview()
            }

            return image
        }
    }

    // MARK: - Internal Properties

    internal static var isRunningInHostApplication: Bool {
        // The tests must be run in a host application in order for the accessibility properties to be populated
        // correctly. The `UIApplication.shared` singleton is non-optional, but will be uninitialized when the tests are
        // running outside of a host application, so we can use this check to determine whether we have a test host.
        let hostApplication: UIApplication? = UIApplication.shared
        return (hostApplication != nil)
    }

}

extension Snapshotting where Value == UIViewController, Format == UIImage {

    /// Snapshots the current view with colored overlays of each accessibility element it contains, as well as an
    /// approximation of the description that VoiceOver will read for each element.
    public static var accessibilityImage: Snapshotting {
        return .accessibilityImage()
    }

    /// Snapshots the current view with colored overlays of each accessibility element it contains, as well as an
    /// approximation of the description that VoiceOver will read for each element.
    ///
    /// - parameter showActivationPoints: When to show indicators for elements' accessibility activation points.
    /// Defaults to showing activation points only when they are different than the default activation point for that
    /// element.
    /// - parameter useMonochromeSnapshot: Whether or not the snapshot of the `view` should be monochrome. Using a
    /// monochrome snapshot makes it more clear where the highlighted elements are, but may make it difficult to
    /// read certain views. Defaults to `true`.
    /// - parameter drawHierarchyInKeyWindow: Whether or not to draw the view hierachy in the key window, rather than
    /// rendering the view's layer. This enables the rendering of `UIAppearance` and `UIVisualEffect`s.
    /// - parameter markerColors: The array of colors which will be chosen from when creating the overlays
    public static func accessibilityImage(
        showActivationPoints activationPointDisplayMode: ActivationPointDisplayMode = .whenOverridden,
        useMonochromeSnapshot: Bool = true,
        drawHierarchyInKeyWindow: Bool = false,
        markerColors: [UIColor] = []
    ) -> Snapshotting {
        return Snapshotting<UIView, UIImage>
            .accessibilityImage(
                showActivationPoints: activationPointDisplayMode,
                useMonochromeSnapshot: useMonochromeSnapshot,
                drawHierarchyInKeyWindow: drawHierarchyInKeyWindow,
                markerColors: markerColors
            )
            .pullback { viewController in
                viewController.view
            }
    }

    /// Snapshots the current view using the specified content size category to test Dynamic Type.
    ///
    /// This method has been marked internal since it is still under development. Once it has been completed, it should
    /// be made `public`.
    ///
    /// - parameter contentSizeCategory: The content size category to use in the snapshot
    static func image(
        at contentSizeCategory: UIContentSizeCategory
    ) -> Snapshotting {
        return Snapshotting<UIView, UIImage>
            .image(
                traits: .init(preferredContentSizeCategory: contentSizeCategory)
            )
            .pullback { viewController in
                viewController.view
            }
    }

    /// Snapshots the current view simulating the way it will appear with Smart Invert Colors enabled.
    public static var imageWithSmartInvert: Snapshotting {
        return Snapshotting<UIView, UIImage>.imageWithSmartInvert.pullback { viewController in
            viewController.view
        }
    }

}
