import Foundation

/// A catalog entry describing a single private/KVC-accessed Apple accessibility API.
///
/// Each conformer names a selector and the Swift type its getter returns. Callers invoke the
/// selector through `NSObject.ax_private(_:)`, which resolves it safely at runtime — using
/// `method(for:)` + `unsafeBitCast` for primitive returns and `perform(_:)` for object returns.
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

/// Convenience conformance for selectors returning Objective-C objects.
protocol PrivateAXObjectSelector: PrivateAXSelector where Return: AnyObject {}

extension PrivateAXObjectSelector {
    static func invoke(on target: NSObject) -> Return? {
        let selector = NSSelectorFromString(name)
        return target.perform(selector)?.takeUnretainedValue() as? Return
    }
}

/// Namespace for known private/KVC-accessed accessibility selectors. Each nested type documents
/// why we depend on it and which public API (if any) can replace it on newer OS versions.
enum PrivateAX {
    /// Reads the expanded/collapsed state of a disclosure-style element.
    ///
    /// `_accessibilityExpandedStatus` is defined on `NSObject` (defaults to 0/unsupported) and
    /// was first given meaningful values by `SwiftUI.AccessibilityNode` in iOS 14.2 for
    /// `DisclosureGroup`. In iOS 18 Apple added a public `accessibilityExpandedStatus` property,
    /// but SwiftUI still only populates the private one — so this private selector remains the
    /// single source of truth for both SwiftUI and UIKit.
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
