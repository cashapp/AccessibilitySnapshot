public struct AccessibilityContainer: Hashable, Codable, Sendable {
    public enum ContainerType: Hashable, Codable, Sendable {
        case none
        case semanticGroup(label: String?, value: String?)
        case list
        case landmark
        case dataTable(rowCount: Int, columnCount: Int, cells: [DataTableCellInfo?])
        case tabBar
        case scrollable(contentSize: AccessibilitySize)
    }

    /// Per-cell grid facts captured once at parse time and stored on the `.dataTable` container so
    /// that cell context ("Row 2. Column 1. Spans 2 rows.", header prefixes) can be derived at
    /// delivery from the graph alone — no live `UIAccessibilityContainerDataTable` access.
    ///
    /// Entries are positionally aligned with the container node's ordered `children`; a `nil`
    /// entry marks a child that is not a data-table cell. Header references are stored as indices
    /// into that same `children` array (headers are themselves cells), never as object references.
    ///
    /// `isFirstInRow` and the header index lists are the *already-filtered* results the parser
    /// computed from the live table (honoring the `NSNotFound` and immediately-preceding-header
    /// rules); they are stored verbatim rather than re-derived from coordinates at delivery.
    public struct DataTableCellInfo: Hashable, Codable, Sendable {
        public let row: Int
        public let column: Int
        public let rowSpan: Int
        public let columnSpan: Int
        public let isFirstInRow: Bool
        public let rowHeaderChildIndices: [Int]
        public let columnHeaderChildIndices: [Int]

        public init(
            row: Int,
            column: Int,
            rowSpan: Int,
            columnSpan: Int,
            isFirstInRow: Bool,
            rowHeaderChildIndices: [Int],
            columnHeaderChildIndices: [Int]
        ) {
            self.row = row
            self.column = column
            self.rowSpan = rowSpan
            self.columnSpan = columnSpan
            self.isFirstInRow = isFirstInRow
            self.rowHeaderChildIndices = rowHeaderChildIndices
            self.columnHeaderChildIndices = columnHeaderChildIndices
        }
    }

    public let type: ContainerType
    public let identifier: String?
    public let scrollableContentSize: AccessibilitySize?
    public let frame: AccessibilityRect
    public let isModalBoundary: Bool
    public let customActions: [AccessibilityElement.CustomAction]

    public init(
        type: ContainerType,
        identifier: String? = nil,
        scrollableContentSize: AccessibilitySize? = nil,
        frame: AccessibilityRect,
        isModalBoundary: Bool = false,
        customActions: [AccessibilityElement.CustomAction] = []
    ) {
        self.type = type
        self.identifier = identifier
        self.scrollableContentSize = scrollableContentSize
        self.frame = frame
        self.isModalBoundary = isModalBoundary
        self.customActions = customActions
    }
}

// MARK: - ContainerType Codable (wire-compatible with pre-`cells` payloads)

// Swift's synthesized enum `Codable` encodes each case under a key named for the case, with the
// associated values as a nested keyed container. Adding the `cells` associated value to
// `.dataTable` would make the synthesized decoder require a `cells` key, breaking payloads written
// before it existed. This hand-rolled conformance mirrors the synthesized shape for every case and
// defaults `cells` to `[]` when the key is absent.
extension AccessibilityContainer.ContainerType {
    private enum CodingKeys: String, CodingKey {
        case none
        case semanticGroup
        case list
        case landmark
        case dataTable
        case tabBar
        case scrollable
    }

    private enum SemanticGroupKeys: String, CodingKey {
        case label
        case value
    }

    private enum DataTableKeys: String, CodingKey {
        case rowCount
        case columnCount
        case cells
    }

    private enum ScrollableKeys: String, CodingKey {
        case contentSize
    }

    private struct EmptyPayload: Codable {}

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        guard let key = container.allKeys.first else {
            throw DecodingError.dataCorrupted(
                .init(codingPath: decoder.codingPath, debugDescription: "No container type key found")
            )
        }
        switch key {
        case .none:
            self = .none
        case .semanticGroup:
            let nested = try container.nestedContainer(keyedBy: SemanticGroupKeys.self, forKey: .semanticGroup)
            self = try .semanticGroup(
                label: nested.decodeIfPresent(String.self, forKey: .label),
                value: nested.decodeIfPresent(String.self, forKey: .value)
            )
        case .list:
            self = .list
        case .landmark:
            self = .landmark
        case .dataTable:
            let nested = try container.nestedContainer(keyedBy: DataTableKeys.self, forKey: .dataTable)
            self = try .dataTable(
                rowCount: nested.decode(Int.self, forKey: .rowCount),
                columnCount: nested.decode(Int.self, forKey: .columnCount),
                cells: nested.decodeIfPresent([AccessibilityContainer.DataTableCellInfo?].self, forKey: .cells) ?? []
            )
        case .tabBar:
            self = .tabBar
        case .scrollable:
            let nested = try container.nestedContainer(keyedBy: ScrollableKeys.self, forKey: .scrollable)
            self = try .scrollable(contentSize: nested.decode(AccessibilitySize.self, forKey: .contentSize))
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .none:
            try container.encode(EmptyPayload(), forKey: .none)
        case let .semanticGroup(label, value):
            var nested = container.nestedContainer(keyedBy: SemanticGroupKeys.self, forKey: .semanticGroup)
            try nested.encodeIfPresent(label, forKey: .label)
            try nested.encodeIfPresent(value, forKey: .value)
        case .list:
            _ = container.nestedContainer(keyedBy: SemanticGroupKeys.self, forKey: .list)
        case .landmark:
            _ = container.nestedContainer(keyedBy: SemanticGroupKeys.self, forKey: .landmark)
        case let .dataTable(rowCount, columnCount, cells):
            var nested = container.nestedContainer(keyedBy: DataTableKeys.self, forKey: .dataTable)
            try nested.encode(rowCount, forKey: .rowCount)
            try nested.encode(columnCount, forKey: .columnCount)
            try nested.encode(cells, forKey: .cells)
        case .tabBar:
            _ = container.nestedContainer(keyedBy: SemanticGroupKeys.self, forKey: .tabBar)
        case let .scrollable(contentSize):
            var nested = container.nestedContainer(keyedBy: ScrollableKeys.self, forKey: .scrollable)
            try nested.encode(contentSize, forKey: .contentSize)
        }
    }
}
