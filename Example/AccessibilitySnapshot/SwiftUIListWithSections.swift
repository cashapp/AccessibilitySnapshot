import SwiftUI

/// A simple sectioned List for testing section header/footer ordering.
@available(iOS 15.0, *)
struct SwiftUIListWithSections: View {
    var body: some View {
        List {
            Section("Fruits") {
                Text("Apple")
                Text("Banana")
                Text("Cherry")
            }
            Section("Vegetables") {
                Text("Carrot")
                Text("Peas")
            }
        }
    }
}

/// A sectioned List with both headers and footers.
@available(iOS 15.0, *)
struct SwiftUIListWithHeadersAndFooters: View {
    var body: some View {
        List {
            Section {
                Text("Checking")
                Text("Savings")
            } header: {
                Text("Accounts")
            } footer: {
                Text("Tap an account to view details")
            }

            Section {
                Text("Electric")
                Text("Internet")
            } header: {
                Text("Bills")
            } footer: {
                Text("Due this month")
            }
        }
    }
}
