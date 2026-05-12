import AccessibilitySnapshotPreviews
import SwiftUI

/// Exercises `accessibilityContainerType = .landmark`. VoiceOver exposes landmarks via the
/// landmark rotor so users can skip between major page regions.
struct LandmarkContainerDemo: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            DemoSection(title: "Page header", description: ".landmark container") {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Today's News")
                        .font(.headline)
                    Text("Tap a story to read more")
                        .font(.caption)
                }
                .accessibilityContainer(type: .landmark)
            }

            DemoSection(title: "Article body", description: "another .landmark") {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Breaking story")
                    Text("Lorem ipsum dolor sit amet.")
                }
                .accessibilityContainer(type: .landmark)
            }

            Spacer()
        }
        .padding()
    }
}

#Preview {
    LandmarkContainerDemo()
        .accessibilityPreview(
            configuration: .init(viewRenderingMode: .drawHierarchyInRect, showContainers: true)
        )
}
