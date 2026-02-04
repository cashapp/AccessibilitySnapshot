import SwiftUI
import SwiftUI_Experimental

@main
struct SwiftUIExperimentalDemoApp: App {
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
        .navigationTitle("SwiftUI Experimental")
    }
}

#Preview {
    NavigationStack {
        DemoListView()
    }
}
