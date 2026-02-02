import SwiftUI
import SwiftUI_Experimental

struct ActivationPointDemo: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                DemoSection(
                    title: "Activation Point",
                    description: "Custom tap target location for VoiceOver"
                ) {
                    HStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.blue)
                            .frame(width: 80, height: 60)
                            .overlay(
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 12, height: 12)
                                    .offset(x: 25, y: 15)
                            )
                            .accessibilityLabel("Tap target")
                            .accessibilityActivationPoint(CGPoint(x: 65, y: 45))

                        Spacer()

                        Text("Tap activates at bottom-right dot")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Activation Point")
    }
}

#Preview {
    NavigationStack {
        ActivationPointDemo()
    }
}
