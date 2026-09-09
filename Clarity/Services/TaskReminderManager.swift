import Foundation
import SwiftData
import UserNotifications

@MainActor
final class TaskReminderManager {
    static let shared = TaskReminderManager()

    private let notifications = NotificationManager.shared

    private init() {}

    /// Schedules or refreshes a task nudge.
    /// - Parameter force: When `true`, cancels and recreates the notification (create / interval change).
    ///   When `false`, keeps an existing pending notification so opening Clarity does not reset the timer.
    /// - Parameter promptIfNeeded: When `false`, never presents a notification-permission prompt (used from
    ///   headless App Intents so Siri isn't left waiting on a dialog that can't be shown).
    func syncReminder(for task: ClarityTask, force: Bool = true, promptIfNeeded: Bool = true) async {
        let id = task.notificationIdentifier

        guard task.reminderEnabled,
              !task.isCompleted,
              let interval = task.reminderInterval,
              interval >= 60 else {
            notifications.cancelNotification(id: id)
            task.nextReminderDate = nil
            return
        }

        if !force, let existing = await notifications.pendingRequest(id: id) {
            // Keep the running schedule; only refresh the displayed next-fire time.
            task.nextReminderDate = notifications.nextFireDate(for: existing)
                ?? task.nextReminderDate
                ?? Date().addingTimeInterval(interval)
            return
        }

        let next = await notifications.scheduleRepeatingReminder(
            id: id,
            title: "Clarity",
            body: task.title,
            interval: interval,
            promptIfNeeded: promptIfNeeded
        )
        task.nextReminderDate = next
    }

    func cancelReminder(for task: ClarityTask) {
        notifications.cancelNotification(id: task.notificationIdentifier)
        task.nextReminderDate = nil
    }

    /// Ensures every active nudged task has a pending notification without resetting timers.
    func ensureAllReminders(in context: ModelContext) async {
        let descriptor = FetchDescriptor<ClarityTask>()
        do {
            let tasks = try context.fetch(descriptor)
            let activeNudged = tasks.filter { $0.reminderEnabled && !$0.isCompleted }
            let activeIDs = Set(activeNudged.map(\.notificationIdentifier))

            // Drop orphaned notifications for deleted/completed tasks.
            let pendingIDs = await notifications.allPendingTaskReminderIDs()
            let orphans = pendingIDs.filter { !activeIDs.contains($0) }
            if !orphans.isEmpty {
                notifications.cancelNotifications(ids: orphans)
            }

            for task in activeNudged {
                await syncReminder(for: task, force: false)
            }
        } catch {
            // Persistence read failure — skip quietly.
        }
    }
}
