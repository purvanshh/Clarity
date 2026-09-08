import SwiftUI
import SwiftData

/// Compact inline composer for the menu-bar popover (no separate window).
struct InlineAddTaskView: View {
    var onCancel: () -> Void
    var onSaved: () -> Void

    @Environment(\.modelContext) private var modelContext

    @State private var title = ""
    @State private var selectedInterval: ReminderInterval = .none
    @State private var errorMessage: String?
    @State private var isSaving = false
    @FocusState private var titleFocused: Bool

    private let quickNudges: [(ReminderInterval, String)] = [
        (.none, "None"),
        (.fifteenMinutes, "15m"),
        (.thirtyMinutes, "30m"),
        (.sixtyMinutes, "60m"),
        (.twoHours, "2h")
    ]

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isSaving
    }

    var body: some View {
        GlassSurface(cornerRadius: 12) {
            VStack(alignment: .leading, spacing: 10) {
                Text("What needs to be done?")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)

                TextField("Task title", text: $title)
                    .textFieldStyle(.plain)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(.quaternary.opacity(0.35), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .focused($titleFocused)
                    .onSubmit { save() }

                HStack(spacing: 5) {
                    Text("Nudge")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)

                    ForEach(quickNudges, id: \.0) { item in
                        Button(item.1) {
                            selectedInterval = item.0
                        }
                        .buttonStyle(.plain)
                        .font(.system(size: 11, weight: selectedInterval == item.0 ? .semibold : .regular))
                        .foregroundStyle(selectedInterval == item.0 ? .primary : .secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background {
                            if selectedInterval == item.0 {
                                Capsule().fill(.thinMaterial)
                            }
                        }
                    }
                }

                if let errorMessage {
                    Text(errorMessage)
                        .font(.system(size: 11))
                        .foregroundStyle(.red)
                }

                HStack {
                    Button("Cancel") { onCancel() }
                        .buttonStyle(.plain)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .keyboardShortcut(.cancelAction)

                    Spacer()

                    Button("Add") { save() }
                        .buttonStyle(.plain)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.primary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 5)
                        .background(.thinMaterial, in: Capsule())
                        .keyboardShortcut(.defaultAction)
                        .disabled(!canSave)
                        .opacity(canSave ? 1 : 0.45)
                }
            }
            .padding(12)
        }
        .onAppear { titleFocused = true }
        .onExitCommand { onCancel() }
    }

    private func save() {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            errorMessage = "A task title is required."
            return
        }

        isSaving = true
        errorMessage = nil

        let interval = selectedInterval.timeInterval
        let task = ClarityTask(
            title: trimmed,
            reminderEnabled: interval != nil,
            reminderInterval: interval
        )

        modelContext.insert(task)

        do {
            try modelContext.save()
            Task {
                await TaskReminderManager.shared.syncReminder(for: task)
                try? modelContext.save()
                onSaved()
            }
        } catch {
            modelContext.delete(task)
            errorMessage = "Couldn't save this task."
            isSaving = false
        }
    }
}
