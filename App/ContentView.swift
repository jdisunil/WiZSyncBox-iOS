import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var store: LightStore
    @State private var status = "Configure one bulb and tap Test Red."
    @State private var busy = false
    @State private var brightness = 80.0
    private let coordinator = SyncCoordinator()
    private let diagnostic = WiZDiagnosticService()
    @State private var diagnosticLog = "No diagnostic test run yet."
    @State private var diagnosticBusy = false
    @State private var diagnosticLightID = 1

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
                Section("Phase 4A.3 · Single-bulb verified diagnostics") {
                    Text("Select ONE bulb. This diagnostic sends exactly one requested colour, reads the setPilot response, then queries getPilot. It does not send to the other enabled bulbs.")
                        .font(.footnote)
                    Picker("Diagnostic bulb", selection: $diagnosticLightID) {
                        ForEach(store.lights) { light in
                            Text(light.name).tag(light.id)
                        }
                    }
                    HStack {
                        Button("Verify Red") { verify(RGBColor(r: 255, g: 0, b: 0)) }
                        Button("Verify Green") { verify(RGBColor(r: 0, g: 255, b: 0)) }
                        Button("Verify Blue") { verify(RGBColor(r: 0, g: 0, b: 255)) }
                    }
                    .disabled(diagnosticBusy || busy)
                    Text(diagnosticLog).font(.system(.caption, design: .monospaced))
                        .textSelection(.enabled)
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

    private func verify(_ color: RGBColor) {
        guard let light = store.lights.first(where: { $0.id == diagnosticLightID }) else { return }
        guard IPv4Validator.isValid(light.ipAddress) else {
            diagnosticLog = "Enter a valid IPv4 address for \(light.name)."
            return
        }
        diagnosticBusy = true
        diagnosticLog = "Testing \(light.name) at \(light.ipAddress)…"
        let ip = light.ipAddress
        let level = Int(brightness)
        Task {
            let result = await diagnostic.test(ip: ip, color: color, brightness: level)
            diagnosticLog = "IP: \(ip)\nREQUEST: \(result.request)\nSET RESPONSE: \(result.setResponse)\nGET RESPONSE: \(result.stateResponse)\nRESULT: \(result.verdict)"
            diagnosticBusy = false
        }
    }

    private func test(_ color: RGBColor) {
        let selected = store.lights.filter(\.enabled)
        guard !selected.isEmpty else {
            status = "Enable at least one light and enter its IPv4 address."
            return
        }
        let ips = selected.map(\.ipAddress)
        guard Set(ips).count == ips.count else {
            status = "Duplicate IP addresses detected. Each enabled light needs its own IPv4 address."
            return
        }
        busy = true
        status = "Sending UDP test to \(selected.count) enabled light(s)…"
        Task {
            var errors: [String] = []
            let zones = Dictionary(uniqueKeysWithValues: TVZone.allCases.map { ($0, color) })
            let failures = await coordinator.synchronize(zones: zones, lights: selected, brightness: Int(brightness))
            for light in selected {
                if let error = failures[light.id] { errors.append("\(light.name): \(error)") }
            }
            status = errors.isEmpty
                ? "Commands sent. Check the physical bulbs; UDP delivery is not acknowledged."
                : errors.joined(separator: "\n")
            busy = false
        }
    }
}
