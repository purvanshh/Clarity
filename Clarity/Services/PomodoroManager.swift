import Foundation
import AppKit
import Observation

@Observable
@MainActor
final class PomodoroManager {
    static let shared = PomodoroManager()

    private enum StorageKey {
        static let sessionType = "clarity.pomodoro.sessionType"
        static let timerState = "clarity.pomodoro.timerState"
        static let endDate = "clarity.pomodoro.endDate"
        static let remaining = "clarity.pomodoro.remaining"
        static let completedFocusCount = "clarity.pomodoro.completedFocusCount"
    }

    var sessionType: PomodoroSessionType = .focus
    var timerState: PomodoroTimerState = .idle
    /// Absolute end date while running.
    var endDate: Date?
    /// Remaining duration while paused or idle.
    var remainingWhenPaused: TimeInterval = PomodoroSessionType.focus.duration
    var completedFocusCount: Int = 0
    /// Display tick — updated on a short cadence for UI only.
    var displayRemaining: TimeInterval = PomodoroSessionType.focus.duration

    private var tickTask: Task<Void, Never>?
    private let defaults = UserDefaults.standard
    private let completionNotificationID = "clarity.pomodoro.sessionComplete"

    var isRunning: Bool { timerState == .running }
    var isPaused: Bool { timerState == .paused }

    var menuBarTitle: String {
        let time = formatTime(displayRemaining)
        switch timerState {
        case .running:
            return "\(sessionType.title) \(time)"
        case .paused:
            return "Paused \(time)"
        case .idle:
            return "Clarity"
        }
    }

    private init() {
        restore()
        reconcileWithWallClock()
        startTicking()
    }

    func selectSession(_ type: PomodoroSessionType) {
        guard timerState == .idle || timerState == .paused else { return }
        sessionType = type
        timerState = .idle
        endDate = nil
        remainingWhenPaused = type.duration
        displayRemaining = type.duration
        persist()
    }

    func toggleStartPause() {
        switch timerState {
        case .idle, .paused:
            start()
        case .running:
            pause()
        }
    }

    func start() {
        let remaining: TimeInterval
        if timerState == .paused {
            remaining = max(remainingWhenPaused, 1)
        } else {
            remaining = sessionType.duration
            remainingWhenPaused = remaining
        }

        endDate = Date().addingTimeInterval(remaining)
        timerState = .running
        displayRemaining = remaining
        persist()
        startTicking()
    }

    func pause() {
        guard timerState == .running, let endDate else { return }
        remainingWhenPaused = max(endDate.timeIntervalSinceNow, 0)
        self.endDate = nil
        timerState = .paused
        displayRemaining = remainingWhenPaused
        persist()
    }

    func reset() {
        timerState = .idle
        endDate = nil
        remainingWhenPaused = sessionType.duration
        displayRemaining = sessionType.duration
        NotificationManager.shared.cancelNotification(id: completionNotificationID)
        persist()
    }

    /// Call when app becomes active to correct drift after backgrounding.
    func reconcileWithWallClock() {
        guard timerState == .running, let endDate else {
            if timerState == .paused {
                displayRemaining = remainingWhenPaused
            } else if timerState == .idle {
                displayRemaining = remainingWhenPaused
            }
            return
        }

        let remaining = endDate.timeIntervalSinceNow
        if remaining <= 0 {
            handleSessionCompletion()
        } else {
            displayRemaining = remaining
        }
    }

    private func startTicking() {
        tickTask?.cancel()
        tickTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(250))
                guard let self else { return }
                self.tick()
            }
        }
    }

    private func tick() {
        guard timerState == .running, let endDate else { return }
        let remaining = endDate.timeIntervalSinceNow
        if remaining <= 0 {
            handleSessionCompletion()
        } else {
            displayRemaining = remaining
        }
    }

    private func handleSessionCompletion() {
        let finished = sessionType
        playCompletionSound()
        Task {
            await NotificationManager.shared.scheduleOneShot(
                id: completionNotificationID,
                title: finished.completionTitle,
                body: finished.completionBody,
                fireDate: Date().addingTimeInterval(0.5)
            )
        }

        if finished == .focus {
            completedFocusCount += 1
            sessionType = (completedFocusCount % 4 == 0) ? .longBreak : .shortBreak
        } else {
            sessionType = .focus
        }

        remainingWhenPaused = sessionType.duration
        displayRemaining = sessionType.duration
        endDate = nil
        timerState = .idle
        persist()
    }

    private func playCompletionSound() {
        NSSound(named: .init("Glass"))?.play()
    }

    func formatTime(_ interval: TimeInterval) -> String {
        let total = max(Int(interval.rounded(.up)), 0)
        let minutes = total / 60
        let seconds = total % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private func persist() {
        defaults.set(sessionType.rawValue, forKey: StorageKey.sessionType)
        defaults.set(timerState.rawValue, forKey: StorageKey.timerState)
        defaults.set(remainingWhenPaused, forKey: StorageKey.remaining)
        defaults.set(completedFocusCount, forKey: StorageKey.completedFocusCount)
        if let endDate {
            defaults.set(endDate.timeIntervalSince1970, forKey: StorageKey.endDate)
        } else {
            defaults.removeObject(forKey: StorageKey.endDate)
        }
    }

    private func restore() {
        if let raw = defaults.string(forKey: StorageKey.sessionType),
           let type = PomodoroSessionType(rawValue: raw) {
            sessionType = type
        }
        if let raw = defaults.string(forKey: StorageKey.timerState),
           let state = PomodoroTimerState(rawValue: raw) {
            timerState = state
        }
        remainingWhenPaused = defaults.object(forKey: StorageKey.remaining) as? TimeInterval
            ?? sessionType.duration
        completedFocusCount = defaults.integer(forKey: StorageKey.completedFocusCount)

        if timerState == .running,
           defaults.object(forKey: StorageKey.endDate) != nil {
            endDate = Date(timeIntervalSince1970: defaults.double(forKey: StorageKey.endDate))
        } else {
            endDate = nil
            if timerState == .running {
                timerState = .paused
            }
        }
        displayRemaining = endDate.map { max($0.timeIntervalSinceNow, 0) } ?? remainingWhenPaused
    }
}
