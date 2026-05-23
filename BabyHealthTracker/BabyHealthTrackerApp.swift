import SwiftUI

@main
struct BabyHealthTrackerApp: App {
    @StateObject private var store = BabyHealthStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
        }
    }
}
