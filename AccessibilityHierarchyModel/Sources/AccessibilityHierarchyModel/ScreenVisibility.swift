/// Whether an element was on screen at parse time.
///
/// Only the parser has the UIKit context (scroll offsets and inset-adjusted bounds) needed to
/// compute this, so it is recorded on the element rather than derived downstream.
public enum ScreenVisibility: String, Hashable, Codable, Sendable {
    /// The element's visible frame intersects the visible region of every scrollable ancestor.
    case onscreen

    /// The element is clipped out by a scrollable ancestor (or an off-screen ancestor).
    case offscreen
}
