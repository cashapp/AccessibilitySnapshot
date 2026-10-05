/// The captured context used to describe an element's position in its container.
public enum AccessibilityContext: Hashable, Codable, Sendable {
    /// Header text captured from a data table, including headers outside the emitted tree.
    public struct Header: Hashable, Codable, Sendable {
        public let label: String?
        public let value: String?

        public init(label: String?, value: String?) {
            self.label = label
            self.value = value
        }
    }

    case series(index: Int, count: Int)
    case tab(index: Int, count: Int)
    case tabBarItem(index: Int, count: Int)
    case dataTableCell(
        row: Int,
        column: Int,
        width: Int,
        height: Int,
        isFirstInRow: Bool,
        rowHeaders: [Header],
        columnHeaders: [Header]
    )
    case listStart
    /// A singleton list receives only `listStart`.
    case listEnd
    case landmarkStart
    /// A singleton landmark receives only `landmarkStart`.
    case landmarkEnd
}
