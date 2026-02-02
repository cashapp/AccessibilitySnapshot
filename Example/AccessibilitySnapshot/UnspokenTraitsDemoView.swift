import SwiftUI

@available(iOS 16.0, *)
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
        }
        .frame(width: 280, height: 380)
    }

    private func traitRow(_ name: String, trait: AccessibilityTraits) -> some View {
        Text(".\(name)")
            .font(.system(size: 14, design: .monospaced))
            .frame(height: 36)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 12)
            .background(Color(UIColor.lightGray))
            .cornerRadius(8)
            .accessibilityAddTraits(trait)
    }
}

@available(iOS 16.0, *)
struct UnspokenTraitsDemoView_Previews: PreviewProvider {
    static var previews: some View {
        UnspokenTraitsDemoView()
            .previewLayout(.sizeThatFits)
    }
}
