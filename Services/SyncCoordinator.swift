import Foundation

actor SyncCoordinator {
    private let transport: any LightTransport
    private var lastSent: [Int: ContinuousClock.Instant] = [:]
    private let clock = ContinuousClock()
    private let minimumInterval: Duration = .milliseconds(250)

    init(transport: any LightTransport = WiZUDPTransport()) {
        self.transport = transport
    }

    func send(color: RGBColor, to light: LightConfig, brightness: Int = 80) async throws {
        guard light.enabled else { return }
        if let previous = lastSent[light.id], previous.duration(to: clock.now) < minimumInterval {
            return
        }
        let payload = try WiZCommand.color(color, brightness: brightness)
        try await transport.send(payload, toIPv4: light.ipAddress)
        lastSent[light.id] = clock.now
    }

    func synchronize(zones: [TVZone: RGBColor], lights: [LightConfig], brightness: Int = 80) async -> [Int: String] {
        var failures: [Int: String] = [:]
        for light in lights where light.enabled {
            guard let color = zones[light.zone] else { continue }
            do { try await send(color: color, to: light, brightness: brightness) }
            catch { failures[light.id] = error.localizedDescription }
        }
        return failures
    }
}
