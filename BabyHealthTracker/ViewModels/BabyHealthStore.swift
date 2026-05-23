import Foundation
import Combine

@MainActor
final class BabyHealthStore: ObservableObject {
    @Published private(set) var profiles: [BabyProfile] = [] {
        didSet { save() }
    }

    @Published private(set) var sleepEntries: [SleepEntry] = [] {
        didSet { save() }
    }

    @Published private(set) var diaperEntries: [DiaperEntry] = [] {
        didSet { save() }
    }

    @Published private(set) var growthEntries: [GrowthEntry] = [] {
        didSet { save() }
    }

    @Published private(set) var vaccineRecords: [VaccineRecord] = [] {
        didSet { save() }
    }

    @Published private(set) var medicationEntries: [MedicationEntry] = [] {
        didSet { save() }
    }

    @Published private(set) var symptomEntries: [SymptomEntry] = [] {
        didSet { save() }
    }

    @Published private(set) var doctorVisits: [DoctorVisit] = [] {
        didSet { save() }
    }

    private let storageKey = "BabyHealthTracker.snapshot.v1"
    private var isLoading = false

    init() {
        load()
        if profiles.isEmpty {
            seedDemoData()
        }
    }

    var activeProfile: BabyProfile? {
        profiles.first(where: \.isActive) ?? profiles.first
    }

    func setActiveProfile(_ profile: BabyProfile) {
        profiles = profiles.map { current in
            var copy = current
            copy.isActive = copy.id == profile.id
            return copy
        }
    }

    func addProfile(name: String, dateOfBirth: Date, gender: BabyGender, bloodType: String?) {
        let profile = BabyProfile(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            dateOfBirth: dateOfBirth,
            gender: gender,
            bloodType: bloodType?.nilIfBlank,
            isActive: profiles.isEmpty
        )

        profiles.append(profile)
        vaccineRecords.append(contentsOf: Self.vietnamVaccineSchedule(for: profile))
    }

    func startSleep(for profile: BabyProfile, kind: SleepKind = .nap, loggedBy: String = "Mom") {
        guard activeSleep(for: profile) == nil else { return }
        sleepEntries.append(SleepEntry(profileID: profile.id, startTime: Date(), endTime: nil, kind: kind, notes: "", loggedBy: loggedBy))
    }

    func stopSleep(for entry: SleepEntry) {
        guard let index = sleepEntries.firstIndex(where: { $0.id == entry.id }) else { return }
        sleepEntries[index].endTime = Date()
    }

    func addManualSleep(for profile: BabyProfile, start: Date, end: Date, kind: SleepKind, notes: String, loggedBy: String = "Dad") {
        sleepEntries.append(SleepEntry(profileID: profile.id, startTime: min(start, end), endTime: max(start, end), kind: kind, notes: notes, loggedBy: loggedBy))
    }

    func addDiaper(for profile: BabyProfile, kind: DiaperKind, condition: DiaperCondition, notes: String, loggedBy: String = "Mom") {
        diaperEntries.append(DiaperEntry(profileID: profile.id, time: Date(), kind: kind, condition: condition, notes: notes, loggedBy: loggedBy))
    }

    func addGrowth(for profile: BabyProfile, date: Date, weightKg: Double, heightCm: Double, headCm: Double, notes: String) {
        growthEntries.append(GrowthEntry(profileID: profile.id, date: date, weightKg: weightKg, heightCm: heightCm, headCircumferenceCm: headCm, notes: notes))
        growthEntries.sort { $0.date < $1.date }
    }

    func completeVaccine(_ record: VaccineRecord, date: Date, clinic: String, lotNumber: String, notes: String) {
        guard let index = vaccineRecords.firstIndex(where: { $0.id == record.id }) else { return }
        vaccineRecords[index].completedDate = date
        vaccineRecords[index].clinic = clinic
        vaccineRecords[index].lotNumber = lotNumber
        vaccineRecords[index].notes = notes
    }

    func addMedication(for profile: BabyProfile, name: String, amount: String, unit: MedicationUnit, route: MedicationRoute, time: Date, minimumIntervalHours: Double, notes: String, loggedBy: String = "Dad") {
        medicationEntries.append(MedicationEntry(profileID: profile.id, name: name, amount: amount, unit: unit, route: route, time: time, minimumIntervalHours: minimumIntervalHours, notes: notes, loggedBy: loggedBy))
    }

    func medicationConflict(for profile: BabyProfile, name: String, at time: Date, minimumIntervalHours: Double) -> MedicationEntry? {
        let normalized = name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !normalized.isEmpty else { return nil }

        return medicationEntries(for: profile)
            .filter { $0.name.lowercased() == normalized }
            .first { abs($0.time.timeIntervalSince(time)) < minimumIntervalHours * 3600 }
    }

