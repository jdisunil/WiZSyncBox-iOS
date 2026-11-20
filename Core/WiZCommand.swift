import Foundation

enum WiZCommand {
    struct SetPilot: Encodable {
        let method = "setPilot"
        let params: Params
        struct Params: Encodable {
            let state: Bool
            let r: Int
            let g: Int
            let b: Int
            let dimming: Int
        }
    }

    static func color(_ color: RGBColor, brightness: Int) throws -> Data {
        let message = SetPilot(params: .init(state: true, r: Int(color.r),
                                             g: Int(color.g), b: Int(color.b),
                                             dimming: min(100, max(10, brightness))))
        return try JSONEncoder().encode(message)
    }
}
