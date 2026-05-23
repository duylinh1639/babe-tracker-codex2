import SwiftUI

enum LogSheet: String, Identifiable {
    case sleep
    case diaper
    case medication
    case symptom
    case growth
    case visit
    case profile

    var id: String { rawValue }
}

struct LogSheetHost: View {
    var sheet: LogSheet
    var profile: BabyProfile

    var body: some View {
        switch sheet {
        case .sleep:
            SleepLogSheet(profile: profile)
        case .diaper:
            DiaperLogSheet(profile: profile)
        case .medication:
            MedicationLogSheet(profile: profile)
        case .symptom:
            SymptomLogSheet(profile: profile)
        case .growth:
            GrowthLogSheet(profile: profile)
        case .visit:
            DoctorVisitSheet(profile: profile)
        case .profile:
            AddProfileSheet()
        }
    }
}

struct SleepLogSheet: View {
    @EnvironmentObject private var store: BabyHealthStore
    @Environment(\.dismiss) private var dismiss
    var profile: BabyProfile

    @State private var kind: SleepKind = .nap
    @State private var start = Date().addingTimeInterval(-3600)
    @State private var end = Date()
    @State private var notes = ""

    var body: some View {
        NavigationStack {
            Form {
                if let active = store.activeSleep(for: profile) {
                    Section("Live timer") {
                        TimelineView(.periodic(from: Date(), by: 1)) { context in
                            Text(AppFormatters.timer(active.durationSeconds(referenceDate: context.date)))
                                .font(.rounded(34, weight: .bold))
                                .foregroundStyle(Color.sleep)
                                .monospacedDigit()
                        }

                        Button(role: .destructive) {
                            store.stopSleep(for: active)
                            dismiss()
                        } label: {
                            Label("End Sleep", systemImage: "stop.fill")
                        }
                    }
                } else {
                    Section("Timer mode") {
                        Picker("Type", selection: $kind) {
                            ForEach(SleepKind.allCases) { kind in
                                Text(kind.title).tag(kind)
                            }
                        }
                        .pickerStyle(.segmented)

                        Button {
                            store.startSleep(for: profile, kind: kind)
                            dismiss()
                        } label: {
                            Label("Start Sleep", systemImage: "play.fill")
                        }
                    }
                }

                Section("Manual log") {
                    DatePicker("Start", selection: $start)
                    DatePicker("End", selection: $end)
                    Picker("Type", selection: $kind) {
                        ForEach(SleepKind.allCases) { kind in
                            Text(kind.title).tag(kind)
                        }
                    }
                    TextField("Notes", text: $notes, axis: .vertical)

                    Button {
                        store.addManualSleep(for: profile, start: start, end: end, kind: kind, notes: notes)
                        dismiss()
                    } label: {
                        Label("Add Sleep Entry", systemImage: "plus.circle.fill")
                    }
                }
            }
            .navigationTitle("Sleep")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}

struct DiaperLogSheet: View {
    @EnvironmentObject private var store: BabyHealthStore
    @Environment(\.dismiss) private var dismiss
    var profile: BabyProfile

    @State private var kind: DiaperKind = .wet
    @State private var condition: DiaperCondition = .normal
    @State private var notes = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Diaper change") {
                    Picker("Type", selection: $kind) {
                        ForEach(DiaperKind.allCases) { kind in
                            Text(kind.title).tag(kind)
                        }
                    }
                    .pickerStyle(.segmented)

                    Picker("Condition", selection: $condition) {
                        ForEach(DiaperCondition.allCases) { condition in
                            Text(condition.title).tag(condition)
                        }
                    }

                    TextField("Notes", text: $notes, axis: .vertical)

                    Button {
                        store.addDiaper(for: profile, kind: kind, condition: condition, notes: notes)
                        dismiss()
                    } label: {
                        Label("Log Diaper", systemImage: "drop.fill")
                    }
                }
            }
            .navigationTitle("Diaper")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}

