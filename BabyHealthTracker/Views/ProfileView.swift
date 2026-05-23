import SwiftUI
import Foundation

enum AppLanguage: String, CaseIterable {
    case english = "en"
    case vietnamese = "vi"
    
    var title: String {
        switch self {
        case .english: return "English"
        case .vietnamese: return "Tiếng Việt"
        }
    }
}

struct LanguageManager {
    static let shared = LanguageManager()
    private let key = "AppleLanguages"
    
    var currentLanguage: AppLanguage {
        get {
            let lang = UserDefaults.standard.string(forKey: key) ?? "en"
            return AppLanguage(rawValue: lang) ?? .english
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: key)
        }
    }
}

struct ProfileView: View {
    @EnvironmentObject private var store: BabyHealthStore
    @State private var activeSheet: LogSheet?

    var body: some View {
        if let profile = store.activeProfile {
            NavigationStack {
                ZStack {
                    Color.appBackground.ignoresSafeArea()

                    ScrollView {
                        VStack(spacing: 18) {
                            ProfileSwitcher(activeProfile: profile, activeSheet: $activeSheet)
                            DoctorVisitSection(profile: profile, activeSheet: $activeSheet)
                            ExportPreview(profile: profile)
                            SettingsSection()
                        }
                        .padding(16)
                    }
                }
                .navigationTitle("Profile")
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

private struct ProfileSwitcher: View {
    @EnvironmentObject private var store: BabyHealthStore
    var activeProfile: BabyProfile
    @Binding var activeSheet: LogSheet?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(title: "Baby profiles", actionTitle: "Add") {
                activeSheet = .profile
            }

            ForEach(store.profiles) { profile in
                Button {
                    store.setActiveProfile(profile)
                } label: {
                    HStack(spacing: 12) {
                        Text(profile.initials)
                            .font(.rounded(15, weight: .bold))
                            .foregroundStyle(Color.appPrimary)
                            .frame(width: 44, height: 44)
                            .background(Color.appPrimary.opacity(0.12))
                            .clipShape(Circle())

                        VStack(alignment: .leading, spacing: 2) {
                            Text(profile.name)
                                .font(.rounded(14, weight: .bold))
                            Text("(profile.ageText()) - (profile.gender.title)")
                                .font(.rounded(12))
                                .foregroundStyle(Color.textSecondary)
                        }

                        Spacer()

                        if profile.id == activeProfile.id {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(Color.growth)
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .padding(12)
                .appCard(radius: 14)
            }
        }
    }
}

private struct DoctorVisitSection: View {
    @EnvironmentObject private var store: BabyHealthStore
    var profile: BabyProfile
    @Binding var activeSheet: LogSheet?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionTitle(title: "Doctor visits", actionTitle: "Add") {
                activeSheet = .visit
            }

            let visits = store.doctorVisits(for: profile)
            if visits.isEmpty {
                EmptyState(icon: "stethoscope", title: "No visits saved", subtitle: "Log appointments, diagnosis, prescriptions, and follow-up reminders.")
            } else {
                VStack(spacing: 8) {
                    ForEach(visits) { visit in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Label(visit.clinic.isEmpty ? "Clinic" : visit.clinic, systemImage: "stethoscope")
                                    .font(.rounded(14, weight: .bold))
                                Spacer()
                                Text(AppFormatters.shortDate.string(from: visit.date))
                                    .font(.rounded(12, weight: .semibold))
                                    .foregroundStyle(Color.textSecondary)
                            }

                            Text(visit.reason.isEmpty ? "Reason not set" : visit.reason)
                                .font(.rounded(13))
                                .foregroundStyle(Color.textSecondary)

                            if let followUp = visit.followUpDate {
                                Badge(title: "Follow-up \(AppFormatters.shortDate.string(from: followUp))", tint: .appPrimary)
                            }
                        }
                        .padding(14)
                        .appCard(radius: 14)
                    }
                }
            }
        }
    }
}

private struct ExportPreview: View {
    @EnvironmentObject private var store: BabyHealthStore
    var profile: BabyProfile

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionTitle(title: "Doctor report")

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("BabyTracker")
                        .font(.rounded(16, weight: .bold))
                    Spacer()
                    Text(AppFormatters.shortDate.string(from: Date()))
                        .font(.rounded(12, weight: .semibold))
                        .foregroundStyle(Color.textSecondary)
                }

