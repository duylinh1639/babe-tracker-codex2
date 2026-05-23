import SwiftUI

struct SleepTrackerView: View {
    @EnvironmentObject private var store: BabyHealthStore
    @State private var activeSheet: LogSheet?

    var body: some View {
        if let profile = store.activeProfile {
            NavigationStack {
                ZStack {
                    Color.sleepBackground.ignoresSafeArea()

                    ScrollView {
                        VStack(spacing: 18) {
                            SleepTimerCard(profile: profile)
                            SevenDaySleepChart(profile: profile)
                            SleepLogList(profile: profile)
                        }
                        .padding(16)
                    }
                }
                .navigationTitle("Sleep")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            activeSheet = .sleep
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
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

private struct SleepTimerCard: View {
    @EnvironmentObject private var store: BabyHealthStore
    var profile: BabyProfile

    var body: some View {
        VStack(spacing: 18) {
            if let active = store.activeSleep(for: profile) {
                Text(active.kind == .nap ? "Dang ngu trua" : "Dang ngu dem")
                    .font(.rounded(16, weight: .bold))

                TimelineView(.periodic(from: Date(), by: 1)) { context in
                    Text(AppFormatters.timer(active.durationSeconds(referenceDate: context.date)))
                        .font(.rounded(42, weight: .bold))
                        .foregroundStyle(Color.sleep)
                        .monospacedDigit()
                }

                Text("Started \(AppFormatters.time.string(from: active.startTime)) - \(active.loggedBy)")
                    .font(.rounded(13))
                    .foregroundStyle(Color.textSecondary)

                Button(role: .destructive) {
                    store.stopSleep(for: active)
                } label: {
                    Label("End Sleep", systemImage: "stop.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            } else {
                Image(systemName: "moon.zzz.fill")
                    .font(.system(size: 38, weight: .semibold))
                    .foregroundStyle(Color.sleep)

                Text("No sleep timer running")
                    .font(.rounded(18, weight: .bold))

                HStack(spacing: 12) {
                    Button {
                        store.startSleep(for: profile, kind: .nap)
                    } label: {
                        Label("Start Sleep", systemImage: "play.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.sleep)

                    Button {
                        store.startSleep(for: profile, kind: .night)
                    } label: {
                        Label("Night", systemImage: "moon.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
                .controlSize(.large)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .appCard()
    }
}

private struct SevenDaySleepChart: View {
    @EnvironmentObject private var store: BabyHealthStore
    var profile: BabyProfile

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionTitle(title: "Last 7 days")
            MiniBarChart(values: values, labels: labels, tint: .sleep, targetRange: 11...14)

            HStack(spacing: 8) {
                Image(systemName: "target")
                Text("WHO toddler recommendation: 11-14h per day")
            }
            .font(.rounded(12, weight: .semibold))
            .foregroundStyle(Color.textSecondary)
        }
        .padding(16)
        .appCard()
    }

    private var days: [Date] {
        (0..<7).compactMap { Calendar.current.date(byAdding: .day, value: -6 + $0, to: Date()) }
    }

    private var values: [Double] {
        days.map { day in
            let entries = store.sleepEntries(for: profile).filter { entry in
                Calendar.current.isDate(entry.startTime, inSameDayAs: day)
            }
            return entries.reduce(0) { total, entry in
                total + entry.durationSeconds(referenceDate: Date()) / 3600
            }
        }
    }

    private var labels: [String] {
        days.map { AppFormatters.weekday.string(from: $0) }
    }
}

private struct SleepLogList: View {
    @EnvironmentObject private var store: BabyHealthStore
    var profile: BabyProfile

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionTitle(title: "Sleep log")

            let entries = store.sleepEntries(for: profile)
            if entries.isEmpty {
                EmptyState(icon: "moon", title: "No sleep yet", subtitle: "Start a timer or add a manual log to build a sleep history.")
            } else {
                VStack(spacing: 8) {
                    ForEach(entries) { entry in
                        SleepEntryRow(entry: entry)
                    }
                }
            }
        }
    }
}

private struct SleepEntryRow: View {
    var entry: SleepEntry

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: entry.kind == .nap ? "sun.max.fill" : "moon.fill")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color.sleep)
                .frame(width: 38, height: 38)
                .background(Color.sleep.opacity(0.12))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.kind.title)
                    .font(.rounded(14, weight: .bold))
                Text("\(AppFormatters.time.string(from: entry.startTime)) - \(entry.endTime.map { AppFormatters.time.string(from: $0) } ?? "now")")
                    .font(.rounded(12))
                    .foregroundStyle(Color.textSecondary)
            }

            Spacer()

            Badge(title: AppFormatters.duration(entry.durationSeconds()), tint: .sleep)
        }
        .padding(12)
        .appCard(radius: 14)
    }
}
