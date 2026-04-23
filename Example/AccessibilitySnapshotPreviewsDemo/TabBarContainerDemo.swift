import AccessibilitySnapshotPreviews
import SwiftUI

/// Exercises the `.tabBar` accessibility trait on a custom view. VoiceOver treats the wrapped
/// content like a tab bar even though it isn't a `UITabBar`, and the legend surfaces a
/// "Tab Bar" badge.
struct TabBarContainerDemo: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            DemoSection(title: "Custom tab bar", description: "accessibilityTraits = .tabBar") {
                HStack(spacing: 24) {
                    tabItem(systemImage: "house.fill", label: "Home")
                    tabItem(systemImage: "magnifyingglass", label: "Search")
                    tabItem(systemImage: "person.fill", label: "Profile")
                }
                .accessibilityTabBar()
            }

            Spacer()
        }
        .padding()
    }

    private func tabItem(systemImage: String, label: String) -> some View {
        VStack(spacing: 2) {
            Image(systemName: systemImage)
            Text(label)
                .font(.caption2)
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
    }
}

#Preview {
    TabBarContainerDemo()
        .accessibilityPreview(
            configuration: .init(viewRenderingMode: .drawHierarchyInRect, showContainers: true)
        )
}
