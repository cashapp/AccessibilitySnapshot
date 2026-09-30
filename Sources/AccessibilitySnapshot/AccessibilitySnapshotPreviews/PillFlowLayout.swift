import SwiftUI

/// A layout that arranges pill-shaped views in horizontal lines, wrapping to new lines as needed.
/// Used for traits badges and input labels in the accessibility legend.
@available(iOS 16.0, *)
public struct PillFlowLayout: Layout {
    let horizontalSpacing: CGFloat
    let verticalSpacing: CGFloat

    public init(horizontalSpacing: CGFloat, verticalSpacing: CGFloat) {
        self.horizontalSpacing = horizontalSpacing
        self.verticalSpacing = verticalSpacing
    }

    public func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache _: inout ()) -> CGSize {
        arrangeSubviews(proposal: proposal, subviews: subviews).size
    }

    public func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache _: inout ()) {
        let arrangement = arrangeSubviews(proposal: proposal, subviews: subviews)
        for (index, position) in arrangement.positions.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                proposal: pillProposal(for: proposal)
            )
        }
    }

    /// Constrains each pill to the available width so that a pill too wide for one line wraps its
    /// text over multiple lines instead of being truncated or clipped.
    private func pillProposal(for proposal: ProposedViewSize) -> ProposedViewSize {
        return .init(width: proposal.width, height: nil)
    }

    private func arrangeSubviews(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var maxX: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(pillProposal(for: proposal))

            if currentX + size.width > maxWidth, currentX > 0 {
                currentX = 0
                currentY += lineHeight + verticalSpacing
                lineHeight = 0
            }

            positions.append(CGPoint(x: currentX, y: currentY))
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + horizontalSpacing
            maxX = max(maxX, currentX - horizontalSpacing)
        }

        return (CGSize(width: maxX, height: currentY + lineHeight), positions)
    }
}
