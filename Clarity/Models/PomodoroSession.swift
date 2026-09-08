import Foundation

enum PomodoroSessionType: String, CaseIterable, Identifiable, Codable {
    case focus
    case shortBreak
    case longBreak

    var id: String { rawValue }

    var title: String {
        switch self {
        case .focus: return "Focus"
        case .shortBreak: return "Short Break"
        case .longBreak: return "Long Break"
        }
    }

    var duration: TimeInterval {
        switch self {
        case .focus: return 25 * 60
        case .shortBreak: return 5 * 60
        case .longBreak: return 15 * 60
        }
    }

    var completionTitle: String {
        switch self {
        case .focus: return "Focus session complete"
        case .shortBreak: return "Short break over"
        case .longBreak: return "Long break over"
        }
    }

    var completionBody: String {
        switch self {
        case .focus: return "Time for a short break."
        case .shortBreak: return "Ready for another focus session?"
        case .longBreak: return "Ready when you are."
        }
    }
}

enum PomodoroTimerState: String, Codable {
    case idle
    case running
    case paused
}
