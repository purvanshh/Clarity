import Foundation

enum ReminderInterval: String, CaseIterable, Identifiable, Codable {
    case none
    case fifteenMinutes
    case thirtyMinutes
    case sixtyMinutes
    case twoHours
    case custom

    var id: String { rawValue }

    var title: String {
        switch self {
        case .none: return "No nudge"
        case .fifteenMinutes: return "Every 15 minutes"
        case .thirtyMinutes: return "Every 30 minutes"
        case .sixtyMinutes: return "Every 60 minutes"
        case .twoHours: return "Every 2 hours"
        case .custom: return "Custom"
        }
    }

    var timeInterval: TimeInterval? {
        switch self {
        case .none: return nil
        case .fifteenMinutes: return 15 * 60
        case .thirtyMinutes: return 30 * 60
        case .sixtyMinutes: return 60 * 60
        case .twoHours: return 2 * 60 * 60
        case .custom: return nil
        }
    }

    static func matching(seconds: TimeInterval?) -> ReminderInterval {
        guard let seconds else { return .none }
        switch seconds {
        case 15 * 60: return .fifteenMinutes
        case 30 * 60: return .thirtyMinutes
        case 60 * 60: return .sixtyMinutes
        case 2 * 60 * 60: return .twoHours
        default: return .custom
        }
    }

    static func displayLabel(for seconds: TimeInterval?) -> String? {
        guard let seconds, seconds > 0 else { return nil }
        let preset = matching(seconds: seconds)
        if preset != .custom {
            return preset.title.replacingOccurrences(of: "Every ", with: "Nudge every ")
        }
        let minutes = Int(seconds / 60)
        if minutes >= 60, minutes % 60 == 0 {
            let hours = minutes / 60
            return "Nudge every \(hours) hr\(hours == 1 ? "" : "s")"
        }
        return "Nudge every \(minutes) min"
    }
}
