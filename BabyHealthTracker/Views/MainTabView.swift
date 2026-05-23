import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem { Label("Home", systemImage: "house.fill") }
                .tag(0)

            SleepTrackerView()
                .tabItem { Label("Sleep", systemImage: "moon.zzz.fill") }
                .tag(1)

            GrowthView()
                .tabItem { Label("Growth", systemImage: "chart.line.uptrend.xyaxis") }
                .tag(2)

            VaccineView()
                .tabItem { Label("Vaccines", systemImage: "syringe.fill") }
                .tag(3)

            ProfileView()
                .tabItem { Label("Profile", systemImage: "person.crop.circle.fill") }
                .tag(4)
        }
        .tint(.appPrimary)
    }
}
