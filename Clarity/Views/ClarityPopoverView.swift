import SwiftUI
import AppKit

/// Shared menu-bar popover shell.
/// Stable geometry: fixed top navigation, flexible middle content, fixed footer.
struct ClarityPopoverView: View {
    @Environment(AppState.self) private var appState
    @Environment(PomodoroManager.self) private var pomodoro

    var body: some View {
        @Bindable var appState = appState

        VStack(spacing: 0) {
            topNavigation
                .padding(.top, 12)
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
                .zIndex(2)

            header
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
                .zIndex(1)

            tabContent
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .zIndex(0)

            if appState.selectedTab == .tasks, pomodoro.timerState != .idle {
                compactPomodoroStrip
            }

            footer
        }
        .frame(width: ClarityChrome.panelWidth, height: ClarityChrome.panelHeight)
        .background {
            NativeGlassBackground()
        }
        .clipShape(RoundedRectangle(cornerRadius: ClarityChrome.cornerRadius, style: .continuous))
        .overlay {
            GlassEdgeHighlight()
        }
        .shadow(color: .black.opacity(0.20), radius: 18, x: 0, y: 8)
        .onAppear {
            MenuBarGlassWindow.configureIfNeeded()
        }
    }

    // MARK: - Top navigation (explicit buttons — reliable single-click)

    private var topNavigation: some View {
        HStack(spacing: 0) {
            tabButton("Tasks", tab: .tasks)
            tabButton("Pomodoro", tab: .pomodoro)
        }
        .padding(3)
        .background { GlassTrack() }
        .frame(maxWidth: 268)
        .frame(maxWidth: .infinity)
    }

    private func tabButton(_ title: String, tab: AppTab) -> some View {
        let isSelected = appState.selectedTab == tab
        return Button {
            appState.selectedTab = tab
            if tab == .pomodoro {
                appState.isAddingTask = false
            }
        } label: {
            Text(title)
                .font(.system(size: 12, weight: isSelected ? .semibold : .medium))
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
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .center) {
            Text("Clarity")
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundStyle(.primary)

            Spacer(minLength: 8)

            if appState.selectedTab == .tasks {
                Button {
                    appState.isAddingTask = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: 26, height: 26)
                        .background {
                            Circle()
                                .fill(.thinMaterial)
                                .allowsHitTesting(false)
                        }
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .help("Add Task")
                .accessibilityLabel("Add Task")
                .keyboardShortcut("n", modifiers: .command)
                .disabled(appState.isAddingTask)
            }
        }
    }

    // MARK: - Content

    private var tabContent: some View {
        Group {
            switch appState.selectedTab {
            case .tasks:
                TasksView()
            case .pomodoro:
                PomodoroView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private var compactPomodoroStrip: some View {
        HStack(spacing: 10) {
            Image(systemName: "timer")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)
            Text(pomodoro.sessionType.title)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
            Text(pomodoro.formatTime(pomodoro.displayRemaining))
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.primary)

            Spacer(minLength: 8)

            Button(pomodoro.isRunning ? "Pause" : "Resume") {
                pomodoro.toggleStartPause()
            }
            .buttonStyle(.plain)
            .font(.system(size: 12, weight: .semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background { GlassSelectionCapsule() }
            .contentShape(Capsule())
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
    }

    // MARK: - Fixed footer

    private var footer: some View {
        HStack {
            Spacer(minLength: 0)
            Button {
                NSApplication.shared.terminate(nil)
            } label: {
                Image(systemName: "power")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.tertiary)
                    .frame(width: 28, height: 28)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help("Quit Clarity")
        }
        .padding(.horizontal, 12)
        .frame(height: ClarityChrome.footerHeight)
    }
}

struct MenuBarLabel: View {
    @Environment(PomodoroManager.self) private var pomodoro

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "checkmark.circle")
            if pomodoro.isRunning || pomodoro.isPaused {
                Text(pomodoro.formatTime(pomodoro.displayRemaining))
                    .monospacedDigit()
                    .font(.system(size: 12, weight: .medium))
            }
        }
    }
}
