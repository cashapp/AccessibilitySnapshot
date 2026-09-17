import FBSnapshotTestCase_Accessibility
import iOSSnapshotTestCase
import SwiftUI

@available(iOS 16.0, *)
final class LongLegendTextTests: AccessibilitySnapshotPreviewsTestCase {
    /// Wide view, so the legend is laid out below the snapshot.
    func testLongTextWithLegendBelowSnapshot() {
        SnapshotVerifyAccessibility(
            LongLegendTextDemo(),
            size: CGSize(width: 402, height: 240),
            layoutEngine: .swiftui
        )
    }

    /// Tall view, so the legend is laid out beside the snapshot in fixed width columns.
    func testLongTextWithLegendBesideSnapshot() {
        snapshotVerifyAccessibility(LongLegendTextDemo())
    }
}

@available(iOS 16.0, *)
private struct LongLegendTextDemo: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            row(label: "Mark 1 with a really long label value that probably should be handled in some way", value: "$10")
                .accessibilityHint("A really long hint that also needs more than a single line of the legend to display")

            row(label: "Mark 2", value: "$20")
                .accessibilityCustomContent("A really long custom content label", "with a really long custom content value")

            row(label: "Mark 3", value: "$50")
                .accessibilityAction(named: "A really long custom action name that needs to wrap") {}

            row(label: "Mark 4", value: "$20")
                .accessibilityInputLabels(["A really long user input label that needs to wrap", "Mark four"])
        }
        .padding()
    }

    private func row(label: String, value: String) -> some View {
        HStack {
            Text(label)
            Spacer()
            Text(value).bold()
        }
        .accessibilityElement(children: .combine)
    }
}
