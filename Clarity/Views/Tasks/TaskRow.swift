import SwiftUI
import SwiftData

struct TaskRow: View {
    @Bindable var task: ClarityTask
    @Environment(\.modelContext) private var modelContext
    @State private var isHovered = false

    private let nudgeChoices: [(ReminderInterval, String)] = [
        (.none, "No nudge"),
        (.fifteenMinutes, "Every 15 min"),
        (.thirtyMinutes, "Every 30 min"),
        (.sixtyMinutes, "Every 60 min"),
        (.twoHours, "Every 2 hours")
    ]

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Button {
                toggleCompletion()
            } label: {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(task.isCompleted ? Color.accentColor.opacity(0.9) : Color.secondary.opacity(0.85))
            }
            .buttonStyle(.borderless)
            .accessibilityLabel(task.isCompleted ? "Mark incomplete" : "Mark complete")
            .padding(.top, 1)

            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .font(.system(size: 13, weight: .medium))
                    .strikethrough(task.isCompleted, color: .secondary)
                    .foregroundStyle(task.isCompleted ? .secondary : .primary)
                    .lineLimit(2)

                if let nudge = compactNudgeLabel, !task.isCompleted {
                    Text(nudge)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: 4)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(.thinMaterial.opacity(isHovered ? 0.55 : 0))
                .allowsHitTesting(false)
        }
        .contentShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .opacity(task.isCompleted ? 0.55 : 1)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.12)) {
                isHovered = hovering
            }
        }
        .contextMenu {
            Button(task.isCompleted ? "Mark Incomplete" : "Complete") {
                toggleCompletion()
            }

            Menu("Change Nudge") {
                ForEach(nudgeChoices, id: \.0) { choice in
                    Button(choice.1) {
                        applyNudge(choice.0)
                    }
                }
            }
            .disabled(task.isCompleted)

            Divider()

            Button("Delete", role: .destructive) {
                deleteTask()
            }
        }
    }

    private var compactNudgeLabel: String? {
        guard task.reminderEnabled, let seconds = task.reminderInterval else { return nil }
        switch ReminderInterval.matching(seconds: seconds) {
        case .fifteenMinutes: return "Nudge · 15 min"
        case .thirtyMinutes: return "Nudge · 30 min"
        case .sixtyMinutes: return "Nudge · 60 min"
        case .twoHours: return "Nudge · 2 hr"
        case .custom:
            let minutes = Int(seconds / 60)
            return "Nudge · \(minutes) min"
        case .none:
            return nil
        }
    }

    private func toggleCompletion() {
        task.isCompleted.toggle()
        task.completedAt = task.isCompleted ? .now : nil

        Task {
            if task.isCompleted {
                TaskReminderManager.shared.cancelReminder(for: task)
            } else {
                await TaskReminderManager.shared.syncReminder(for: task)
            }
            try? modelContext.save()
        }
    }

    private func applyNudge(_ interval: ReminderInterval) {
        let seconds = interval.timeInterval
        task.reminderEnabled = seconds != nil
        task.reminderInterval = seconds

        Task {
            await TaskReminderManager.shared.syncReminder(for: task)
            try? modelContext.save()
        }
    }

    private func deleteTask() {
        TaskReminderManager.shared.cancelReminder(for: task)
        modelContext.delete(task)
        try? modelContext.save()
    }
}
