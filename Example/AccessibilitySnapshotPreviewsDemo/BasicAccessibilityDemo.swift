import SwiftUI
import AccessibilitySnapshotPreviews

struct BasicAccessibilityDemo: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // MARK: - Label

            DemoSection(title: "Label", description: "Text description for an element") {
                Image(systemName: "star.fill")
                    .font(.title2)
                    .foregroundStyle(.yellow)
                    .accessibilityLabel("Favorite")
            }

            // MARK: - Value

            DemoSection(title: "Value", description: "Current state or content") {
                HStack {
                    Text("Progress")
                    Spacer()
                    Text("75%")
                        .foregroundStyle(.secondary)
                }
                .accessibilityElement(children: .combine)
                .accessibilityValue("75 percent complete")
            }

            // MARK: - Hint

            DemoSection(title: "Hint", description: "What happens when activated") {
                Button("Delete") {}
                    .buttonStyle(.bordered)
                    .tint(.red)
                    .accessibilityHint("Removes this item permanently")
            }

            // MARK: - Traits

            DemoSection(title: "Traits", description: "Element type and behavior") {
                Text("Section Header")
                    .font(.headline)
                    .accessibilityAddTraits(.isHeader)
            }

            // MARK: - Input Labels

            DemoSection(title: "Input Labels", description: "Voice Control phrases") {
                Button {} label: {
                    Image(systemName: "mic.fill")
                }
                .buttonStyle(.bordered)
                .accessibilityLabel("Microphone")
                .accessibilityInputLabels(["Microphone", "Mic", "Record", "Voice"])
            }

            // MARK: - Activation Point

            DemoSection(title: "Activation Point", description: "Custom tap target") {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.blue)
                    .frame(width: 60, height: 40)
                    .overlay(
                        Circle()
                            .fill(Color.white)
                            .frame(width: 8, height: 8)
                            .offset(x: 20, y: 10)
                    )
                    .accessibilityLabel("Custom tap target")
                    .accessibilityActivationPoint(CGPoint(x: 50, y: 30))
            }

            // MARK: - Element Grouping

            DemoSection(title: "Element Grouping", description: "Combine children") {
                HStack {
                    Image(systemName: "person.circle.fill")
                        .font(.title2)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("John Doe")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text("Online")
                            .font(.caption2)
                            .foregroundStyle(.green)
                    }
                }
                .padding(8)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(8)
                .accessibilityElement(children: .combine)
            }

            Spacer()
        }
        .padding()
        .navigationTitle("Basic Accessibility")
    }
}

#Preview {
    BasicAccessibilityDemo()
        .accessibilityPreview()
}
