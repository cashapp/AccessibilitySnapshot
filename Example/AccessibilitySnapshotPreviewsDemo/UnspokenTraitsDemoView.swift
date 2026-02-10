import AccessibilitySnapshotPreviews
import SwiftUI

struct UnspokenTraitsDemoView: View {
    var body: some View {
        VStack {
            traitRow("isKeyboardKey", trait: .isKeyboardKey)
            traitRow("allowsDirectInteraction", trait: .allowsDirectInteraction)
            traitRow("updatesFrequently", trait: .updatesFrequently)
            traitRow("causesPageTurn", trait: .causesPageTurn)
            traitRow("playsSound", trait: .playsSound)
            traitRow("startsMediaSession", trait: .startsMediaSession)
            traitRow("isSummaryElement", trait: .isSummaryElement)
            if #available(iOS 17.0, *) {
                label("supportsZoom")
                    .accessibilityZoomAction { _ in }
            }
        }
        .frame(width: 280, height: 420)
    }

    private func traitRow(_ name: String, trait: AccessibilityTraits) -> some View {
        label(name)
            .accessibilityAddTraits(trait)
    }

    private func label(_ string: String) -> some View {
        Text(".\(string)")
            .font(.system(size: 14, design: .monospaced))
            .frame(height: 36)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 12)
            .background(Color(UIColor.lightGray))
            .cornerRadius(8)
    }
}

#Preview {
    UnspokenTraitsDemoView()
        .accessibilityPreview()
}
