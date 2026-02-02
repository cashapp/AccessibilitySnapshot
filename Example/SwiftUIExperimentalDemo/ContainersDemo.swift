import SwiftUI
import SwiftUI_Experimental

struct ContainersDemo: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                DemoSection(
                    title: "Containers",
                    description: "Group related elements for navigation"
                ) {
                    VStack(spacing: 12) {
                        // Navigation container
                        HStack {
                            ForEach(["Home", "Search", "Profile"], id: \.self) { item in
                                Text(item)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.blue.opacity(0.1))
                                    .cornerRadius(8)
                            }
                        }
                        .accessibilityElement(children: .contain)
                        .accessibilityLabel("Navigation")

                        // Search field
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundStyle(.secondary)
                            Text("Search...")
                                .foregroundStyle(.secondary)
                            Spacer()
                        }
                        .padding()
                        .background(Color(.tertiarySystemBackground))
                        .cornerRadius(12)
                        .accessibilityElement(children: .combine)
                        .accessibilityAddTraits(.isSearchField)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Containers")
    }
}

#Preview {
    NavigationStack {
        ContainersDemo()
    }
}
