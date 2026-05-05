import SwiftUI

@available(iOS 16.0, *)
struct SwiftUIDisclosureGroup: View {
    @State private var isExpanded = true
    @State private var isCollapsed = false

    var body: some View {
        List {
            DisclosureGroup("Expanded Section", isExpanded: $isExpanded) {
                Text("Item 1")
                Text("Item 2")
            }

            DisclosureGroup("Collapsed Section", isExpanded: $isCollapsed) {
                Text("Hidden Item")
            }
        }
    }
}
