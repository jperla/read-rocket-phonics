import SwiftUI

@main
struct ReadRocketPhonicsApp: App {
    @StateObject private var store = ProfileStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
        }
    }
}
