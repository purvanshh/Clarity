import Foundation
import SwiftData

@MainActor
final class TaskReminderManager {
    static let shared = TaskReminderManager()

    private let notifications = NotificationManager.shared

    private init() {}

    func syncReminder(for task: ClarityTask) async {
        let id = task.notificationIdentifier

        guard task.reminderEnabled,
              !task.isCompleted,
              let interval = task.reminderInterval,
              interval >= 60 else {
            notifications.cancelNotification(id: id)
            task.nextReminderDate = nil
            return
        }

        let next = Date().addingTimeInterval(interval)
        task.nextReminderDate = next

        await notifications.scheduleRepeatingReminder(
            id: id,
            title: "Clarity",
            body: task.title,
            interval: interval
        )
    }

    func cancelReminder(for task: ClarityTask) {
        notifications.cancelNotification(id: task.notificationIdentifier)
        task.nextReminderDate = nil
    }

    func rescheduleAll(in context: ModelContext) async {
        // Avoid Bool `#Predicate` KeyPath Sendable warnings under complete concurrency checking.
        let descriptor = FetchDescriptor<ClarityTask>()
        do {
            let tasks = try context.fetch(descriptor).filter { $0.reminderEnabled && !$0.isCompleted }
            for task in tasks {
                await syncReminder(for: task)
            }
        } catch {
            // Persistence read failure — skip reschedule quietly.
        }
    }
}
