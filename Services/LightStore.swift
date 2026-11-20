import Foundation

@MainActor
final class LightStore: ObservableObject {
    @Published var lights: [LightConfig] {
        didSet { persist() }
    }
    private let key = "wiz.syncbox.lights.v1"

    init() {
        if let data = UserDefaults.standard.data(forKey: key),
           let decoded = try? JSONDecoder().decode([LightConfig].self, from: data),
           decoded.count == 11 {
            lights = decoded
        } else {
            lights = DefaultConfiguration.lights()
        }
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(lights) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
}
