import Foundation
import UserNotifications

@MainActor
final class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()

    private let center = UNUserNotificationCenter.current()
    private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined

    private override init() {
        super.init()
    }

    /// Must be called once at launch so banners show while Clarity is running in the menu bar.
    func configure() {
        center.delegate = self
        Task { await refreshAuthorizationStatus() }
    }

    /// True when notifications are already granted and can be scheduled without prompting.
    var isAuthorized: Bool {
        switch authorizationStatus {
        case .authorized, .provisional, .ephemeral: return true
        default: return false
        }
    }

    func refreshAuthorizationStatus() async {
        let settings = await center.notificationSettings()
        authorizationStatus = settings.authorizationStatus
    }

    @discardableResult
    func requestAuthorizationIfNeeded() async -> Bool {
        await refreshAuthorizationStatus()
        switch authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return true
        case .denied:
            return false
        case .notDetermined:
            do {
                let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
                await refreshAuthorizationStatus()
                return granted
            } catch {
                await refreshAuthorizationStatus()
                return false
            }
        @unknown default:
            return false
        }
    }

    func pendingRequest(id: String) async -> UNNotificationRequest? {
        let pending = await center.pendingNotificationRequests()
        return pending.first { $0.identifier == id }
    }

    func nextFireDate(for request: UNNotificationRequest) -> Date? {
        if let intervalTrigger = request.trigger as? UNTimeIntervalNotificationTrigger {
            return intervalTrigger.nextTriggerDate()
        }
        if let calendarTrigger = request.trigger as? UNCalendarNotificationTrigger {
            return calendarTrigger.nextTriggerDate()
        }
        return nil
    }

    /// Schedules a repeating local nudge. Replaces any existing request with the same id.
    /// - Parameter promptIfNeeded: When `true` (default), prompts for authorization if the status is
    ///   `.notDetermined`. When `false`, never prompts — it only schedules if authorization was already
    ///   granted. Use `false` from a headless App Intent, where a permission prompt cannot be presented
    ///   and would leave Siri waiting indefinitely.
    func scheduleRepeatingReminder(
        id: String,
        title: String,
        body: String,
        interval: TimeInterval,
        promptIfNeeded: Bool = true
    ) async -> Date? {
        guard interval >= 60 else { return nil }

        if promptIfNeeded {
            let granted = await requestAuthorizationIfNeeded()
            guard granted else { return nil }
        } else {
            await refreshAuthorizationStatus()
            guard isAuthorized else { return nil }
        }

        cancelNotification(id: id)

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.interruptionLevel = .active

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: true)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)

        do {
            try await center.add(request)
            return trigger.nextTriggerDate() ?? Date().addingTimeInterval(interval)
        } catch {
            return nil
        }
    }

    func scheduleOneShot(
        id: String,
        title: String,
        body: String,
        fireDate: Date
    ) async {
        let granted = await requestAuthorizationIfNeeded()
        guard granted else { return }

        cancelNotification(id: id)

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.interruptionLevel = .active

        let interval = max(fireDate.timeIntervalSinceNow, 1)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)

        do {
            try await center.add(request)
        } catch {
            // Ignore scheduling failures.
        }
    }

    func cancelNotification(id: String) {
        center.removePendingNotificationRequests(withIdentifiers: [id])
        center.removeDeliveredNotifications(withIdentifiers: [id])
    }

    func cancelNotifications(ids: [String]) {
        center.removePendingNotificationRequests(withIdentifiers: ids)
        center.removeDeliveredNotifications(withIdentifiers: ids)
    }

    func allPendingTaskReminderIDs() async -> [String] {
        let pending = await center.pendingNotificationRequests()
        return pending.map(\.identifier).filter { $0.hasPrefix("clarity.task.") }
    }

    // MARK: - UNUserNotificationCenterDelegate

    /// Menu-bar apps are always "running", so without this, macOS may suppress banners.
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .list, .sound]
    }
}
