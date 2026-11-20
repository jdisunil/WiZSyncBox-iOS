import Foundation

struct RGBColor: Codable, Equatable, Sendable {
    let r: UInt8
    let g: UInt8
    let b: UInt8

    static func parse(hex: String) -> RGBColor? {
        let value = hex.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")
        guard value.count == 6, let number = UInt32(value, radix: 16) else { return nil }
        return RGBColor(r: UInt8((number >> 16) & 255),
                        g: UInt8((number >> 8) & 255),
                        b: UInt8(number & 255))
    }
}

enum TVZone: String, CaseIterable, Codable, Identifiable, Sendable {
    case topLeft, top, topRight, right, bottomRight, bottom, bottomLeft, left
    var id: String { rawValue }
    var title: String {
        switch self {
        case .topLeft: "Top Left"
        case .top: "Top"
        case .topRight: "Top Right"
        case .right: "Right"
        case .bottomRight: "Bottom Right"
        case .bottom: "Bottom"
        case .bottomLeft: "Bottom Left"
        case .left: "Left"
        }
    }
}

struct LightConfig: Identifiable, Codable, Equatable, Sendable {
    let id: Int
    var name: String
    var ipAddress: String
    var zone: TVZone
    var enabled: Bool
}

enum DefaultConfiguration {
    static let zones: [TVZone] = [.topLeft, .top, .topRight, .right, .right,
                                  .bottomRight, .bottom, .bottomLeft, .left, .left, .top]
    static func lights() -> [LightConfig] {
        (1...11).map { LightConfig(id: $0, name: "Living Room \($0)", ipAddress: "",
                                   zone: zones[$0 - 1], enabled: false) }
    }
}
