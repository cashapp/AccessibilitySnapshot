import SwiftUI
import AccessibilitySnapshotPreviews

struct CustomActionsDemo: View {
    @State private var isFavorite = false
    @State private var isArchived = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                DemoSection(
                    title: "Custom Actions",
                    description: "VoiceOver users swipe up/down to access these actions"
                ) {
                    emailRowView
                }
            }
            .padding()
        }
        .navigationTitle("Custom Actions")
    }

    private var emailRowView: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Important Email")
                    .font(.headline)
                Text("Preview of email content...")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if isFavorite {
                Image(systemName: "star.fill")
                    .foregroundStyle(.yellow)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Important Email. Preview of email content")
        .accessibilityActions {
            Button(isFavorite ? "Remove from favorites" : "Add to favorites") {
                isFavorite.toggle()
            }
            Button("Reply") {}
            Button("Forward") {}
            Button(isArchived ? "Unarchive" : "Archive") {
                isArchived.toggle()
            }
            Button("Delete", role: .destructive) {}
        }
    }
}

#Preview {
    CustomActionsDemo()
        .accessibilityPreview()
}
