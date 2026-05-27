import AccessibilitySnapshotCore
import SwiftUI
import UIKit

/// Builds a `UIHostingController` for the SwiftUI snapshot path that renders edge-to-edge,
/// so the parsed accessibility frames (in the un-shifted coordinate space) line up with the
/// rendered image. On iOS 16.4+ uses `safeAreaRegions = []`; on earlier iOS falls back to
/// wrapping the content in `.ignoresSafeArea()`. Scoped to the SwiftUI engine — UIKit
/// engine references already include the inset, so they get an unmodified host.
@available(iOS 13.0, *)
public func makeSwiftUIHostingController<V: SwiftUI.View>(
    for view: V,
    layoutEngine: LayoutEngine
) -> UIViewController {
    guard layoutEngine == .swiftui else {
        return UIHostingController(rootView: view)
    }
    if #available(iOS 16.4, *) {
        let host = UIHostingController(rootView: view)
        host.safeAreaRegions = []
        return host
    }
    return UIHostingController(rootView: view.ignoresSafeArea())
}
