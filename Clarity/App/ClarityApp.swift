import SwiftUI
import SwiftData
import AppKit

@main
struct ClarityApp: App {
    @State private var appState = AppState()
    @NSApplicationDelegateAdaptor(ClarityAppDelegate.self) private var appDelegate

    private let modelContainer: ModelContainer
    private let persistenceFailed: Bool

    init() {
        if let container = try? ClarityPersistence.makeContainer() {
            modelContainer = container
            persistenceFailed = false
        } else {
            modelContainer = try! ModelContainer(
                for: Schema([ClarityTask.self]),
                configurations: [ModelConfiguration(isStoredInMemoryOnly: true)]
            )
            persistenceFailed = true
        }
    }

    var body: some Scene {
        MenuBarExtra {
            Group {
                if persistenceFailed {
                    VStack(spacing: 10) {
                        Text("Clarity couldn't open its library.")
                            .font(.headline)
                        Text("Quit and relaunch. If this keeps happening, check disk permissions.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                        Button("Quit Clarity") {
                            NSApplication.shared.terminate(nil)
                        }
                    }
                    .padding(20)
                    .frame(width: ClarityChrome.panelWidth, height: ClarityChrome.panelHeight)
                    .background { NativeGlassBackground() }
                    .clipShape(RoundedRectangle(cornerRadius: ClarityChrome.cornerRadius, style: .continuous))
                    .overlay { GlassEdgeHighlight() }
                } else {
                    ClarityPopoverView()
                        .environment(appState)
                        .environment(PomodoroManager.shared)
                        .onAppear {
                            appDelegate.appState = appState
                            Task {
                                await TaskReminderManager.shared.rescheduleAll(
                                    in: modelContainer.mainContext
                                )
                                PomodoroManager.shared.reconcileWithWallClock()
                            }
                        }
                }
            }
            .clearMenuBarContainerBackground()
            .onAppear { MenuBarGlassWindow.configureIfNeeded() }
        } label: {
            MenuBarLabel()
                .environment(PomodoroManager.shared)
        }
        .menuBarExtraStyle(.window)
        .modelContainer(modelContainer)
        .commands {
            ClarityCommands(appState: appState)
        }
    }
}

final class ClarityAppDelegate: NSObject, NSApplicationDelegate {
    var appState: AppState?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        // App Intents / App Shortcuts register automatically via AppShortcutsProvider.
        // Do not manually talk to linkd — XPC failures there are OS-service issues.
    }

    func applicationDidBecomeActive(_ notification: Notification) {
        PomodoroManager.shared.reconcileWithWallClock()
        MenuBarGlassWindow.configureIfNeeded()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }
}
