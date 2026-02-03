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
                NavigationLink("Input Labels") {
                    InputLabelsDemo()
                }
                NavigationLink("Activation Point") {
                    ActivationPointDemo()
                }
                NavigationLink("Sort Priority") {
                    SortPriorityDemo()
                }
                NavigationLink("Containers") {
                    ContainersDemo()
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
