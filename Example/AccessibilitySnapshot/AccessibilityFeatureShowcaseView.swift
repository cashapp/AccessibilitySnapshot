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
import UIKit

@available(iOS 16.0, *)
struct AccessibilityFeatureShowcaseView: View {

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {

            // Just a label
            Text("Basic label")

            // Label and value
            HStack(spacing: 4) {
                Text("Basic label with value")
                    .bold()
                Text("Here is the value")
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text("Basic label with value"))
            .accessibilityValue(Text("Here is the value"))

            // Custom hint
            Text("Something with a hint")
                .accessibilityHint(Text("Here's the hint."))

            // Custom input labels
            Text("Custom input labels")
                .accessibilityRespondsToUserInteraction()
                .accessibilityInputLabels([Text("Custom Label 1"), Text("Another custom label")])

            // Header trait
            Text("A label marked as a header")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)

            // Button trait
            Button("Something with the button trait", action: { })

            // Link trait
            Text("Something with the link trait")
                .accessibilityAddTraits(.isLink)

            Slider(value: .constant(0.5), in: 0...1.5)
                .accessibilityLabel(Text("A slider that has the adjustable trait"))

            CustomActionFeatureCard()

            RotorTraitFeatureCard()
        }
        .navigationTitle(Text("Accessibility Snapshot Feature Showcase"))
        .padding()
    }
}

@available(iOS 16.0, *)
private struct CustomActionFeatureCard: View {
    var body: some View {
        VStack {
            Text("Three buttons combined. The latter two become accessibility custom actions")
            HStack {
                Button("Primary button") { }
                    .buttonStyle(.borderedProminent)
                Button("Reply") { }
                Button("Archive") { }
            }
        }
        .buttonStyle(.bordered)
        .accessibilityElement(children: .combine)
    }
}

@available(iOS 16.0, *)
private struct RotorTraitFeatureCard: View {

    private let flaggedEntries = [
        "Melissa — Needs approval",
        "Jordan — Missing receipt",
        "Priya — Waiting on brand review",
    ]

    let title = "A custom rotor"
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.secondary)

            ForEach(flaggedEntries, id: \.self) { entry in
                Text(entry)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(title))
        .accessibilityRotor(Text(title), entries: {
            ForEach(flaggedEntries, id: \.self) { entry in
                AccessibilityRotorEntry(entry, id: entry)
            }
        })
    }
}

#Preview {
    if #available(iOS 16.0, *) {
        AccessibilityFeatureShowcaseView()
    } else {
        Text("Not available")
    }
}
