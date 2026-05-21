public struct AccessibilityContainer: Hashable, Codable, Sendable {
    public enum ContainerType: Hashable, Codable, Sendable {
        case semanticGroup(label: String?, value: String?, identifier: String?)
        case list
        case landmark
        case dataTable(rowCount: Int, columnCount: Int)
        case tabBar
    }

    public let type: ContainerType
    public let frame: AccessibilityRect

    public init(type: ContainerType, frame: AccessibilityRect) {
        self.type = type
        self.frame = frame
    }
}
