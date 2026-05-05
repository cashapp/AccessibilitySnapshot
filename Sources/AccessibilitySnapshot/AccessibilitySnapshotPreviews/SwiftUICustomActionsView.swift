import AccessibilitySnapshotCore
import AccessibilitySnapshotParser
import SwiftUI

/// Displays an element's custom actions.
@available(iOS 16.0, *)
struct CustomActionsView: View {
    let actions: [String]
    let locale: String?

    private typealias Tokens = DesignTokens.CustomContent

    var body: some View {
        VStack(alignment: .leading, spacing: Tokens.verticalSpacing) {
            Text("↳ \(Strings.actionsAvailableText(for: locale))")
                .font(DesignTokens.Typography.secondary)
                .foregroundColor(DesignTokens.Colors.primaryText)
                .lineLimit(nil)

            ForEach(actions.indices, id: \.self) { index in
                Text("↳ \(actions[index])")
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
            "Delete",
        ],
        locale: nil
    )
    .padding()
}

@available(iOS 16.0, *)
#Preview("Multiple Actions") {
    CustomActionsView(
        actions: [
            "Delete",
            "Duplicate",
            "Share",
        ],
        locale: nil
    )
    .padding()
}
