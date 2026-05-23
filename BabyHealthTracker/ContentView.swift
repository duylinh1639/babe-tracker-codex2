import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var store: BabyHealthStore

    var body: some View {
        Group {
            if store.profiles.isEmpty {
                OnboardingView()
            } else {
                MainTabView()
            }
        }
        .preferredColorScheme(nil)
    }
}
