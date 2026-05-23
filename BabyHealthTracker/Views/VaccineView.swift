import SwiftUI

struct VaccineView: View {
    @EnvironmentObject private var store: BabyHealthStore

    var body: some View {
        if let profile = store.activeProfile {
            NavigationStack {
                ZStack {
                    Color.vaccineBackground.ignoresSafeArea()

                    ScrollView {
                        VStack(spacing: 18) {
                            VaccineStatusOverview(profile: profile)
                            VaccineList(profile: profile)
                        }
                        .padding(16)
                    }
                }
                .navigationTitle("Vaccines")
            }
        } else {
            OnboardingView()
        }
    }
}

private struct VaccineStatusOverview: View {
    @EnvironmentObject private var store: BabyHealthStore
    var profile: BabyProfile

    var body: some View {
        HStack(spacing: 8) {
            StatusPill(title: "\(completed) Done", icon: "checkmark.circle.fill", tint: .growth)
            StatusPill(title: "\(soon) Soon", icon: "clock.fill", tint: .vaccine)
            StatusPill(title: "\(overdue) Late", icon: "exclamationmark.circle.fill", tint: .appAlert)
        }
    }

    private var records: [VaccineRecord] {
        store.vaccineRecords(for: profile)
    }

    private var completed: Int {
        records.filter { $0.status() == .completed }.count
    }

    private var soon: Int {
        records.filter {
            if case .dueSoon = $0.status() { return true }
            return false
        }.count
    }

    private var overdue: Int {
        records.filter {
            if case .overdue = $0.status() { return true }
            return false
        }.count
    }
}

private struct StatusPill: View {
    var title: String
    var icon: String
    var tint: Color

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
            Text(title)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .font(.rounded(12, weight: .bold))
        .foregroundStyle(tint)
        .frame(maxWidth: .infinity, minHeight: 42)
        .background(tint.opacity(0.12))
        .clipShape(Capsule())
    }
}

private struct VaccineList: View {
    @EnvironmentObject private var store: BabyHealthStore
    var profile: BabyProfile

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(title: "Vietnam EPI schedule")

            ForEach(store.vaccineRecords(for: profile)) { record in
                VaccineCard(record: record)
            }
        }
    }
}

private struct VaccineCard: View {
    @EnvironmentObject private var store: BabyHealthStore
    @State private var showingCompleteSheet = false
    @State private var clinic = ""
    @State private var lotNumber = ""
    @State private var notes = ""
    @State private var completedDate = Date()

    var record: VaccineRecord

    var body: some View {
        let status = record.status()
        let tint = color(for: status)

        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: icon(for: status))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(tint)
                    .frame(width: 38, height: 38)
                    .background(tint.opacity(0.12))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 3) {
                    Text(record.name)
                        .font(.rounded(15, weight: .bold))
                    Text("\(record.dose) - Due \(AppFormatters.shortDate.string(from: record.dueDate))")
                        .font(.rounded(12))
                        .foregroundStyle(Color.textSecondary)
                }

                Spacer()

                Badge(title: status.title, tint: tint)
            }

            if status != .completed {
                HStack {
                    Text(status.detail)
                        .font(.rounded(12, weight: .semibold))
                        .foregroundStyle(tint)

                    Spacer()

                    Button("Mark done") {
                        showingCompleteSheet = true
                    }
                    .buttonStyle(.bordered)
                    .tint(tint)
                }
            } else if let completedDate = record.completedDate {
                Text("Completed \(AppFormatters.shortDate.string(from: completedDate)) at \(record.clinic.isEmpty ? "clinic not set" : record.clinic)")
                    .font(.rounded(12))
                    .foregroundStyle(Color.textSecondary)
            }
        }
        .padding(14)
        .background(background(for: status))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(tint.opacity(0.18), lineWidth: 1)
        )
        .sheet(isPresented: $showingCompleteSheet) {
            NavigationStack {
                Form {
                    DatePicker("Date given", selection: $completedDate, displayedComponents: .date)
                    TextField("Clinic / hospital", text: $clinic)
                    TextField("Lot number optional", text: $lotNumber)
                    TextField("Notes", text: $notes, axis: .vertical)

                    Button {
                        store.completeVaccine(record, date: completedDate, clinic: clinic, lotNumber: lotNumber, notes: notes)
                        showingCompleteSheet = false
                    } label: {
                        Label("Save Completion", systemImage: "checkmark.circle.fill")
                    }
                }
                .navigationTitle(record.name)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Close") { showingCompleteSheet = false }
                    }
                }
            }
            .presentationDetents([.medium])
        }
    }

    private func color(for status: VaccineStatus) -> Color {
        switch status {
        case .completed: return .growth
        case .dueSoon, .notDue: return .vaccine
        case .overdue: return .appAlert
        }
    }

    private func background(for status: VaccineStatus) -> Color {
        switch status {
        case .completed: return Color.growth.opacity(0.08)
        case .dueSoon, .notDue: return Color.vaccine.opacity(0.08)
        case .overdue: return Color.appAlert.opacity(0.08)
        }
    }

    private func icon(for status: VaccineStatus) -> String {
        switch status {
        case .completed: return "checkmark"
        case .dueSoon, .notDue: return "syringe.fill"
        case .overdue: return "exclamationmark"
        }
    }
}
