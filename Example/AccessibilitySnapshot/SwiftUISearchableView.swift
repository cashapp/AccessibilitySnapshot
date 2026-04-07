import SwiftUI

@available(iOS 16.0, *)
struct SwiftUISearchableView: View {
    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            List {
                Text("Item 1")
                Text("Item 2")
                Text("Item 3")
            }
            .navigationTitle("Searchable")
            .searchable(text: $searchText, placement: .toolbar, prompt: "Filter items")
        }
    }
}
