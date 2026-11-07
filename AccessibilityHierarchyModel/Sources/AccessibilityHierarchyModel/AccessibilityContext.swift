/// The captured context used to describe an element's position in its container.
public enum AccessibilityContext: Hashable, Codable, Sendable {
    /// Header text captured from a data table, including headers outside the emitted tree.
    public struct TableHeader: Hashable, Codable, Sendable {
        public let label: String?
        public let value: String?

        public init(label: String?, value: String?) {
            self.label = label
            self.value = value
        }
    }

    @available(*, deprecated, renamed: "TableHeader")
    public typealias Header = TableHeader

    case series(index: Int, count: Int)
    case tab(index: Int, count: Int)
    case tabBarItem(index: Int, count: Int)
    case dataTableCell(
        row: Int,
        column: Int,
        width: Int,
        height: Int,
        isFirstInRow: Bool,
        rowHeaders: [TableHeader],
        columnHeaders: [TableHeader]
    )
    case listStart
    /// A singleton list receives only `listStart`.
    case listEnd
    case landmarkStart
    /// A singleton landmark receives only `landmarkStart`.
    case landmarkEnd
}
