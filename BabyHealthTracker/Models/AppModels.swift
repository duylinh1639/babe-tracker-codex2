import Foundation

struct BabyProfile: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String
    var dateOfBirth: Date
    var gender: BabyGender
    var bloodType: String?
    var isActive: Bool = false

    var initials: String {
        let parts = name.split(separator: " ")
        let letters = parts.prefix(2).compactMap { $0.first }
        return letters.isEmpty ? "B" : String(letters).uppercased()
    }

    func ageInMonths(on date: Date = Date()) -> Int {
        Calendar.current.dateComponents([.month], from: dateOfBirth, to: date).month ?? 0
    }

    func ageText(on date: Date = Date()) -> String {
        let components = Calendar.current.dateComponents([.year, .month], from: dateOfBirth, to: date)
        let years = components.year ?? 0
        let months = components.month ?? 0

        if years > 0 {
            return "\(years)y \(months)m"
        }

        return "\(max(months, 0))m"
    }
}

enum BabyGender: String, CaseIterable, Codable, Identifiable {
    case girl
    case boy
    case other

    var id: String { rawValue }

    var title: String {
        switch self {
        case .girl: return "Girl"
        case .boy: return "Boy"
        case .other: return "Other"
        }
    }
}

struct SleepEntry: Identifiable, Codable, Equatable {
    var id = UUID()
    var profileID: UUID
    var startTime: Date
    var endTime: Date?
    var kind: SleepKind
    var notes: String
    var loggedBy: String

    var isActive: Bool { endTime == nil }

    func durationSeconds(referenceDate: Date = Date()) -> TimeInterval {
        max((endTime ?? referenceDate).timeIntervalSince(startTime), 0)
    }

    func durationMinutes(referenceDate: Date = Date()) -> Int {
        Int(durationSeconds(referenceDate: referenceDate) / 60)
    }
}

enum SleepKind: String, CaseIterable, Codable, Identifiable {
    case nap
    case night

    var id: String { rawValue }
    var title: String { self == .nap ? "Nap" : "Night" }
}

struct DiaperEntry: Identifiable, Codable, Equatable {
    var id = UUID()
    var profileID: UUID
    var time: Date
    var kind: DiaperKind
    var condition: DiaperCondition
    var notes: String
    var loggedBy: String
}

enum DiaperKind: String, CaseIterable, Codable, Identifiable {
    case wet
    case dirty
    case both
    case dry

    var id: String { rawValue }

    var title: String {
        switch self {
        case .wet: return "Wet"
        case .dirty: return "Dirty"
        case .both: return "Both"
        case .dry: return "Dry"
        }
    }
}

enum DiaperCondition: String, CaseIterable, Codable, Identifiable {
    case normal
    case green
    case black
    case bloodTinged
    case hard
    case watery

    var id: String { rawValue }

    var title: String {
        switch self {
        case .normal: return "Normal"
        case .green: return "Green"
        case .black: return "Black"
        case .bloodTinged: return "Blood-tinged"
        case .hard: return "Hard"
        case .watery: return "Watery"
        }
    }
}

struct GrowthEntry: Identifiable, Codable, Equatable {
    var id = UUID()
    var profileID: UUID
    var date: Date
    var weightKg: Double
    var heightCm: Double
    var headCircumferenceCm: Double
    var notes: String
}

enum GrowthMetric: String, CaseIterable, Identifiable {
    case weight
    case height
    case head

    var id: String { rawValue }

    var title: String {
        switch self {
        case .weight: return "Weight"
        case .height: return "Height"
        case .head: return "Head"
        }
    }

    var unit: String {
        switch self {
        case .weight: return "kg"
        case .height, .head: return "cm"
        }
    }
}

struct VaccineRecord: Identifiable, Codable, Equatable {
    var id = UUID()
    var profileID: UUID
    var name: String
    var dose: String
    var dueDate: Date
    var completedDate: Date?
    var clinic: String
    var lotNumber: String
    var notes: String

    func status(on date: Date = Date()) -> VaccineStatus {
        if completedDate != nil {
            return .completed
        }

        let days = Calendar.current.dateComponents([.day], from: date.startOfDay, to: dueDate.startOfDay).day ?? 0
        if days < 0 {
            return .overdue(abs(days))
        }
        if days <= 30 {
            return .dueSoon(days)
        }
        return .notDue
    }
}

enum VaccineStatus: Equatable {
    case completed
    case dueSoon(Int)
    case overdue(Int)
    case notDue

    var sortPriority: Int {
        switch self {
        case .overdue: return 0
        case .dueSoon: return 1
        case .notDue: return 2
        case .completed: return 3
        }
    }

    var title: String {
        switch self {
        case .completed: return "Done"
        case .dueSoon: return "Soon"
        case .overdue: return "Overdue"
        case .notDue: return "Not due"
        }
    }

    var detail: String {
        switch self {
        case .completed: return "Completed"
        case .dueSoon(let days): return days == 0 ? "Due today" : "\(days)d left"
        case .overdue(let days): return "\(days)d overdue"
        case .notDue: return "Scheduled"
        }
    }
}

struct MedicationEntry: Identifiable, Codable, Equatable {
    var id = UUID()
    var profileID: UUID
    var name: String
    var amount: String
    var unit: MedicationUnit
    var route: MedicationRoute
    var time: Date
    var minimumIntervalHours: Double
    var notes: String
    var loggedBy: String

    var dosageText: String {
        "\(amount) \(unit.title)"
    }
}

enum MedicationUnit: String, CaseIterable, Codable, Identifiable {
    case ml
    case mg
    case tablet

    var id: String { rawValue }
    var title: String { rawValue }
}

enum MedicationRoute: String, CaseIterable, Codable, Identifiable {
    case oral
    case topical
    case inhaled

    var id: String { rawValue }

    var title: String {
        switch self {
        case .oral: return "Oral"
        case .topical: return "Topical"
        case .inhaled: return "Inhaled"
        }
    }
}

struct SymptomEntry: Identifiable, Codable, Equatable {
    var id = UUID()
    var profileID: UUID
    var time: Date
    var symptom: SymptomKind
    var severity: SymptomSeverity
    var temperatureC: Double?
    var notes: String
    var loggedBy: String
}

enum SymptomKind: String, CaseIterable, Codable, Identifiable {
    case fever
    case cough
    case runnyNose
    case rash
    case vomiting
    case diarrhea
    case appetiteLoss
    case irritability
    case other

    var id: String { rawValue }

    var title: String {
        switch self {
        case .fever: return "Fever"
        case .cough: return "Cough"
        case .runnyNose: return "Runny nose"
        case .rash: return "Rash"
        case .vomiting: return "Vomiting"
        case .diarrhea: return "Diarrhea"
        case .appetiteLoss: return "Loss of appetite"
        case .irritability: return "Irritability"
        case .other: return "Other"
        }
    }
}

enum SymptomSeverity: String, CaseIterable, Codable, Identifiable {
    case mild
    case moderate
    case severe

    var id: String { rawValue }

    var title: String {
        switch self {
        case .mild: return "Mild"
        case .moderate: return "Moderate"
        case .severe: return "Severe"
        }
    }
}

struct DoctorVisit: Identifiable, Codable, Equatable {
    var id = UUID()
    var profileID: UUID
    var date: Date
    var doctorName: String
    var clinic: String
    var reason: String
    var diagnosis: String
    var prescriptions: String
    var followUpDate: Date?
    var notes: String
}

extension Date {
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }
}
