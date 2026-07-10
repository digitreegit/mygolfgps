import SwiftUI
import MyGolfGPSCore

@main
struct MyGolfGPSWatchApp: App {
    @StateObject private var session = WatchSession()

    var body: some Scene {
        WindowGroup {
            WatchContentView()
                .environmentObject(session)
        }
    }
}
