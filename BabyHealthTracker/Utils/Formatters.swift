import Foundation

enum AppFormatters {
    static let time: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter
    }()

    static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        return formatter
    }()

    static let weekday: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter
    }()

    static func relative(_ date: Date, to referenceDate: Date = Date()) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: referenceDate)
    }

    static func duration(_ interval: TimeInterval) -> String {
        let seconds = max(Int(interval), 0)
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let secs = seconds % 60

        if hours > 0 {
            return String(format: "%dh %02dm", hours, minutes)
        }

        if minutes > 0 {
            return String(format: "%dm %02ds", minutes, secs)
        }

        return "\(secs)s"
    }

    static func timer(_ interval: TimeInterval) -> String {
        let seconds = max(Int(interval), 0)
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let secs = seconds % 60

        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, secs)
        }

        return String(format: "%02d:%02d", minutes, secs)
    }

    static func hours(_ interval: TimeInterval) -> String {
        let hours = interval / 3600
        return hours >= 10 ? String(format: "%.0fh", hours) : String(format: "%.1fh", hours)
    }
}
