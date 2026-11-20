import XCTest
@testable import WiZSyncBox

final class WiZSyncBoxTests: XCTestCase {
    func testHexParsing() {
        XCTAssertEqual(RGBColor.parse(hex: "#FF0080"), RGBColor(r: 255, g: 0, b: 128))
        XCTAssertNil(RGBColor.parse(hex: "#ZZZZZZ"))
    }

    func testIPv4Validation() {
        XCTAssertTrue(IPv4Validator.isValid("192.168.1.50"))
        XCTAssertFalse(IPv4Validator.isValid("192.168.1.999"))
        XCTAssertFalse(IPv4Validator.isValid("my-device.local"))
    }

    func testCommandEncoding() throws {
        let data = try WiZCommand.color(.init(r: 255, g: 0, b: 128), brightness: 80)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        XCTAssertEqual(json["method"] as? String, "setPilot")
        let params = try XCTUnwrap(json["params"] as? [String: Any])
        XCTAssertEqual(params["r"] as? Int, 255)
        XCTAssertEqual(params["b"] as? Int, 128)
        XCTAssertEqual(params["dimming"] as? Int, 80)
    }

    func testElevenLights() {
        XCTAssertEqual(DefaultConfiguration.lights().count, 11)
        XCTAssertTrue(DefaultConfiguration.lights().allSatisfy { !$0.enabled })
    }
}
