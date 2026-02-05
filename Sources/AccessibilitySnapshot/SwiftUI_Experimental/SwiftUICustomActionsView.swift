import AccessibilitySnapshotCore
import AccessibilitySnapshotParser
import SwiftUI

/// Displays an element's custom actions.
@available(iOS 16.0, *)
struct CustomActionsView: View {
    let actions: [AccessibilityMarker.CustomAction]
    let locale: String?

    private typealias Tokens = DesignTokens.CustomContent

    var body: some View {
        VStack(alignment: .leading, spacing: Tokens.verticalSpacing) {
            Text("↳ \(Strings.actionsAvailableText(for: locale))")
                .font(DesignTokens.Typography.secondary)
                .foregroundColor(DesignTokens.Colors.primaryText)
                .lineLimit(nil)

            ForEach(actions.indices, id: \.self) { index in
                Text("↳ \(actions[index].name)")
                    .font(DesignTokens.Typography.secondary)
                    .foregroundColor(DesignTokens.Colors.primaryText)
                    .lineLimit(nil)
                    .padding(.leading, Tokens.indent)
            }
        }
    }
}

// MARK: - Preview

@available(iOS 16.0, *)
#Preview("Single Action") {
    CustomActionsView(
        actions: [
            .init(name: "Delete"),
        ],
        locale: nil
    )
    .padding()
}

@available(iOS 16.0, *)
#Preview("Multiple Actions") {
    CustomActionsView(
        actions: [
            .init(name: "Delete"),
            .init(name: "Duplicate"),
            .init(name: "Share"),
        ],
        locale: nil
    )
    .padding()
}
