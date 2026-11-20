import SwiftUI

@main
struct WiZSyncBoxApp: App {
    @StateObject private var store = LightStore()
    var body: some Scene {
        WindowGroup { ContentView().environmentObject(store) }
    }
}
