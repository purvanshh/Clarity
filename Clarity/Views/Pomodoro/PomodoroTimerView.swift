import SwiftUI

struct PomodoroTimerView: View {
    @Environment(PomodoroManager.self) private var pomodoro

    var body: some View {
        VStack(spacing: 4) {
            Text(pomodoro.sessionType.title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .tracking(0.8)

            Text(pomodoro.formatTime(pomodoro.displayRemaining))
                .font(.system(size: 48, weight: .light, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.primary)
                .contentTransition(.numericText())
                .animation(.easeInOut(duration: 0.2), value: Int(pomodoro.displayRemaining))

            Text(statusLabel)
                .font(.system(size: 11))
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
    }

    private var statusLabel: String {
        switch pomodoro.timerState {
        case .idle: return "Ready"
        case .running: return "In progress"
        case .paused: return "Paused"
        }
    }
}
