import AccessibilitySnapshotCore
import SnapshotTesting
import SwiftUI
import UIKit

public extension Snapshotting where Value == UIView, Format == UIImage {
    /// Creates a snapshot strategy that renders the view with a legend of keyboard accessibility information.
    ///
    /// This variant parses shortcuts from the view's responder chain, without category grouping.
    ///
    /// - parameter useMonochromeSnapshot: Whether or not the snapshot of the `view` should be monochrome. Using a
    /// monochrome snapshot makes it more clear where the highlighted elements are, but may make it difficult to
    /// read certain views. Defaults to `true`.
    /// - parameter showFocusOverlays: Whether to show overlays on focusable elements. Defaults to `false`.
    /// - parameter drawHierarchyInKeyWindow: Whether or not to draw the view hierachy in the key window, rather than
    /// rendering the view's layer. This enables the rendering of `UIAppearance` and `UIVisualEffect`s.
    static func keyboardAccessibilityImage(
        useMonochromeSnapshot: Bool = true,
        showFocusOverlays: Bool = false,
        drawHierarchyInKeyWindow: Bool = false
    ) -> Snapshotting {
        return Snapshotting<UIView, UIImage>.image(
            drawHierarchyInKeyWindow: drawHierarchyInKeyWindow
        ).pullback { view in
            makeSnapshotContainer(
                for: view,
                menu: nil,
                useMonochromeSnapshot: useMonochromeSnapshot,
                showFocusOverlays: showFocusOverlays,
                renderingMode: drawHierarchyInKeyWindow ? .drawHierarchyInRect : .renderLayerInContext
            )
        }
    }

    /// Creates a snapshot strategy that renders the view with a legend of keyboard shortcuts from a UIMenu.
    ///
    /// This variant uses the provided UIMenu to extract shortcuts with category grouping based on submenu titles.
    ///
    /// - parameter menu: The UIMenu containing keyboard shortcuts organized by category.
    /// - parameter useMonochromeSnapshot: Whether or not the snapshot of the `view` should be monochrome. Using a
    /// monochrome snapshot makes it more clear where the highlighted elements are, but may make it difficult to
    /// read certain views. Defaults to `true`.
    /// - parameter showFocusOverlays: Whether to show overlays on focusable elements. Defaults to `false`.
    /// - parameter drawHierarchyInKeyWindow: Whether or not to draw the view hierachy in the key window, rather than
    /// rendering the view's layer. This enables the rendering of `UIAppearance` and `UIVisualEffect`s.
    static func keyboardAccessibilityImage(
        menu: UIMenu,
        useMonochromeSnapshot: Bool = true,
        showFocusOverlays: Bool = false,
        drawHierarchyInKeyWindow: Bool = false
    ) -> Snapshotting {
        return Snapshotting<UIView, UIImage>.image(
            drawHierarchyInKeyWindow: drawHierarchyInKeyWindow
        ).pullback { view in
            makeSnapshotContainer(
                for: view,
                menu: menu,
                useMonochromeSnapshot: useMonochromeSnapshot,
                showFocusOverlays: showFocusOverlays,
                renderingMode: drawHierarchyInKeyWindow ? .drawHierarchyInRect : .renderLayerInContext
            )
        }
    }
}

public extension Snapshotting where Value == UIViewController, Format == UIImage {
    /// Creates a snapshot strategy that renders the view controller's view with a legend of keyboard accessibility information.
    ///
    /// This variant parses shortcuts from the view controller's responder chain, without category grouping.
    ///
    /// - parameter useMonochromeSnapshot: Whether or not the snapshot of the view should be monochrome. Using a
    /// monochrome snapshot makes it more clear where the highlighted elements are, but may make it difficult to
    /// read certain views. Defaults to `true`.
    /// - parameter showFocusOverlays: Whether to show overlays on focusable elements. Defaults to `false`.
    /// - parameter drawHierarchyInKeyWindow: Whether or not to draw the view hierachy in the key window, rather than
    /// rendering the view's layer. This enables the rendering of `UIAppearance` and `UIVisualEffect`s.
    static func keyboardAccessibilityImage(
        useMonochromeSnapshot: Bool = true,
        showFocusOverlays: Bool = false,
        drawHierarchyInKeyWindow: Bool = false
    ) -> Snapshotting {
        return Snapshotting<UIView, UIImage>.keyboardAccessibilityImage(
            useMonochromeSnapshot: useMonochromeSnapshot,
            showFocusOverlays: showFocusOverlays,
            drawHierarchyInKeyWindow: drawHierarchyInKeyWindow
        ).pullback { viewController in
            viewController.view
        }
    }

