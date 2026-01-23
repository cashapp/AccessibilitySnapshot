import SwiftUI

// MARK: - SwiftUI View with Uncategorized Shortcuts

/// A SwiftUI view demonstrating keyboard shortcuts without categories.
/// Uses the standard .keyboardShortcut() modifier on buttons.
@available(iOS 14.0, *)
struct SwiftUIKeyboardShortcuts: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("⌨️")
                .font(.system(size: 64))

            Text("SwiftUI Keyboard Shortcuts")
                .font(.headline)

            Text("Press ⌘ to see available shortcuts")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(UIColor.systemBackground))
        .background(shortcutButtons)
    }

    @ViewBuilder
    private var shortcutButtons: some View {
        VStack(spacing: 0) {
            Button("New") {}
                .keyboardShortcut("n", modifiers: .command)
            Button("Open") {}
                .keyboardShortcut("o", modifiers: .command)
            Button("Save") {}
                .keyboardShortcut("s", modifiers: .command)
            Button("Copy") {}
                .keyboardShortcut("c", modifiers: .command)
            Button("Paste") {}
                .keyboardShortcut("v", modifiers: .command)
            Button("Paste Special") {}
                .keyboardShortcut("v", modifiers: [.command, .shift, .option])
        }
        .opacity(0)
        .allowsHitTesting(false)
    }
}

// MARK: - Previews

@available(iOS 14.0, *)
struct SwiftUIKeyboardShortcuts_Previews: PreviewProvider {
    static var previews: some View {
        SwiftUIKeyboardShortcuts()
    }
}
