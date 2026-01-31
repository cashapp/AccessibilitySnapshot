import AccessibilitySnapshotParser
import SwiftUI

/// Displays an element's custom actions (SwiftUI version).
struct SwiftUICustomActionsView: View {
    let actions: [AccessibilityMarker.CustomAction]
    let locale: String?

    private enum Metrics {
        static let verticalSpacing: CGFloat = 2
        static let indent: CGFloat = 12
        static let font = Font.system(size: 12)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Metrics.verticalSpacing) {
            Text("• \(Strings.actionsAvailableText(for: locale))")
                .font(Metrics.font)
                .foregroundColor(.black)

            ForEach(actions.indices, id: \.self) { index in
                Text("• \(actions[index].name)")
                    .font(Metrics.font)
                    .foregroundColor(.black)
                    .padding(.leading, Metrics.indent)
            }
        }
    }
}