    /// Creates a snapshot strategy that renders the view controller's view with a legend of keyboard shortcuts from a UIMenu.
    ///
    /// This variant uses the provided UIMenu to extract shortcuts with category grouping based on submenu titles.
    ///
    /// - parameter menu: The UIMenu containing keyboard shortcuts organized by category.
    /// - parameter useMonochromeSnapshot: Whether or not the snapshot of the view should be monochrome. Using a
    /// monochrome snapshot makes it more clear where the highlighted elements are, but may make it difficult to
    /// read certain views. Defaults to `true`.
    /// - parameter showFocusOverlays: Whether to show overlays on focusable elements. Defaults to `false`.
    /// - parameter drawHierarchyInKeyWindow: Whether or not to draw the view hierachy in the key window, rather than
    /// rendering the view's layer. This enables the rendering of `UIAppearance` and `UIVisualEffect`s.
    static func keyboardAccessibilityImage(
        menu: UIMenu,
        useMonochromeSnapshot: Bool = true,
        showFocusOverlays: Bool = false,
        drawHierarchyInKeyWindow: Bool = false
    ) -> Snapshotting {
        return Snapshotting<UIView, UIImage>.keyboardAccessibilityImage(
            menu: menu,
            useMonochromeSnapshot: useMonochromeSnapshot,
            showFocusOverlays: showFocusOverlays,
            drawHierarchyInKeyWindow: drawHierarchyInKeyWindow
        ).pullback { viewController in
            viewController.view
        }
    }
}

public extension Snapshotting where Value: SwiftUI.View, Format == UIImage {
    /// Creates a snapshot strategy for SwiftUI views with keyboard accessibility information.
    ///
    /// This variant parses shortcuts from the view's responder chain, without category grouping.
    ///
    /// - parameter useMonochromeSnapshot: Whether or not the snapshot of the view should be monochrome. Using a
    /// monochrome snapshot makes it more clear where the highlighted elements are, but may make it difficult to
    /// read certain views. Defaults to `true`.
    /// - parameter showFocusOverlays: Whether to show overlays on focusable elements. Defaults to `false`.
    static func keyboardAccessibilityImage(
        useMonochromeSnapshot: Bool = true,
        showFocusOverlays: Bool = false
    ) -> Snapshotting {
        return Snapshotting<UIImage, UIImage>.image.pullback { (view: Value) in
            makeSwiftUISnapshot(view: view, menu: nil, useMonochromeSnapshot: useMonochromeSnapshot, showFocusOverlays: showFocusOverlays)
        }
    }

    /// Creates a snapshot strategy for SwiftUI views with keyboard shortcuts from a UIMenu.
    ///
    /// This variant uses the provided UIMenu to extract shortcuts with category grouping based on submenu titles.
    ///
    /// - parameter menu: The UIMenu containing keyboard shortcuts organized by category.
    /// - parameter useMonochromeSnapshot: Whether or not the snapshot of the view should be monochrome. Using a
    /// monochrome snapshot makes it more clear where the highlighted elements are, but may make it difficult to
    /// read certain views. Defaults to `true`.
    /// - parameter showFocusOverlays: Whether to show overlays on focusable elements. Defaults to `false`.
    static func keyboardAccessibilityImage(
        menu: UIMenu,
        useMonochromeSnapshot: Bool = true,
        showFocusOverlays: Bool = false
    ) -> Snapshotting {
        return Snapshotting<UIImage, UIImage>.image.pullback { (view: Value) in
            makeSwiftUISnapshot(view: view, menu: menu, useMonochromeSnapshot: useMonochromeSnapshot, showFocusOverlays: showFocusOverlays)
        }
    }
}

private func makeSwiftUISnapshot<V: SwiftUI.View>(
    view: V,
    menu: UIMenu?,
    useMonochromeSnapshot: Bool,
    showFocusOverlays: Bool
) -> UIImage {
    let hostingController = UIHostingController(rootView: view)
    let hostingView = hostingController.view!
    hostingView.bounds.size = hostingController.sizeThatFits(in: .zero)

    // Add to window to ensure responder chain is set up for keyboard shortcut discovery
    let window = UIWindow(frame: hostingView.bounds)
    window.rootViewController = hostingController
    window.makeKeyAndVisible()

    hostingView.setNeedsLayout()
    hostingView.layoutIfNeeded()

    let containerView = makeSnapshotContainer(
        for: hostingView,
        menu: menu,
        useMonochromeSnapshot: useMonochromeSnapshot,
        showFocusOverlays: showFocusOverlays,
        renderingMode: .drawHierarchyInRect
    )

    return containerView.renderToImage() ?? UIImage()
}

private func makeSnapshotContainer(
    for view: UIView,
    menu: UIMenu?,
    useMonochromeSnapshot: Bool,
    showFocusOverlays: Bool,
    renderingMode: KeyboardAccessibilitySnapshotView.ViewRenderingMode
) -> KeyboardAccessibilitySnapshotView {
    let containerView = KeyboardAccessibilitySnapshotView(
        containedView: view,
        viewRenderingMode: renderingMode,
        useMonochromeSnapshot: useMonochromeSnapshot,
        showFocusOverlays: showFocusOverlays
    )

    do {
        if let menu = menu {
            try containerView.parseKeyboardShortcuts(from: menu)
        } else {
            try containerView.parseKeyboardShortcuts()
        }
    } catch {
        fatalError("Failed to parse keyboard shortcuts: \(error)")
    }

    let size = containerView.sizeThatFits(.zero)
    containerView.frame = CGRect(origin: .zero, size: size)
    containerView.layoutIfNeeded()
    return containerView
}

private extension UIView {
    func renderToImage() -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(bounds.size, false, 0)
        defer { UIGraphicsEndImageContext() }
        drawHierarchy(in: bounds, afterScreenUpdates: true)
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}
