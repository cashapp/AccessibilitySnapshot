public struct AccessibilityContainer: Hashable, Codable, Sendable {
    public enum ContainerType: Hashable, Codable, Sendable {
        case semanticGroup(label: String?, value: String?, identifier: String?)
        case list
        case landmark
        case dataTable(rowCount: Int, columnCount: Int)
        case tabBar
        case scrollable(contentSize: AccessibilitySize)
    }

    public let type: ContainerType
    public let frame: AccessibilityRect
    public let isModalBoundary: Bool
    public let customActions: [AccessibilityElement.CustomAction]

    public init(type: ContainerType, frame: AccessibilityRect, isModalBoundary: Bool = false, customActions: [AccessibilityElement.CustomAction] = []) {
        self.type = type
        self.frame = frame
        self.isModalBoundary = isModalBoundary
        self.customActions = customActions
    }
}
