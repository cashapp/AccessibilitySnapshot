import Foundation

/// A catalog entry describing a single private Apple accessibility API.
///
/// Each conformer names a selector and the Swift type its getter returns. Callers invoke the
/// selector through `NSObject.ax_private(_:)`, which resolves it safely at runtime via
/// `method(for:)` + `unsafeBitCast` for primitive returns.
///
/// KVC is deliberately avoided: plain `NSObject`s respond to some private accessibility selectors
/// but are not KVC-compliant for them, and `value(forKey:)` raises `NSUnknownKeyException`.
protocol PrivateAXSelector {
    associatedtype Return

    /// The ObjC selector name (e.g. `"_accessibilityExpandedStatus"`).
    static var name: String { get }

    /// Invokes the selector on `target`. Callers should only reach this path after
    /// `target.responds(to:)` has returned true.
    static func invoke(on target: NSObject) -> Return?
}

/// Convenience conformance for selectors returning integer primitives.
protocol PrivateAXIntSelector: PrivateAXSelector where Return == Int {}

extension PrivateAXIntSelector {
    static func invoke(on target: NSObject) -> Int? {
        let selector = NSSelectorFromString(name)
        let imp = target.method(for: selector)
        typealias Fn = @convention(c) (AnyObject, Selector) -> Int
        let fn = unsafeBitCast(imp, to: Fn.self)
        return fn(target, selector)
    }
}

/// Namespace for known private/KVC-accessed accessibility selectors. Each nested type documents
/// why we depend on it and which public API (if any) can replace it on newer OS versions.
enum PrivateAX {
    /// Reads the expanded/collapsed state of a disclosure-style element.
    ///
    /// Why we read the **private** `_accessibilityExpandedStatus` and not the public iOS 18
    /// `accessibilityExpandedStatus` property:
    ///
    /// 1. `_accessibilityExpandedStatus` is a method defined on `NSObject` (defaults to
    ///    `0`/unsupported). `SwiftUI.AccessibilityNode` overrides it for `DisclosureGroup` and
    ///    expandable list sections. VoiceOver reads this private method directly — it is the
    ///    ground truth that drives the "Expanded."/"Collapsed." announcement and the "Double
    ///    tap to collapse/expand." hint.
    ///
    /// 2. In iOS 18 Apple added a public `accessibilityExpandedStatus` property on
    ///    `UIAccessibility`. The public **setter** writes through to the private getter, so
    ///    UIKit views that set the public property still expose the value via the private
    ///    method. The public **getter**, however, reads from separate storage: it does NOT
    ///    observe overrides of the private method made by SwiftUI. For every SwiftUI
    ///    `DisclosureGroup`, the public property returns `.unsupported` while the private
    ///    method returns the real state.
    ///
    /// 3. On-device testing with VoiceOver confirmed that when the two disagree, VoiceOver
    ///    always announces based on the private value.
    ///
    /// Therefore the private method is the single source of truth for both SwiftUI and UIKit,
    /// and reading the public property would only introduce inconsistency without adding signal.
    enum ExpandedStatus: PrivateAXIntSelector {
        static let name = "_accessibilityExpandedStatus"
    }
}

extension NSObject {
    /// Invokes a catalogued private accessibility selector on this object, returning `nil` if
    /// the object does not respond to the selector.
    func ax_private<S: PrivateAXSelector>(_: S.Type) -> S.Return? {
        guard responds(to: NSSelectorFromString(S.name)) else { return nil }
        return S.invoke(on: self)
    }

    /// Resolves the element's expanded/collapsed state via `PrivateAX.ExpandedStatus`.
    var expandedStatus: AccessibilityElement.ExpandedStatus {
        guard let rawValue = ax_private(PrivateAX.ExpandedStatus.self) else {
            return .unsupported
        }
        return AccessibilityElement.ExpandedStatus(rawValue: rawValue) ?? .unsupported
    }
}
