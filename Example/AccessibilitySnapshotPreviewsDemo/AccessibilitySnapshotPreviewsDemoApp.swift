import SwiftUI
import AccessibilitySnapshotPreviews

@main
struct AccessibilitySnapshotPreviewsDemoApp: App {
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                DemoListView()
            }
        }
    }
}

struct DemoListView: View {
    var body: some View {
        List {
            Section("Basics") {
                NavigationLink("Basic Accessibility") {
                    BasicAccessibilityDemo()
                }
            }

            Section("Advanced") {
                NavigationLink("Custom Actions") {
                    CustomActionsDemo()
                }
                NavigationLink("Custom Rotors") {
                    CustomRotorsDemo()
                }
                NavigationLink("Custom Content") {
                    CustomContentDemo()
                }
                NavigationLink("Path Shapes") {
                    PathShapesDemo()
                }
            }
        }
        .navigationTitle("Accessibility Previews")
    }
}

#Preview {
    NavigationStack {
        DemoListView()
    }
}