                Divider()

                reportLine(title: "Growth", value: latestGrowth)
                reportLine(title: "Vaccines", value: "(completedVaccines) completed, (overdueVaccines) late")
                reportLine(title: "Medicine", value: latestMedicine)
                reportLine(title: "Symptoms", value: latestSymptom)

                ShareLink(item: reportText) {
                    Label("Share Summary", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.appPrimary)
                .controlSize(.large)
            }
            .padding(16)
            .appCard()
        }
    }

    private func reportLine(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.rounded(13, weight: .bold))
            Spacer()
            Text(value)
                .font(.rounded(13))
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.trailing)
        }
    }

    private var latestGrowth: String {
        guard let entry = store.growthEntries(for: profile).last else { return "No data" }
        return String(format: "%.1f kg, %.0f cm", entry.weightKg, entry.heightCm)
    }

    private var completedVaccines: Int {
        store.vaccineRecords(for: profile).filter { $0.status() == .completed }.count
    }

    private var overdueVaccines: Int {
        store.vaccineRecords(for: profile).filter {
            if case .overdue = $0.status() { return true }
            return false
        }.count
    }

    private var latestMedicine: String {
        guard let entry = store.medicationEntries(for: profile).first else { return "None" }
        return "(entry.name) (entry.dosageText)"
    }

    private var latestSymptom: String {
        guard let entry = store.symptomEntries(for: profile).first else { return "None" }
        return entry.symptom.title
    }

    private var reportText: String {
        """
        BabyTracker Health Summary
        Baby: \(profile.name)
        Date: \(AppFormatters.shortDate.string(from: Date()))
        Growth: \(latestGrowth)
        Vaccines: \(completedVaccines) completed, \(overdueVaccines) late
        Latest medicine: \(latestMedicine)
        Latest symptom: \(latestSymptom)
        """
    }
}

private struct SettingsSection: View {
    @EnvironmentObject private var store: BabyHealthStore
    @State private var dailySummary = Date()
    @State private var diaperReminderHours = 4.0
    @State private var vaccineReminderDays = 7
    @State private var selectedLanguage: AppLanguage = LanguageManager.shared.currentLanguage
    @State private var showRestartAlert = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionTitle(title: LocalizedStringKey("settings.title"))

            VStack(spacing: 12) {
                DatePicker(LocalizedStringKey("settings.daily_summary"), selection: $dailySummary, displayedComponents: .hourAndMinute)
                Stepper(String(format: NSLocalizedString("settings.diaper_reminder", comment: ""), Int(diaperReminderHours)), value: $diaperReminderHours, in: 2...8, step: 1)
                Stepper(String(format: NSLocalizedString("settings.vaccine_reminder", comment: ""), vaccineReminderDays), value: $vaccineReminderDays, in: 1...14, step: 1)
                
                HStack {
                    Text(LocalizedStringKey("settings.language"))
                        .font(.rounded(14, weight: .semibold))
                    Spacer()
                    Picker("", selection: $selectedLanguage) {
                        ForEach(AppLanguage.allCases, id: \.self) { lang in
                            Text(lang.title).tag(lang)
                        }
                    }
                    .pickerStyle(.menu)
                    .onChange(of: selectedLanguage) { _, newValue in
                        LanguageManager.shared.currentLanguage = newValue
                        showRestartAlert = true
                    }
                }
                .alert(LocalizedStringKey("settings.title"), isPresented: $showRestartAlert) {
                    Button("OK", role: .cancel) {}
                } message: {
                    Text(LocalizedStringKey("settings.restart_required"))
                }

                Button(role: .destructive) {
                    store.resetDemoData()
                } label: {
                    Label(LocalizedStringKey("settings.reset_demo_data"), systemImage: "arrow.counterclockwise")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
            .padding(16)
            .appCard()
        }
    }
}
