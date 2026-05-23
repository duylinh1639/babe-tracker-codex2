import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var store: BabyHealthStore
    @State private var activeSheet: LogSheet?

    var body: some View {
        if let profile = store.activeProfile {
            NavigationStack {
                ZStack {
                    Color.appBackground.ignoresSafeArea()

                    ScrollView {
                        VStack(spacing: 18) {
                            HomeHeader(profile: profile)
                            BabySummaryCard(profile: profile)
                            TodayStats(profile: profile)
                            QuickLogGrid(activeSheet: $activeSheet)
                            LiveSleepBanner(profile: profile)
                            UpcomingToday(profile: profile)
                            ActivityFeed(profile: profile)
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                        .padding(.bottom, 28)
                    }
                }
                .navigationBarTitleDisplayMode(.inline)
                .toolbar(.hidden, for: .navigationBar)
                .sheet(item: $activeSheet) { sheet in
                    LogSheetHost(sheet: sheet, profile: profile)
                        .presentationDetents([.medium, .large])
                }
            }
        } else {
            OnboardingView()
        }
    }
}

private struct HomeHeader: View {
    var profile: BabyProfile

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("home.greeting")
                    .font(.rounded(13, weight: .semibold))
                    .foregroundStyle(Color.textSecondary)
                Text(profile.name)
                    .font(.rounded(24, weight: .bold))
            }

            Spacer()

            Text("MN")
                .font(.rounded(13, weight: .bold))
                .foregroundStyle(Color.appPrimary)
                .frame(width: 34, height: 34)
                .background(Color.appPrimary.opacity(0.14))
                .clipShape(Circle())
        }
    }
}

private struct BabySummaryCard: View {
    var profile: BabyProfile

    var body: some View {
        HStack(spacing: 14) {
            Text(profile.initials)
                .font(.rounded(18, weight: .bold))
                .foregroundStyle(Color.appPrimary)
                .frame(width: 56, height: 56)
                .background(Color.appPrimary.opacity(0.12))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(profile.name)
                    .font(.rounded(18, weight: .bold))
                Text("\(profile.ageText()) - \(AppFormatters.shortDate.string(from: profile.dateOfBirth))")
                    .font(.rounded(13))
                    .foregroundStyle(Color.textSecondary)
            }

            Spacer()

            LiveSyncBadge()
        }
        .padding(16)
        .appCard()
    }
}

private struct LiveSyncBadge: View {
    var body: some View {
        HStack(spacing: 6) {
            TimelineView(.periodic(from: Date(), by: 2)) { context in
                Circle()
                    .fill(Color.growth.opacity(context.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 4) < 2 ? 1 : 0.45))
                    .frame(width: 8, height: 8)
            }

            Text("sync.live")
                .font(.rounded(11, weight: .bold))
                .foregroundStyle(Color.growth)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(Color.growth.opacity(0.12))
        .clipShape(Capsule())
    }
}

private struct TodayStats: View {
    @EnvironmentObject private var store: BabyHealthStore
    var profile: BabyProfile

    var body: some View {
        HStack(spacing: 10) {
            MetricCard(icon: "moon.fill", value: AppFormatters.hours(store.sleepTotalToday(for: profile)), label: "Sleep", tint: .sleep, background: .sleepBackground)
            MetricCard(icon: "drop.fill", value: "\(store.diaperCountToday(for: profile))", label: "Diapers", tint: .diaper, background: .diaperBackground)
            MetricCard(icon: "thermometer.medium", value: temperatureText, label: "Temp", tint: .appAlert, background: .alertBackground)
        }
    }

    private var temperatureText: String {
        guard let temp = store.latestTemperature(for: profile) else { return "--" }
        return String(format: "%.1f", temp)
    }
}

private struct QuickLogGrid: View {
    @Binding var activeSheet: LogSheet?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionTitle(title: "Quick log")

