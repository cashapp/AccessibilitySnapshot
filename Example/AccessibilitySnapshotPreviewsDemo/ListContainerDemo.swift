import AccessibilitySnapshotPreviews
import SwiftUI

/// Exercises `accessibilityContainerType = .list`. The container type influences VoiceOver
/// rotor navigation (list items) and surfaces a "List" badge in the legend.
struct ListContainerDemo: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            DemoSection(title: "Shopping List", description: ".list container") {
                VStack(alignment: .leading, spacing: 4) {
                    Text("• Apples")
                    Text("• Bread")
                    Text("• Milk")
                    Text("• Eggs")
                }
                .accessibilityContainer(type: .list)
            }

            Spacer()
        }
        .padding()
    }
}

#Preview {
    ListContainerDemo()
        .accessibilityPreview(
            configuration: .init(viewRenderingMode: .drawHierarchyInRect, showContainers: true)
        )
}
