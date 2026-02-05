import SwiftUI

/// Displays an accessibility element's hint.
@available(iOS 16.0, *)
struct HintView: View {
    let text: String

    var body: some View {
        Text(text)
            .font(DesignTokens.Typography.hint)
            .foregroundColor(DesignTokens.Colors.secondaryText)
            .lineLimit(nil)
    }
}

// MARK: - Preview

@available(iOS 16.0, *)
#Preview {
    VStack(alignment: .leading, spacing: 8) {
        HintView(text: "Double tap to activate")
        HintView(text: "Swipe up or down to adjust the value")
    }
    .padding()
}