    func addSymptom(for profile: BabyProfile, symptom: SymptomKind, severity: SymptomSeverity, temperatureC: Double?, notes: String, loggedBy: String = "Mom") {
        symptomEntries.append(SymptomEntry(profileID: profile.id, time: Date(), symptom: symptom, severity: severity, temperatureC: temperatureC, notes: notes, loggedBy: loggedBy))
    }

    func addDoctorVisit(for profile: BabyProfile, date: Date, doctorName: String, clinic: String, reason: String, diagnosis: String, prescriptions: String, followUpDate: Date?, notes: String) {
        doctorVisits.append(DoctorVisit(profileID: profile.id, date: date, doctorName: doctorName, clinic: clinic, reason: reason, diagnosis: diagnosis, prescriptions: prescriptions, followUpDate: followUpDate, notes: notes))
    }

    func resetDemoData() {
        profiles = []
        sleepEntries = []
        diaperEntries = []
        growthEntries = []
        vaccineRecords = []
        medicationEntries = []
        symptomEntries = []
        doctorVisits = []
        UserDefaults.standard.removeObject(forKey: storageKey)
        seedDemoData()
    }

    func activeSleep(for profile: BabyProfile) -> SleepEntry? {
        sleepEntries(for: profile).first(where: \.isActive)
    }

    func sleepEntries(for profile: BabyProfile) -> [SleepEntry] {
        sleepEntries
            .filter { $0.profileID == profile.id }
            .sorted { $0.startTime > $1.startTime }
    }

    func diaperEntries(for profile: BabyProfile) -> [DiaperEntry] {
        diaperEntries
            .filter { $0.profileID == profile.id }
            .sorted { $0.time > $1.time }
    }

    func growthEntries(for profile: BabyProfile) -> [GrowthEntry] {
        growthEntries
            .filter { $0.profileID == profile.id }
            .sorted { $0.date < $1.date }
    }

    func vaccineRecords(for profile: BabyProfile) -> [VaccineRecord] {
        vaccineRecords
            .filter { $0.profileID == profile.id }
            .sorted {
                let first = $0.status().sortPriority
                let second = $1.status().sortPriority
                return first == second ? $0.dueDate < $1.dueDate : first < second
            }
    }

    func medicationEntries(for profile: BabyProfile) -> [MedicationEntry] {
        medicationEntries
            .filter { $0.profileID == profile.id }
            .sorted { $0.time > $1.time }
    }

    func symptomEntries(for profile: BabyProfile) -> [SymptomEntry] {
        symptomEntries
            .filter { $0.profileID == profile.id }
            .sorted { $0.time > $1.time }
    }

    func doctorVisits(for profile: BabyProfile) -> [DoctorVisit] {
        doctorVisits
            .filter { $0.profileID == profile.id }
            .sorted { $0.date > $1.date }
    }

    func sleepTotalToday(for profile: BabyProfile, on date: Date = Date()) -> TimeInterval {
        let calendar = Calendar.current
        return sleepEntries(for: profile).reduce(0) { total, entry in
            guard let end = entry.endTime, calendar.isDate(entry.startTime, inSameDayAs: date) else { return total }
            return total + end.timeIntervalSince(entry.startTime)
        }
    }

    func diaperCountToday(for profile: BabyProfile, on date: Date = Date()) -> Int {
        diaperEntries(for: profile).filter { Calendar.current.isDate($0.time, inSameDayAs: date) }.count
    }

    func latestTemperature(for profile: BabyProfile) -> Double? {
        symptomEntries(for: profile).first(where: { $0.temperatureC != nil })?.temperatureC
    }

    func upcomingItems(for profile: BabyProfile) -> [UpcomingItem] {
        var items: [UpcomingItem] = []
        let now = Date()

        if let med = medicationEntries(for: profile).first {
            let nextDose = med.time.addingTimeInterval(max(med.minimumIntervalHours, 1) * 3600)
            if nextDose >= now && Calendar.current.isDate(nextDose, inSameDayAs: now) {
                items.append(UpcomingItem(icon: "pills.fill", title: "\(med.name) next dose", time: nextDose, tintName: "med"))
            }
        }

        if let visit = doctorVisits(for: profile).first(where: { ($0.followUpDate ?? .distantPast) >= now }) {
            items.append(UpcomingItem(icon: "stethoscope", title: "Follow-up: \(visit.clinic)", time: visit.followUpDate ?? visit.date, tintName: "primary"))
        }

        if let vaccine = vaccineRecords(for: profile).first(where: {
            if case .dueSoon = $0.status() { return true }
            return false
        }) {
            items.append(UpcomingItem(icon: "syringe.fill", title: vaccine.name, time: vaccine.dueDate, tintName: "vaccine"))
        }

        return items.sorted { $0.time < $1.time }
    }