struct MedicationLogSheet: View {
    @EnvironmentObject private var store: BabyHealthStore
    @Environment(\.dismiss) private var dismiss
    var profile: BabyProfile

    @State private var name = "Paracetamol"
    @State private var amount = "5"
    @State private var unit: MedicationUnit = .ml
    @State private var route: MedicationRoute = .oral
    @State private var time = Date()
    @State private var minimumIntervalHours = 6.0
    @State private var notes = ""
    @State private var allowConflict = false

    private var conflict: MedicationEntry? {
        store.medicationConflict(for: profile, name: name, at: time, minimumIntervalHours: minimumIntervalHours)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Medication") {
                    TextField("Medication name", text: $name)
                    HStack {
                        TextField("Dose", text: $amount)
                            .keyboardType(.decimalPad)

                        Picker("Unit", selection: $unit) {
                            ForEach(MedicationUnit.allCases) { unit in
                                Text(unit.title).tag(unit)
                            }
                        }
                    }

                    Picker("Route", selection: $route) {
                        ForEach(MedicationRoute.allCases) { route in
                            Text(route.title).tag(route)
                        }
                    }

                    DatePicker("Time", selection: $time)
                    Stepper("Minimum interval: \(Int(minimumIntervalHours))h", value: $minimumIntervalHours, in: 1...12, step: 1)
                    TextField("Notes", text: $notes, axis: .vertical)
                }

                if let conflict, !allowConflict {
                    Section {
                        VStack(alignment: .leading, spacing: 10) {
                            Label("Double-dose warning", systemImage: "exclamationmark.triangle.fill")
                                .font(.rounded(15, weight: .bold))
                                .foregroundStyle(Color.appAlert)

                            Text("\(conflict.loggedBy) logged \(conflict.name) at \(AppFormatters.time.string(from: conflict.time)). Review before saving another dose.")
                                .font(.rounded(13))
                                .foregroundStyle(Color.textSecondary)

                            Button("Still save this dose") {
                                allowConflict = true
                            }
                        }
                    }
                    .listRowBackground(Color.alertBackground)
                }

                Button {
                    store.addMedication(for: profile, name: name, amount: amount, unit: unit, route: route, time: time, minimumIntervalHours: minimumIntervalHours, notes: notes)
                    dismiss()
                } label: {
                    Label("Log Medication", systemImage: "pills.fill")
                }
                .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || amount.isEmpty || (conflict != nil && !allowConflict))
            }
            .navigationTitle("Medicine")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}

struct SymptomLogSheet: View {
    @EnvironmentObject private var store: BabyHealthStore
    @Environment(\.dismiss) private var dismiss
    var profile: BabyProfile

    @State private var symptom: SymptomKind = .fever
    @State private var severity: SymptomSeverity = .mild
    @State private var temperature = ""
    @State private var notes = ""

