import SwiftUI
import Observation

enum AppTab: String, CaseIterable, Identifiable {
    case tasks
    case pomodoro

    var id: String { rawValue }

    var title: String {
        switch self {
        case .tasks: return "Tasks"
        case .pomodoro: return "Pomodoro"
        }
    }
}

@Observable
@MainActor
final class AppState {
    var selectedTab: AppTab = .tasks
    var isAddingTask = false

    func showAddTask() {
        selectedTab = .tasks
        isAddingTask = true
    }

    func cancelAddTask() {
        isAddingTask = false
    }
}
