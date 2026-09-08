import SwiftUI

struct ClarityCommands: Commands {
    @Bindable var appState: AppState

    var body: some Commands {
        CommandGroup(replacing: .newItem) {
            Button("New Task") {
                appState.showAddTask()
            }
            .keyboardShortcut("n", modifiers: .command)
        }

        CommandGroup(after: .sidebar) {
            Button("Tasks") {
                appState.selectedTab = .tasks
            }
            .keyboardShortcut("1", modifiers: .command)

            Button("Pomodoro") {
                appState.selectedTab = .pomodoro
            }
            .keyboardShortcut("2", modifiers: .command)
        }

        CommandMenu("Pomodoro") {
            Button(PomodoroManager.shared.isRunning ? "Pause Timer" : "Start Timer") {
                PomodoroManager.shared.toggleStartPause()
            }

            Button("Reset Timer") {
                PomodoroManager.shared.reset()
            }
            .keyboardShortcut("r", modifiers: [.command, .shift])
        }
    }
}
