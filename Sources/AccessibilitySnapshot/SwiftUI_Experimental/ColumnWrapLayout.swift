import AccessibilitySnapshotParser
import SwiftUI

/// A layout that arranges items in columns, wrapping to a new column when items exceed the available height.
/// This matches the behavior of UIKit's SnapshotAndLegendView column wrapping.
@available(iOS 16.0, *)
struct ColumnWrapLayout: Layout {
    let availableHeight: CGFloat
    let columnWidth: CGFloat
    let horizontalSpacing: CGFloat
    let verticalSpacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let columns = calculateColumns(subviews: subviews)

        guard !columns.isEmpty else {
            return .zero
        }

        let totalWidth = CGFloat(columns.count) * columnWidth + CGFloat(columns.count - 1) * horizontalSpacing
        let maxColumnHeight = columns.map { column in
            column.map { $0.height }.reduce(-verticalSpacing) { $0 + $1 + verticalSpacing }
        }.max() ?? 0

        return CGSize(width: totalWidth, height: maxColumnHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let columns = calculateColumns(subviews: subviews)

        var columnX = bounds.minX
        var subviewIndex = 0

        for column in columns {
            var y = bounds.minY

            for size in column {
                guard subviewIndex < subviews.count else { continue }

                subviews[subviewIndex].place(
                    at: CGPoint(x: columnX, y: y),
                    anchor: .topLeading,
                    proposal: ProposedViewSize(width: columnWidth, height: size.height)
                )

                y += size.height + verticalSpacing
                subviewIndex += 1
            }

            columnX += columnWidth + horizontalSpacing
        }
    }

    private func calculateColumns(subviews: Subviews) -> [[CGSize]] {
        var columns: [[CGSize]] = [[]]
        var currentColumnHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(ProposedViewSize(width: columnWidth, height: nil))
            let wouldExceedHeight = currentColumnHeight + size.height > availableHeight && !columns.last!.isEmpty

            if wouldExceedHeight {
                columns.append([size])
                currentColumnHeight = size.height + verticalSpacing
            } else {
                columns[columns.count - 1].append(size)
                currentColumnHeight += size.height + verticalSpacing
            }
        }

        return columns
    }
}
