import AppIntents
import SwiftData
import Foundation

struct AddTaskIntent: AppIntent {
    static let title: LocalizedStringResource = "Add Task to Clarity"
    static let description = IntentDescription("Adds a new task in Clarity.")
    static let openAppWhenRun: Bool = false

    @Parameter(title: "Task", description: "What needs to get done?", requestValueDialog: "What should I add to Clarity?")
    var taskTitle: String

    @Parameter(title: "Nudge Interval", description: "How often to remind you.", default: NudgeOption.none)
    var nudge: NudgeOption

    init() {
        self.taskTitle = ""
        self.nudge = .none
    }

    init(taskTitle: String, nudge: NudgeOption = .none) {
        self.taskTitle = taskTitle
        self.nudge = nudge
    }

    static var parameterSummary: some ParameterSummary {
        Summary("Add \(\.$taskTitle) to Clarity") {
            \.$nudge
        }
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let trimmed = taskTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw AddTaskIntentError.emptyTitle
        }

        let container: ModelContainer
        do {
            container = try ClarityPersistence.makeContainer()
        } catch {
            throw AddTaskIntentError.persistenceFailed
        }

        let context = ModelContext(container)
        let interval = nudge.timeInterval
        let task = ClarityTask(
            title: trimmed,
            reminderEnabled: interval != nil,
            reminderInterval: interval
        )
        context.insert(task)

        do {
            try context.save()
        } catch {
            throw AddTaskIntentError.persistenceFailed
        }

        await TaskReminderManager.shared.syncReminder(for: task)
        try? context.save()

        let dialog: IntentDialog
        if let interval, let label = ReminderInterval.displayLabel(for: interval) {
            dialog = IntentDialog("Added \"\(trimmed)\" with \(label.lowercased()).")
        } else {
            dialog = IntentDialog("Added \"\(trimmed)\" to Clarity.")
        }

        return .result(dialog: dialog)
    }
}

enum NudgeOption: String, AppEnum {
    case none
    case fifteenMinutes
    case thirtyMinutes
    case sixtyMinutes
    case twoHours

    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Nudge")

    static let caseDisplayRepresentations: [NudgeOption: DisplayRepresentation] = [
        .none: "No nudge",
        .fifteenMinutes: "Every 15 minutes",
        .thirtyMinutes: "Every 30 minutes",
        .sixtyMinutes: "Every 60 minutes",
        .twoHours: "Every 2 hours"
    ]

    var timeInterval: TimeInterval? {
        switch self {
        case .none: return nil
        case .fifteenMinutes: return 15 * 60
        case .thirtyMinutes: return 30 * 60
        case .sixtyMinutes: return 60 * 60
        case .twoHours: return 2 * 60 * 60
        }
    }
}

enum AddTaskIntentError: Error, CustomLocalizedStringResourceConvertible {
    case emptyTitle
    case persistenceFailed

    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .emptyTitle:
            return "Please provide a task title."
        case .persistenceFailed:
            return "Clarity couldn't save that task."
        }
    }
}

struct ClarityShortcuts: AppShortcutsProvider {
    /// Declared statically for App Intents metadata export. Registration is handled
    /// by the system; failures talking to `com.apple.linkd.autoShortcut` are OS XPC
    /// issues and must not be retried or suppressed from app code.
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: AddTaskIntent(),
            phrases: [
                "Add a task to \(.applicationName)",
                "Create a task in \(.applicationName)",
                "Remind me in \(.applicationName)",
                "Add something to \(.applicationName)"
            ],
            shortTitle: "Add Task",
            systemImageName: "checklist"
        )
    }
}
