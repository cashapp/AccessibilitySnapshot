import SwiftUI

/// Displays an accessibility element's description.
@available(iOS 16.0, *)
struct DescriptionView: View {
    let text: String

    var body: some View {
        Text(text)
            .font(DesignTokens.Typography.description)
            .foregroundColor(DesignTokens.Colors.primaryText)
            .lineLimit(nil)
    }
}

// MARK: - Preview

@available(iOS 17.0, *)
#Preview {
    VStack(alignment: .leading, spacing: 8) {
        DescriptionView(text: "Submit Button")
        DescriptionView(text: "A longer description that might wrap to multiple lines when the container is narrow enough")
    }
    .padding()
    .frame(width: 200)
}
