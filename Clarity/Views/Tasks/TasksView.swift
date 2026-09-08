import SwiftUI
import SwiftData

struct TasksView: View {
    @Environment(AppState.self) private var appState

    @Query(sort: \ClarityTask.createdAt, order: .reverse)
    private var allTasks: [ClarityTask]

    private var tasks: [ClarityTask] {
        allTasks.filter { !$0.isCompleted } + allTasks.filter { $0.isCompleted }
    }

    var body: some View {
        @Bindable var appState = appState

        VStack(alignment: .leading, spacing: 0) {
            if appState.isAddingTask {
                InlineAddTaskView(
                    onCancel: { appState.cancelAddTask() },
                    onSaved: { appState.cancelAddTask() }
                )
                .padding(.horizontal, 14)
                .padding(.bottom, 8)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

            if tasks.isEmpty && !appState.isAddingTask {
                emptyState
                    .padding(.horizontal, 16)
                    .padding(.top, 20)
                Spacer(minLength: 0)
            } else if !tasks.isEmpty {
                taskList
            } else {
                Spacer(minLength: 0)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .animation(.easeInOut(duration: 0.15), value: appState.isAddingTask)
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Text("Nothing demanding your attention.")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
            Button {
                appState.isAddingTask = true
            } label: {
                Label("Add Task", systemImage: "plus")
                    .font(.system(size: 12, weight: .medium))
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var taskList: some View {
        ScrollView {
            LazyVStack(spacing: 2) {
                ForEach(tasks) { task in
                    TaskRow(task: task)
                }
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 4)
        }
        .scrollIndicators(.never)
    }
}
