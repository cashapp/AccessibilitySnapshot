public struct AccessibilityContainer: Hashable, Codable, Sendable {
    public enum ContainerType: Hashable, Codable, Sendable {
        case none
        case semanticGroup(label: String?, value: String?)
        case list
        case landmark
        case dataTable(rowCount: Int, columnCount: Int)
        case tabBar
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
