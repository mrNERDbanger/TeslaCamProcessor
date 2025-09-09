import SwiftUI

@main
struct TeslaCamProcessorApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 800, minHeight: 600)
        }
        .windowStyle(.automatic)
        .windowResizability(.contentSize)
    }
}