import AccessibilitySnapshotParser
import SwiftUI

/// Displays an element's custom content (SwiftUI version).
struct SwiftUICustomContentView: View {
    let content: [AccessibilityMarker.CustomContent]
    let locale: String?

    private enum Metrics {
        static let verticalSpacing: CGFloat = 2
        static let indent: CGFloat = 12
        static let font = Font.system(size: 12)
        static let boldFont = Font.system(size: 12, weight: .bold)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Metrics.verticalSpacing) {
            Text("• \(Strings.moreContentAvailableText(for: locale))")
                .font(Metrics.font)
                .foregroundColor(.black)

            ForEach(content.indices, id: \.self) { index in
                let item = content[index]
                let text = item.value.isEmpty ? item.label : "\(item.label): \(item.value)"

                Text("• \(text)")
                    .font(item.isImportant ? Metrics.boldFont : Metrics.font)
                    .foregroundColor(.black)
                    .padding(.leading, Metrics.indent)
            }
        }
    }
}
