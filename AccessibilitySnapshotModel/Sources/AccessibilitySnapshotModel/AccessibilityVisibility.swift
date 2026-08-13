/// Whether an element was on screen at parse time.
///
/// The parser always walks the full accessibility tree and stamps this flag; the decision to
/// omit off-screen elements is made later, at delivery time. Only the parser has the UIKit context
/// (scroll offsets, inset-adjusted bounds) needed to compute it, so it is recorded here rather than
/// derived downstream.
public enum AccessibilityVisibility: String, Hashable, Codable, Sendable {
    /// The element's visible frame intersects the visible region of every scrollable ancestor.
    case onscreen

    /// The element is clipped out by a scrollable ancestor (or an off-screen ancestor).
    case offscreen
}