            HStack(spacing: 10) {
                QuickLogButton(title: String(localized: "home.quicklog.sleep"), icon: "moon.zzz.fill", tint: .sleep, background: .sleepBackground) { activeSheet = .sleep }
                QuickLogButton(title: String(localized: "home.quicklog.diaper"), icon: "drop.fill", tint: .diaper, background: .diaperBackground) { activeSheet = .diaper }
                QuickLogButton(title: String(localized: "home.quicklog.medicine"), icon: "pills.fill", tint: .medicine, background: .medicineBackground) { activeSheet = .medication }
                QuickLogButton(title: String(localized: "home.quicklog.symptom"), icon: "thermometer.medium", tint: .appAlert, background: .alertBackground) { activeSheet = .symptom }
            }
        }
    }
}

private struct LiveSleepBanner: View {
    @EnvironmentObject private var store: BabyHealthStore
    var profile: BabyProfile

    var body: some View {
        if let active = store.activeSleep(for: profile) {
            TimelineView(.periodic(from: Date(), by: 1)) { context in
                HStack(spacing: 14) {
                    Image(systemName: "moon.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(Color.sleep)
                        .frame(width: 42, height: 42)
                        .background(Color.sleep.opacity(0.12))
                        .clipShape(Circle())

                    VStack(alignment: .leading, spacing: 3) {
                        Text("Dang ngu")
                            .font(.rounded(14, weight: .bold))
                        Text("Started \(AppFormatters.time.string(from: active.startTime)) by \(active.loggedBy)")
                            .font(.rounded(12))
                            .foregroundStyle(Color.textSecondary)
                    }

                    Spacer()

                    Text(AppFormatters.timer(active.durationSeconds(referenceDate: context.date)))
                        .font(.rounded(22, weight: .bold))
                        .foregroundStyle(Color.sleep)
                        .monospacedDigit()
                }
                .padding(16)
                .background(Color.sleepBackground)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
        }
    }
}

private struct UpcomingToday: View {
    @EnvironmentObject private var store: BabyHealthStore
    var profile: BabyProfile

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionTitle(title: "Today")
            let items = store.upcomingItems(for: profile)
            if items.isEmpty {
                EmptyState(icon: "checkmark.circle.fill", title: "No reminders due", subtitle: "Medication, vaccine, and follow-up reminders will appear here.")
            } else {
                VStack(spacing: 8) {
                    ForEach(items) { item in
                        UpcomingRow(item: item)
                    }
                }
            }
        }
    }
}

private struct UpcomingRow: View {
    var item: UpcomingItem

    var body: some View {
        let tint = AppTheme.tint(for: item.tintName)

        HStack(spacing: 12) {
            Image(systemName: item.icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 36, height: 36)
                .background(tint.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            Text(item.title)
                .font(.rounded(14, weight: .semibold))
                .lineLimit(1)

            Spacer()

            Badge(title: AppFormatters.time.string(from: item.time), tint: tint)
        }
        .padding(12)
        .appCard(radius: 14)
    }
}

private struct ActivityFeed: View {
    @EnvironmentObject private var store: BabyHealthStore
    var profile: BabyProfile

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionTitle(title: "Activity today")
            let items = Array(store.activityItems(for: profile).prefix(6))
            if items.isEmpty {
                EmptyState(icon: "list.bullet.rectangle", title: "No activity yet", subtitle: "Quick logs from both parents will build a timeline here.")
            } else {
                VStack(spacing: 8) {
                    ForEach(items) { item in
                        ActivityRow(item: item)
                    }
                }
            }
        }
    }
}

private struct ActivityRow: View {
    var item: ActivityItem

    var body: some View {
        let tint = AppTheme.tint(for: item.tintName)

        HStack(spacing: 12) {
            Circle()
                .fill(tint)
                .frame(width: 8, height: 8)

            Image(systemName: item.icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 32, height: 32)
                .background(tint.opacity(0.12))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.rounded(13, weight: .bold))
                    .lineLimit(1)
                Text(item.subtitle)
                    .font(.rounded(12))
                    .foregroundStyle(Color.textSecondary)
                    .lineLimit(1)
            }

            Spacer()

            Text(AppFormatters.relative(item.time))
                .font(.rounded(11, weight: .semibold))
                .foregroundStyle(Color.textSecondary)
        }
        .padding(12)
        .appCard(radius: 14)
    }
}
