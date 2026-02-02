import SwiftUI
import UIKit

/// Displays trait icons as pills matching the UserInputLabelsView style.
@available(iOS 18.0, *)
struct TraitsView: View {
    let traits: UIAccessibilityTraits

    private typealias Tokens = DesignTokens.TraitPill

    private var displayableTraits: [UnspokenTrait] {
        UnspokenTrait.from(traits)
    }

    var body: some View {
        if !displayableTraits.isEmpty {
            PillFlowLayout(horizontalSpacing: Tokens.horizontalSpacing, verticalSpacing: Tokens.verticalSpacing) {
                ForEach(displayableTraits, id: \.self) { trait in
                    TraitPillView(trait: trait)
                }
            }
        }
    }
}

/// A single pill containing a trait icon and name.
@available(iOS 18.0, *)
private struct TraitPillView: View {
    let trait: UnspokenTrait

    private typealias Tokens = DesignTokens.TraitPill

    var body: some View {
        HStack(spacing: Tokens.iconTextSpacing) {
            Image(systemName: trait.iconName)
            Text(trait.displayName)
        }
        .font(DesignTokens.Typography.traitPill)
        .foregroundColor(DesignTokens.Colors.pillText)
        .padding(.horizontal, Tokens.horizontalPadding)
        .padding(.vertical, Tokens.verticalPadding)
        .background(DesignTokens.Colors.pillBackground)
        .cornerRadius(Tokens.cornerRadius)
        .accessibilityElement(children: .combine)
    }
}

/// Represents accessibility traits that are visually indicated in the legend.
/// These are traits that VoiceOver doesn't verbally announce.
@available(iOS 18.0, *)
enum UnspokenTrait: CaseIterable {
    case keyboardKey
    case allowsDirectInteraction
    case updatesFrequently
    case causesPageTurn
    case playsSound
    case startsMediaSession
    case summaryElement
    case supportsZoom

    /// The SF Symbol name for this trait.
    var iconName: String {
        switch self {
        case .keyboardKey: return "keyboard"
        case .allowsDirectInteraction: return "hand.point.up.fill"
        case .updatesFrequently: return "arrow.clockwise"
        case .causesPageTurn: return "doc.text"
        case .playsSound: return "speaker.wave.2.fill"
        case .startsMediaSession: return "play.fill"
        case .summaryElement: return "light.max"
        case .supportsZoom: return "plus.magnifyingglass"
        }
    }

    /// The display name for this trait (used for accessibility label).
    var displayName: String {
        switch self {
        case .keyboardKey: return "Keyboard Key"
        case .allowsDirectInteraction: return "Direct Interaction"
        case .updatesFrequently: return "Updates Frequently"
        case .causesPageTurn: return "Page Turn"
        case .playsSound: return "Plays Sound"
        case .startsMediaSession: return "Starts Media"
        case .summaryElement: return "Summary"
        case .supportsZoom: return "Supports Zoom"
        }
    }

    /// The corresponding UIAccessibilityTraits value.
    var uiTrait: UIAccessibilityTraits {
        switch self {
        case .keyboardKey: return .keyboardKey
        case .allowsDirectInteraction: return .allowsDirectInteraction
        case .updatesFrequently: return .updatesFrequently
        case .causesPageTurn: return .causesPageTurn
        case .playsSound: return .playsSound
        case .startsMediaSession: return .startsMediaSession
        case .summaryElement: return .summaryElement
        case .supportsZoom: return .supportsZoom
        }
    }

    /// Extracts displayable traits from a UIAccessibilityTraits value.
    static func from(_ traits: UIAccessibilityTraits) -> [UnspokenTrait] {
        allCases.filter { traits.contains($0.uiTrait) }
    }
}

// MARK: - Preview

@available(iOS 18.0, *)
#Preview("Single Trait") {
    TraitsView(traits: .playsSound)
        .padding()
}

@available(iOS 18.0, *)
#Preview("Multiple Traits") {
    TraitsView(traits: [.playsSound, .startsMediaSession, .causesPageTurn])
        .padding()
        .frame(width: 200)
}

@available(iOS 18.0, *)
#Preview("All Unspoken Traits") {
    TraitsView(traits: [
        .keyboardKey,
        .allowsDirectInteraction,
        .updatesFrequently,
        .causesPageTurn,
        .playsSound,
        .startsMediaSession,
        .summaryElement,
        .supportsZoom,
    ])
    .padding()
    .frame(width: 250)
}
