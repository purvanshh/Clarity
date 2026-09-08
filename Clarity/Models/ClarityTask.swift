import Foundation
import SwiftData

/// Persisted task model. Named `ClarityTask` to avoid clashing with Swift concurrency `Task`.
@Model
final class ClarityTask {
    @Attribute(.unique) var id: UUID
    var title: String
    var isCompleted: Bool
    var createdAt: Date
    var completedAt: Date?
    var reminderEnabled: Bool
    /// Reminder interval in seconds. `nil` when reminders are disabled.
    var reminderInterval: TimeInterval?
    var nextReminderDate: Date?

    init(
        id: UUID = UUID(),
        title: String,
        isCompleted: Bool = false,
        createdAt: Date = .now,
        completedAt: Date? = nil,
        reminderEnabled: Bool = false,
        reminderInterval: TimeInterval? = nil,
        nextReminderDate: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
        self.createdAt = createdAt
        self.completedAt = completedAt
        self.reminderEnabled = reminderEnabled
        self.reminderInterval = reminderInterval
        self.nextReminderDate = nextReminderDate
    }

    var notificationIdentifier: String {
        "clarity.task.\(id.uuidString)"
    }
}
