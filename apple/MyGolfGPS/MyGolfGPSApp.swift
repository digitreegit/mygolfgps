import SwiftUI
import MyGolfGPSCore

@main
struct MyGolfGPSApp: App {
    @StateObject private var session = PhoneSession()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(session)
        }
    }
}
