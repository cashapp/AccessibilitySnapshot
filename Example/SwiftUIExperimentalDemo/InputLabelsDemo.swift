import SwiftUI
import SwiftUI_Experimental

struct InputLabelsDemo: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                DemoSection(
                    title: "User Input Labels",
                    description: "Voice Control users can speak these labels to activate elements"
                ) {
                    HStack(spacing: 16) {
                        Button {} label: {
                            Image(systemName: "mic.fill")
                                .font(.title2)
                        }
                        .accessibilityLabel("Microphone")
                        .accessibilityInputLabels(["Microphone", "Mic", "Record", "Voice"])

                        Button {} label: {
                            Image(systemName: "camera.fill")
                                .font(.title2)
                        }
                        .accessibilityLabel("Camera")
                        .accessibilityInputLabels(["Camera", "Photo", "Take picture", "Snap"])

                        Button {} label: {
                            Image(systemName: "square.and.arrow.up")
                                .font(.title2)
                        }
                        .accessibilityLabel("Share")
                        .accessibilityInputLabels(["Share", "Send", "Export"])
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding()
        }
        .navigationTitle("Input Labels")
    }
}

#Preview {
    NavigationStack {
        InputLabelsDemo()
    }
}