    func activityItems(for profile: BabyProfile) -> [ActivityItem] {
        var items: [ActivityItem] = []

        for sleep in sleepEntries(for: profile).prefix(10) {
            let duration = AppFormatters.duration(sleep.durationSeconds())
            items.append(ActivityItem(icon: "moon.fill", title: sleep.isActive ? "Sleep timer started" : "\(sleep.kind.title) sleep", subtitle: sleep.isActive ? "\(sleep.loggedBy) logged" : "\(duration) - \(sleep.loggedBy)", time: sleep.startTime, tintName: "sleep"))
        }

        for diaper in diaperEntries(for: profile).prefix(10) {
            items.append(ActivityItem(icon: "drop.fill", title: "\(diaper.kind.title) diaper", subtitle: "\(diaper.condition.title) - \(diaper.loggedBy)", time: diaper.time, tintName: "diaper"))
        }

        for medication in medicationEntries(for: profile).prefix(10) {
            items.append(ActivityItem(icon: "pills.fill", title: medication.name, subtitle: "\(medication.dosageText) - \(medication.loggedBy)", time: medication.time, tintName: "med"))
        }

        for symptom in symptomEntries(for: profile).prefix(10) {
            let temp = symptom.temperatureC.map { String(format: " - %.1f C", $0) } ?? ""
            items.append(ActivityItem(icon: "thermometer.medium", title: symptom.symptom.title, subtitle: "\(symptom.severity.title)\(temp)", time: symptom.time, tintName: "alert"))
        }

        return items.sorted { $0.time > $1.time }
    }
}

struct UpcomingItem: Identifiable {
    var id = UUID()
    var icon: String
    var title: String
    var time: Date
    var tintName: String
}

struct ActivityItem: Identifiable {
    var id = UUID()
    var icon: String
    var title: String
    var subtitle: String
    var time: Date
    var tintName: String
}

private extension BabyHealthStore {
    struct Snapshot: Codable {
        var profiles: [BabyProfile]
        var sleepEntries: [SleepEntry]
        var diaperEntries: [DiaperEntry]
        var growthEntries: [GrowthEntry]
        var vaccineRecords: [VaccineRecord]
        var medicationEntries: [MedicationEntry]
        var symptomEntries: [SymptomEntry]
        var doctorVisits: [DoctorVisit]
    }

