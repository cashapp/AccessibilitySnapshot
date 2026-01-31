import SwiftUI

/// Displays user input labels (Voice Control) as pills.
struct UserInputLabelsView: View {
    let labels: [String]

    private enum Metrics {
        static let horizontalSpacing: CGFloat = 4
        static let verticalSpacing: CGFloat = 4
    }

    var body: some View {
        if #available(iOS 16.0, *) {
            FlowLayout(horizontalSpacing: Metrics.horizontalSpacing, verticalSpacing: Metrics.verticalSpacing) {
                ForEach(labels, id: \.self) { label in
                    PillView(title: label)
                }
            }
        } else {
            HStack(spacing: Metrics.horizontalSpacing) {
                ForEach(labels, id: \.self) { label in
                    PillView(title: label)
                }
            }
        }
    }
}

/// A single pill-shaped label.
private struct PillView: View {
    let title: String

    private enum Metrics {
        static let horizontalPadding: CGFloat = 6
        static let verticalPadding: CGFloat = 2
        static let cornerRadius: CGFloat = 6
        static let font = Font.system(size: 12)
        static let textColor = Color(white: 0.2)
        static let backgroundColor = Color(white: 0.8)
    }

    var body: some View {
        Text(title)
            .font(Metrics.font)
            .lineLimit(1)
            .foregroundColor(Metrics.textColor)
            .padding(.horizontal, Metrics.horizontalPadding)
            .padding(.vertical, Metrics.verticalPadding)
            .background(Metrics.backgroundColor)
            .cornerRadius(Metrics.cornerRadius)
    }
}

/// A layout that arranges views in horizontal lines, wrapping to new lines as needed.
@available(iOS 16.0, *)
struct FlowLayout: Layout {
    let horizontalSpacing: CGFloat
    let verticalSpacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache _: inout ()) -> CGSize {
        arrangeSubviews(proposal: proposal, subviews: subviews).size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache _: inout ()) {
        let arrangement = arrangeSubviews(proposal: proposal, subviews: subviews)
        for (index, position) in arrangement.positions.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                proposal: .unspecified
            )
        }
    }

    private func arrangeSubviews(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var maxX: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

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
