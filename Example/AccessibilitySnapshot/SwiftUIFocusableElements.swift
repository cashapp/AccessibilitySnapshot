import SwiftUI

/// A SwiftUI view demonstrating focusable elements for testing focus overlay snapshots.
@available(iOS 15.0, *)
struct SwiftUIFocusableElements: View {
    @State private var searchText = ""
    @State private var isEnabled = true
    @State private var selectedOption = 0
    @State private var sliderValue = 50.0

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                searchSection
                gridSection
                buttonSection
                toggleSection
                pickerSection
                sliderSection
            }
            .padding()
        }
        .background(Color(UIColor.systemBackground))
    }

    // MARK: - Sections

    private var header: some View {
        VStack(spacing: 8) {
            Text("Focusable Elements")
                .font(.largeTitle)
                .frame(maxWidth: .infinity)

            Text("Use Tab key to navigate between elements")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity)
        }
    }

    private var searchSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Search")
                .font(.headline)

            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search...", text: $searchText)
            }
            .padding(8)
            .background(Color(UIColor.systemGray6))
            .cornerRadius(8)
        }
    }

    private var buttonSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Button")
                .font(.headline)

            Button(action: {
                print("Submit pressed")
            }) {
                Text("Submit")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private var toggleSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Toggle")
                .font(.headline)

            Toggle("Enable notifications", isOn: $isEnabled)
        }
    }

    private var pickerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Segmented Picker")
                .font(.headline)

            Picker("Options", selection: $selectedOption) {
                Text("Option A").tag(0)
                Text("Option B").tag(1)
                Text("Option C").tag(2)
            }
            .pickerStyle(.segmented)
        }
    }

    private var sliderSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Slider")
                .font(.headline)

            HStack {
                Text("0")
                    .font(.caption)
                Slider(value: $sliderValue, in: 0...100)
                Text("100")
                    .font(.caption)
            }
        }
    }

    private var gridSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Grid")
                .font(.headline)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(1...4, id: \.self) { index in
                    // Item 1: not accessible, not focusable -> no overlay
                    // Item 2, 4: focusable -> blue overlay
                    // Item 3: not focusable but accessible -> red overlay (FKA-only)
                    let isFocusable = (index == 2 || index == 4)
                    let isAccessibilityElement = (index != 1)
                    GridItemButton(
                        index: index,
                        isFocusable: isFocusable,
                        isAccessibilityElement: isAccessibilityElement
                    )
                }
            }
        }
    }
}

// MARK: - GridItemButton

/// A focusable button for use in the grid.
/// Styling matches the UIKit GridCell: gray background with blue text,
/// blue background with white text when focused.
@available(iOS 15.0, *)
private struct GridItemButton: View {
    let index: Int
    let isFocusable: Bool
    let isAccessibilityElement: Bool
    
    @FocusState private var isFocused: Bool
    
    // Fixed height to match Item 3 (title + subtitle + spacing + padding)
    private let cellHeight: CGFloat = 50
    
    /// Subtitle text describing item state
    private var subtitle: String? {
        if isFocusable && isAccessibilityElement {
            return nil
        }

        return [
            isFocusable ? nil : "Not focusable",
            isAccessibilityElement ? nil : "Not accessible"
        ].compactMap { $0 }
            .joined(separator: " | ")
    }
    
    var body: some View {
        VStack(spacing: 2) {
            Text("Item \(index)")
                .font(.body)
                .foregroundStyle(isFocused ? .white : Color(UIColor.systemBlue))
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(isFocused ? .white.opacity(0.8) : .secondary)
            }
        }
        .frame(maxWidth: .infinity, minHeight: cellHeight)
        .background(isFocused ? Color(UIColor.systemBlue) : Color(UIColor.systemGray5))
        .cornerRadius(8)
        .onTapGesture {
            performAction()
        }
        .focused($isFocused)
        .modifier(FocusableModifier(isFocusable: isFocusable, action: performAction))
        .modifier(AccessibilityModifier(isAccessibilityElement: isAccessibilityElement))
    }
    
    private func performAction() {
        print("Item \(index) tapped")
    }
}

/// Conditionally hides element from accessibility
@available(iOS 15.0, *)
private struct AccessibilityModifier: ViewModifier {
    let isAccessibilityElement: Bool
    
    func body(content: Content) -> some View {
        if isAccessibilityElement {
            content
                .accessibilityElement(children: .combine)
                .accessibilityAddTraits(.isButton)
        } else {
            content
                .accessibilityHidden(true)
        }
    }
}

/// Conditionally applies .focusable() and keyboard activation on iOS 17+
@available(iOS 15.0, *)
private struct FocusableModifier: ViewModifier {
    let isFocusable: Bool
    let action: () -> Void
    
    func body(content: Content) -> some View {
        if #available(iOS 17.0, *) {
            content
                .focusable(isFocusable)
                .onKeyPress(.return) {
                    action()
                    return .handled
                }
                .onKeyPress(.space) {
                    action()
                    return .handled
                }
        } else {
            content
        }
    }
}

// MARK: - Previews

@available(iOS 15.0, *)
struct SwiftUIFocusableElements_Previews: PreviewProvider {
    static var previews: some View {
        SwiftUIFocusableElements()
    }
}
