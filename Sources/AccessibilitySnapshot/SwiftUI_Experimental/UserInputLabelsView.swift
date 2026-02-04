import SwiftUI

/// Displays user input labels (Voice Control) as pills.
@available(iOS 16.0, *)
struct UserInputLabelsView: View {
    let labels: [String]

    private typealias Tokens = DesignTokens.Pill

    var body: some View {
        PillFlowLayout(horizontalSpacing: Tokens.horizontalSpacing, verticalSpacing: Tokens.verticalSpacing) {
            ForEach(labels, id: \.self) { label in
                PillView(title: label)
            }
        }
    }
}

/// A single pill-shaped label.
@available(iOS 16.0, *)
private struct PillView: View {
    let title: String

    private typealias Tokens = DesignTokens.Pill

    var body: some View {
        Text(title)
            .font(DesignTokens.Typography.pill)
            .foregroundColor(DesignTokens.Colors.pillText)
            .padding(.horizontal, Tokens.horizontalPadding)
            .padding(.vertical, Tokens.verticalPadding)
            .background(DesignTokens.Colors.pillBackground)
            .cornerRadius(Tokens.cornerRadius)
    }
}

// MARK: - Preview

@available(iOS 17.0, *)
#Preview("Single Label") {
    UserInputLabelsView(labels: ["Submit"])
        .padding()
}

@available(iOS 17.0, *)
#Preview("Multiple Labels") {
    UserInputLabelsView(labels: ["Submit", "Cancel", "Save Draft"])
        .padding()
        .frame(width: 200)
}

@available(iOS 17.0, *)
#Preview("Wrapping Labels") {
    UserInputLabelsView(labels: ["Tap here", "Press button", "Click me", "Submit form", "Cancel"])
        .padding()
        .frame(width: 180)
}
