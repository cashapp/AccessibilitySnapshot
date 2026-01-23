//
//  Copyright 2024 Block Inc.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

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
