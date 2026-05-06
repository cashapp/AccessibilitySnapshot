import FBSnapshotTestCase_Accessibility
import iOSSnapshotTestCase

@testable import AccessibilitySnapshotDemo

/// Snapshot tests for SwiftUI List with Section headers and footers.
/// These tests verify that section headers/footers are interleaved correctly
/// with their row content, matching VoiceOver's traversal order.
///
/// To validate against VoiceOver: run the corresponding SwiftUI views on a
/// device with VoiceOver enabled and swipe through elements. The snapshot
/// element order should match the VoiceOver reading order.
final class SwiftUIListSectionTests: SnapshotTestCase {
    /// iOS 17 SwiftUI List snapshots alternate between two CI renderings while
    /// preserving the same section ordering. Later runtimes are pixel-stable.
    private var iOS17ListOverallTolerance: CGFloat {
        if #available(iOS 18.0, *) {
            return 0
        }
        return 0.10
    }

    @available(iOS 15.0, *)
    func testListWithSectionHeaders() {
        SnapshotVerifyAccessibility(
            SwiftUIListWithSections(),
            size: UIScreen.main.bounds.size,
            overallTolerance: iOS17ListOverallTolerance
        )
    }

    @available(iOS 15.0, *)
    func testListWithHeadersAndFooters() {
        SnapshotVerifyAccessibility(
            SwiftUIListWithHeadersAndFooters(),
            size: UIScreen.main.bounds.size,
            overallTolerance: iOS17ListOverallTolerance
        )
    }
}
