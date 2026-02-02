import AccessibilitySnapshotCore
import AccessibilitySnapshotParser
import SwiftUI

/// Displays an element's custom content.
@available(iOS 18.0, *)
struct CustomContentView: View {
    let content: [AccessibilityMarker.CustomContent]
    let locale: String?

    private typealias Tokens = DesignTokens.CustomContent

    var body: some View {
        VStack(alignment: .leading, spacing: Tokens.verticalSpacing) {
            Text("↳ \(Strings.moreContentAvailableText(for: locale))")
                .font(DesignTokens.Typography.secondary)
                .foregroundColor(DesignTokens.Colors.primaryText)
                .lineLimit(nil)

            ForEach(content.indices, id: \.self) { index in
                let item = content[index]
                let text = item.value.isEmpty ? item.label : "\(item.label): \(item.value)"

                Text("↳ \(text)")
                    .font(item.isImportant ? DesignTokens.Typography.secondaryBold : DesignTokens.Typography.secondary)
                    .foregroundColor(DesignTokens.Colors.primaryText)
                    .lineLimit(nil)
                    .padding(.leading, Tokens.indent)
            }
        }
    }
}

// MARK: - Preview

@available(iOS 18.0, *)
#Preview("Single Content") {
    CustomContentView(
        content: [
            .init(label: "Price", value: "$19.99"),
        ],
        locale: nil
    )
    .padding()
}

@available(iOS 18.0, *)
#Preview("Multiple Content Items") {
    CustomContentView(
        content: [
            .init(label: "Price", value: "$19.99"),
            .init(label: "Rating", value: "4.5 stars", isImportant: true),
            .init(label: "In Stock", value: "Yes"),
        ],
        locale: nil
    )
    .padding()
}

@available(iOS 18.0, *)
#Preview("Label Only") {
    CustomContentView(
        content: [
            .init(label: "Limited Edition", value: "", isImportant: true),
        ],
        locale: nil
    )
    .padding()
}
