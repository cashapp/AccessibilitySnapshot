import SwiftUI
import SwiftUI_Experimental

struct BasicAccessibilityDemo: View {
    @State private var textValue = ""
    @State private var toggleValue = true
    @State private var sliderValue = 50.0

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                labelsSection
                valuesSection
                hintsSection
                traitsSection
                groupingSection
                formControlsSection
            }
            .padding()
        }
        .navigationTitle("Basic Accessibility")
    }

    // MARK: - Labels

    private var labelsSection: some View {
        DemoSection(title: "Labels", description: "Provide text descriptions for elements") {
            HStack(spacing: 24) {
                Image(systemName: "star.fill")
                    .font(.title)
                    .foregroundStyle(.yellow)
                    .accessibilityLabel("Favorite")

                Image(systemName: "heart.fill")
                    .font(.title)
                    .foregroundStyle(.red)
                    .accessibilityLabel("Like")

                Image(systemName: "bookmark.fill")
                    .font(.title)
                    .foregroundStyle(.blue)
                    .accessibilityLabel("Bookmark")
            }
        }
    }

    // MARK: - Values

    private var valuesSection: some View {
        DemoSection(title: "Values", description: "Indicate current state or content") {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Progress")
                    Spacer()
                    Text("75%")
                        .foregroundStyle(.secondary)
                }
                .accessibilityElement(children: .combine)
                .accessibilityValue("75 percent complete")

                HStack {
                    Text("Rating")
                    Spacer()
                    HStack(spacing: 2) {
                        ForEach(0 ..< 5) { i in
                            Image(systemName: i < 4 ? "star.fill" : "star")
                                .foregroundStyle(.yellow)
                        }
                    }
                }
                .accessibilityElement(children: .combine)
                .accessibilityValue("4 out of 5 stars")
            }
        }
    }

    // MARK: - Hints

    private var hintsSection: some View {
        DemoSection(title: "Hints", description: "Describe what happens when activated") {
            VStack(spacing: 12) {
                Button("Delete") {}
                    .buttonStyle(.bordered)
                    .tint(.red)
                    .accessibilityHint("Removes this item permanently")

                Button("Share") {}
                    .buttonStyle(.bordered)
                    .accessibilityHint("Opens share sheet")
            }
        }
    }

    // MARK: - Traits

    private var traitsSection: some View {
        DemoSection(title: "Traits", description: "Indicate element type and behavior") {
            VStack(alignment: .leading, spacing: 12) {
                Text("Section Header")
                    .font(.headline)
                    .accessibilityAddTraits(.isHeader)

                Button("Button Trait") {}
                    .buttonStyle(.borderedProminent)

                Image(systemName: "photo")
                    .font(.largeTitle)
                    .foregroundStyle(.secondary)
                    .accessibilityLabel("Sample image")
                    .accessibilityAddTraits(.isImage)

                Link("Link Trait", destination: URL(string: "https://example.com")!)
            }
        }
    }

    // MARK: - Grouping

    private var groupingSection: some View {
        DemoSection(title: "Element Grouping", description: "Combine or contain child elements") {
            VStack(spacing: 16) {
                // Combined
                HStack {
                    Image(systemName: "person.circle.fill")
                        .font(.title)
                    VStack(alignment: .leading) {
                        Text("John Doe")
                            .font(.headline)
                        Text("Online")
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
                .accessibilityElement(children: .combine)

                // Contained
                VStack(alignment: .leading, spacing: 8) {
                    Text("Options")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    HStack(spacing: 12) {
                        ForEach(["A", "B", "C"], id: \.self) { option in
                            Text(option)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(8)
                        }
                    }
                }
                .accessibilityElement(children: .contain)
            }
        }
    }

    // MARK: - Form Controls

    private var formControlsSection: some View {
        DemoSection(title: "Form Controls", description: "Native controls with built-in accessibility") {
            VStack(alignment: .leading, spacing: 16) {
                TextField("Username", text: $textValue)
                    .textFieldStyle(.roundedBorder)
                    .accessibilityHint("Enter your username")

                Toggle("Enable notifications", isOn: $toggleValue)

                VStack(alignment: .leading, spacing: 4) {
                    Slider(value: $sliderValue, in: 0 ... 100)
                        .accessibilityLabel("Volume")
                        .accessibilityValue("\(Int(sliderValue)) percent")
                    Text("Volume: \(Int(sliderValue))%")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        BasicAccessibilityDemo()
    }
}
