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

/// Reproduces issue #129: sectioned SwiftUI Form on iOS 16+.
@available(iOS 15.0, *)
struct SwiftUIFormWithSections: View {
    var body: some View {
        Form {
            Section("Profile") {
                Text("Name: Alice")
                Text("Email: alice@example.com")
            }
            Section("Preferences") {
                Text("Language: English")
                Text("Timezone: PST")
            }
        }
    }
}

/// Reproduces issue #168: NavigationStack with toolbar and title.
@available(iOS 16.0, *)
struct SwiftUIViewWithNavigationStack: View {
    var body: some View {
        NavigationStack {
            Text("Text inside a NavigationStack")
                .navigationTitle("Navigation Stack")
                .toolbar {
                    ToolbarItem {
                        Button {
                            // no-op
                        } label: {
                            Text("Add")
                        }
                    }
                }
        }
    }
}
