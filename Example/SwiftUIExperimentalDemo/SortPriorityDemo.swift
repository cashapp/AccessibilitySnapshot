import SwiftUI
import SwiftUI_Experimental

struct SortPriorityDemo: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                DemoSection(
                    title: "Sort Priority",
                    description: "Control VoiceOver reading order"
                ) {
                    HStack(spacing: 16) {
                        Text("Third")
                            .padding()
                            .background(Color.red.opacity(0.2))
                            .cornerRadius(8)
                            .accessibilitySortPriority(1)

                        Text("First")
                            .padding()
                            .background(Color.green.opacity(0.2))
                            .cornerRadius(8)
                            .accessibilitySortPriority(3)

                        Text("Second")
                            .padding()
                            .background(Color.yellow.opacity(0.2))
                            .cornerRadius(8)
                            .accessibilitySortPriority(2)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Sort Priority")
    }
}

#Preview {
    NavigationStack {
        SortPriorityDemo()
    }
}
