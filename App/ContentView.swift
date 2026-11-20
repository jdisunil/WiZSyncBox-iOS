import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var store: LightStore
    @State private var status = "Configure one bulb and tap Test Red."
    @State private var busy = false
    @State private var brightness = 80.0
    private let coordinator = SyncCoordinator()

    var body: some View {
        NavigationStack {
            Form {
                Section("Phase 4A · One-bulb connectivity test") {
                    Text("Connect your iPhone and WiZ bulbs to the same home network. Enter each bulb's local IPv4 address.")
                        .font(.footnote)
                    HStack {
                        Button("Test Red") { test(RGBColor(r: 255, g: 0, b: 0)) }
                        Button("Test Green") { test(RGBColor(r: 0, g: 255, b: 0)) }
                        Button("Test Blue") { test(RGBColor(r: 0, g: 0, b: 255)) }
                    }
                    .disabled(busy)
                    HStack {
                        Text("Brightness")
                        Slider(value: $brightness, in: 10...100, step: 5)
                        Text("\(Int(brightness))%")
                    }
                    Text(status).font(.footnote).accessibilityIdentifier("connectionStatus")
                }
                Section("Living room · 11 WiZ lights") {
                    ForEach($store.lights) { $light in
                        VStack(alignment: .leading, spacing: 8) {
                            Toggle("\(light.name)", isOn: $light.enabled)
                            TextField("Bulb IPv4, e.g. 192.168.1.50", text: $light.ipAddress)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .keyboardType(.numbersAndPunctuation)
                            Picker("TV zone", selection: $light.zone) {
                                ForEach(TVZone.allCases) { zone in
                                    Text(zone.title).tag(zone)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                Section("Safety and limitations") {
                    Text("This screen sends a manual colour test only. A successful UDP send does not prove that a bulb received the command. Verify the physical colour change.")
                        .font(.footnote)
                    Text("Camera capture and live TV synchronization are planned for Phase 4B; they are not included in this native connectivity test.")
                        .font(.footnote)
                }
            }
            .navigationTitle("WiZ Sync Box")
        }
    }

    private func test(_ color: RGBColor) {
        let selected = store.lights.filter(\.enabled)
        guard !selected.isEmpty else {
            status = "Enable at least one light and enter its IPv4 address."
            return
        }
        busy = true
        status = "Sending UDP test to \(selected.count) enabled light(s)…"
        Task {
            var errors: [String] = []
            for light in selected {
                do { try await coordinator.send(color: color, to: light, brightness: Int(brightness)) }
                catch { errors.append("\(light.name): \(error.localizedDescription)") }
            }
            status = errors.isEmpty
                ? "Commands sent. Check the physical bulbs; UDP delivery is not acknowledged."
                : errors.joined(separator: "\n")
            busy = false
        }
    }
}
