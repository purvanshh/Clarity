import SwiftUI

struct PomodoroView: View {
    @Environment(PomodoroManager.self) private var pomodoro

    var body: some View {
        VStack(spacing: 16) {
            sessionPicker
                .padding(.horizontal, 14)

            PomodoroTimerView()
                .padding(.horizontal, 14)

            controls
                .padding(.horizontal, 14)

            Spacer(minLength: 0)
        }
        .padding(.top, 4)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        // Intentionally not `.focusable()` — that caused a large blue focus ring
        // around the entire Pomodoro content area.
    }

    private var sessionPicker: some View {
        HStack(spacing: 0) {
            ForEach(PomodoroSessionType.allCases) { type in
                sessionButton(type)
            }
        }
        .padding(3)
        .background { GlassTrack() }
    }

    private func sessionButton(_ type: PomodoroSessionType) -> some View {
        let isSelected = pomodoro.sessionType == type
        return Button {
            pomodoro.selectSession(type)
        } label: {
            Text(shortTitle(type))
                .font(.system(size: 11, weight: isSelected ? .semibold : .medium))
                .foregroundStyle(isSelected ? .primary : .secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 7)
                .contentShape(Rectangle())
                .background {
                    if isSelected {
                        GlassSelectionCapsule()
                    }
                }
        }
        .buttonStyle(.plain)
        .disabled(pomodoro.isRunning && pomodoro.sessionType != type)
    }

    private func shortTitle(_ type: PomodoroSessionType) -> String {
        switch type {
        case .focus: return "Focus 25"
        case .shortBreak: return "Short 5"
        case .longBreak: return "Long 15"
        }
    }

    private var controls: some View {
        HStack(spacing: 10) {
            Button(pomodoro.isRunning ? "Pause" : "Start") {
                pomodoro.toggleStartPause()
            }
            .buttonStyle(.plain)
            .font(.system(size: 13, weight: .semibold))
            .padding(.horizontal, 16)
            .padding(.vertical, 7)
            .background { GlassSelectionCapsule() }
            .contentShape(Capsule())

            Button("Reset") {
                pomodoro.reset()
            }
            .buttonStyle(.plain)
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background {
                Capsule()
                    .fill(.ultraThinMaterial.opacity(0.45))
                    .allowsHitTesting(false)
            }
            .contentShape(Capsule())
            .disabled(pomodoro.timerState == .idle
                      && abs(pomodoro.displayRemaining - pomodoro.sessionType.duration) < 0.5)
        }
    }
}