    func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return }
        isLoading = true
        defer { isLoading = false }

        guard let snapshot = try? JSONDecoder().decode(Snapshot.self, from: data) else { return }
        profiles = snapshot.profiles
        sleepEntries = snapshot.sleepEntries
        diaperEntries = snapshot.diaperEntries
        growthEntries = snapshot.growthEntries
        vaccineRecords = snapshot.vaccineRecords
        medicationEntries = snapshot.medicationEntries
        symptomEntries = snapshot.symptomEntries
        doctorVisits = snapshot.doctorVisits
    }

    func save() {
        guard !isLoading else { return }

        let snapshot = Snapshot(
            profiles: profiles,
            sleepEntries: sleepEntries,
            diaperEntries: diaperEntries,
            growthEntries: growthEntries,
            vaccineRecords: vaccineRecords,
            medicationEntries: medicationEntries,
            symptomEntries: symptomEntries,
            doctorVisits: doctorVisits
        )

        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }

    func seedDemoData() {
        let calendar = Calendar.current
        let dob = calendar.date(from: DateComponents(year: 2024, month: 11, day: 15)) ?? Date().addingTimeInterval(-18 * 30 * 24 * 3600)
        var profile = BabyProfile(name: "Bao Miu", dateOfBirth: dob, gender: .girl, bloodType: "O+", isActive: true)
        profile.id = UUID(uuidString: "8F9A647B-21F7-4866-A117-62EF3E4B08AB") ?? profile.id

        let now = Date()
        profiles = [profile]

        sleepEntries = [
            SleepEntry(profileID: profile.id, startTime: now.addingTimeInterval(-5 * 3600), endTime: now.addingTimeInterval(-3.5 * 3600), kind: .nap, notes: "", loggedBy: "Mom"),
            SleepEntry(profileID: profile.id, startTime: now.addingTimeInterval(-18 * 3600), endTime: now.addingTimeInterval(-9 * 3600), kind: .night, notes: "One short wake-up", loggedBy: "Dad"),
            SleepEntry(profileID: profile.id, startTime: now.addingTimeInterval(-26 * 3600), endTime: now.addingTimeInterval(-24.5 * 3600), kind: .nap, notes: "", loggedBy: "Mom")
        ]

        diaperEntries = [
            DiaperEntry(profileID: profile.id, time: now.addingTimeInterval(-45 * 60), kind: .wet, condition: .normal, notes: "", loggedBy: "Dad"),
            DiaperEntry(profileID: profile.id, time: now.addingTimeInterval(-3 * 3600), kind: .both, condition: .normal, notes: "", loggedBy: "Mom"),
            DiaperEntry(profileID: profile.id, time: now.addingTimeInterval(-7 * 3600), kind: .dirty, condition: .normal, notes: "", loggedBy: "Dad")
        ]

        growthEntries = [
            GrowthEntry(profileID: profile.id, date: calendar.date(byAdding: .month, value: -5, to: now) ?? now, weightKg: 9.2, heightCm: 76, headCircumferenceCm: 45.3, notes: ""),
            GrowthEntry(profileID: profile.id, date: calendar.date(byAdding: .month, value: -3, to: now) ?? now, weightKg: 9.8, heightCm: 79, headCircumferenceCm: 46.1, notes: ""),
            GrowthEntry(profileID: profile.id, date: calendar.date(byAdding: .month, value: -1, to: now) ?? now, weightKg: 10.2, heightCm: 82, headCircumferenceCm: 46.7, notes: "Clinic checkup")
        ]

        vaccineRecords = Self.vietnamVaccineSchedule(for: profile)
        if vaccineRecords.indices.contains(0) {
            vaccineRecords[0].completedDate = dob
            vaccineRecords[0].clinic = "City Children's Hospital"
        }
        if vaccineRecords.indices.contains(1) {
            vaccineRecords[1].completedDate = calendar.date(byAdding: .month, value: 2, to: dob)
            vaccineRecords[1].clinic = "Ward clinic"
        }

        medicationEntries = [
            MedicationEntry(profileID: profile.id, name: "Paracetamol", amount: "5", unit: .ml, route: .oral, time: now.addingTimeInterval(-2 * 3600), minimumIntervalHours: 6, notes: "After breakfast", loggedBy: "Mom")
        ]

        symptomEntries = [
            SymptomEntry(profileID: profile.id, time: now.addingTimeInterval(-2.2 * 3600), symptom: .fever, severity: .mild, temperatureC: 36.8, notes: "", loggedBy: "Mom")
        ]

        doctorVisits = [
            DoctorVisit(profileID: profile.id, date: calendar.date(byAdding: .day, value: -8, to: now) ?? now, doctorName: "Dr. Lan", clinic: "Family Pediatrics", reason: "Cough follow-up", diagnosis: "Mild viral cough", prescriptions: "Saline spray", followUpDate: calendar.date(byAdding: .day, value: 6, to: now), notes: "Bring temperature log")
        ]
    }

    static func vietnamVaccineSchedule(for profile: BabyProfile) -> [VaccineRecord] {
        let calendar = Calendar.current
        let dob = profile.dateOfBirth

        let schedule: [(String, String, Date)] = [
            ("Hepatitis B", "Birth dose", dob),
            ("BCG", "Birth dose", dob),
            ("DPT-HepB-Hib", "Dose 1", calendar.date(byAdding: .month, value: 2, to: dob) ?? dob),
            ("DPT-HepB-Hib", "Dose 2", calendar.date(byAdding: .month, value: 3, to: dob) ?? dob),
            ("DPT-HepB-Hib", "Dose 3", calendar.date(byAdding: .month, value: 4, to: dob) ?? dob),
            ("OPV", "Dose 1", calendar.date(byAdding: .month, value: 2, to: dob) ?? dob),
            ("OPV", "Dose 2", calendar.date(byAdding: .month, value: 3, to: dob) ?? dob),
            ("OPV", "Dose 3", calendar.date(byAdding: .month, value: 4, to: dob) ?? dob),
            ("Measles", "Dose 1", calendar.date(byAdding: .month, value: 9, to: dob) ?? dob),
            ("MMR", "Dose 1", calendar.date(byAdding: .month, value: 18, to: dob) ?? dob),
            ("Japanese encephalitis", "Dose 1", calendar.date(byAdding: .month, value: 12, to: dob) ?? dob)
        ]

        return schedule.map { name, dose, dueDate in
            VaccineRecord(profileID: profile.id, name: name, dose: dose, dueDate: dueDate, completedDate: nil, clinic: "", lotNumber: "", notes: "")
        }
    }
}

private extension String {
    var nilIfBlank: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