    var body: some View {
        NavigationStack {
            Form {
                Picker("Symptom", selection: $symptom) {
                    ForEach(SymptomKind.allCases) { symptom in
                        Text(symptom.title).tag(symptom)
                    }
                }

                Picker("Severity", selection: $severity) {
                    ForEach(SymptomSeverity.allCases) { severity in
                        Text(severity.title).tag(severity)
                    }
                }
                .pickerStyle(.segmented)

                TextField("Temperature C", text: $temperature)
                    .keyboardType(.decimalPad)
                TextField("Notes", text: $notes, axis: .vertical)

                Button {
                    let parsedTemperature = Double(temperature.replacingOccurrences(of: ",", with: "."))
                    store.addSymptom(for: profile, symptom: symptom, severity: severity, temperatureC: parsedTemperature, notes: notes)
                    dismiss()
                } label: {
                    Label("Log Symptom", systemImage: "thermometer.medium")
                }
            }
            .navigationTitle("Symptom")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}

struct GrowthLogSheet: View {
    @EnvironmentObject private var store: BabyHealthStore
    @Environment(\.dismiss) private var dismiss
    var profile: BabyProfile

    @State private var date = Date()
    @State private var weight = "10.2"
    @State private var height = "82"
    @State private var head = "46.7"
    @State private var notes = ""

    var body: some View {
        NavigationStack {
            Form {
                DatePicker("Date", selection: $date, displayedComponents: .date)
                TextField("Weight kg", text: $weight)
                    .keyboardType(.decimalPad)
                TextField("Height cm", text: $height)
                    .keyboardType(.decimalPad)
                TextField("Head circumference cm", text: $head)
                    .keyboardType(.decimalPad)
                TextField("Notes", text: $notes, axis: .vertical)

                Button {
                    store.addGrowth(
                        for: profile,
                        date: date,
                        weightKg: Double(weight.replacingOccurrences(of: ",", with: ".")) ?? 0,
                        heightCm: Double(height.replacingOccurrences(of: ",", with: ".")) ?? 0,
                        headCm: Double(head.replacingOccurrences(of: ",", with: ".")) ?? 0,
                        notes: notes
                    )
                    dismiss()
                } label: {
                    Label("Add Measurement", systemImage: "plus.circle.fill")
                }
            }
            .navigationTitle("Growth")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}

struct DoctorVisitSheet: View {
    @EnvironmentObject private var store: BabyHealthStore
    @Environment(\.dismiss) private var dismiss
    var profile: BabyProfile

    @State private var date = Date()
    @State private var doctorName = ""
    @State private var clinic = ""
    @State private var reason = ""
    @State private var diagnosis = ""
    @State private var prescriptions = ""
    @State private var hasFollowUp = false
    @State private var followUpDate = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
    @State private var notes = ""

    var body: some View {
        NavigationStack {
            Form {
                DatePicker("Visit date", selection: $date)
                TextField("Doctor", text: $doctorName)
                TextField("Clinic / hospital", text: $clinic)
                TextField("Reason", text: $reason, axis: .vertical)
                TextField("Diagnosis", text: $diagnosis, axis: .vertical)
                TextField("Prescriptions", text: $prescriptions, axis: .vertical)
                Toggle("Follow-up reminder", isOn: $hasFollowUp)
                if hasFollowUp {
                    DatePicker("Follow-up date", selection: $followUpDate)
                }
                TextField("Notes", text: $notes, axis: .vertical)

                Button {
                    store.addDoctorVisit(
                        for: profile,
                        date: date,
                        doctorName: doctorName,
                        clinic: clinic,
                        reason: reason,
                        diagnosis: diagnosis,
                        prescriptions: prescriptions,
                        followUpDate: hasFollowUp ? followUpDate : nil,
                        notes: notes
                    )
                    dismiss()
                } label: {
                    Label("Save Visit", systemImage: "calendar.badge.plus")
                }
            }
            .navigationTitle("Doctor Visit")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}

struct AddProfileSheet: View {
    @EnvironmentObject private var store: BabyHealthStore
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var dateOfBirth = Date()
    @State private var gender: BabyGender = .girl
    @State private var bloodType = ""

    var body: some View {
        NavigationStack {
            Form {
                TextField("Baby name", text: $name)
                DatePicker("Date of birth", selection: $dateOfBirth, displayedComponents: .date)
                Picker("Gender", selection: $gender) {
                    ForEach(BabyGender.allCases) { gender in
                        Text(gender.title).tag(gender)
                    }
                }
                TextField("Blood type optional", text: $bloodType)

                Button {
                    store.addProfile(name: name.isEmpty ? "Baby" : name, dateOfBirth: dateOfBirth, gender: gender, bloodType: bloodType)
                    dismiss()
                } label: {
                    Label("Add Baby Profile", systemImage: "person.crop.circle.badge.plus")
                }
            }
            .navigationTitle("New Profile")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}
