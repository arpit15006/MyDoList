//
//  TasksView.swift
//  MyDoList
//
//  Created by Arpit Patel on 04/12/25.
//

import SwiftData
import SwiftUI

struct TasksView: View {
    let list: DoList
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var appViewModel: AppViewModel
    @StateObject private var viewModel = TasksViewModel()
    @Query private var allTasks: [Task]

    var tasks: [Task] {
        list.tasks
    }

    var body: some View {
        Group {
            if tasks.isEmpty {
                TasksEmptyStateView(listName: list.title)
            } else {
                List {
                    ForEach(filteredTasks) { task in
                        TaskRowView(task: task)
                            .environmentObject(viewModel)
                    }
                    .onDelete(perform: deleteTasks)
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle(list.title)
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: $viewModel.searchText, prompt: "Search tasks...")
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Menu {
                    Picker("Filter", selection: $viewModel.selectedFilter) {
                        ForEach(TasksViewModel.TaskFilter.allCases, id: \.self) { filter in
                            Text(filter.rawValue).tag(filter)
                        }
                    }

                    Divider()

                    Picker("Sort by", selection: $viewModel.selectedSortOption) {
                        ForEach(TasksViewModel.TaskSortOption.allCases, id: \.self) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                } label: {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                }

                Button {
                    viewModel.showingCreateTask = true
                    appViewModel.triggerHaptic(.light)
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $viewModel.showingCreateTask) {
            CreateTaskView(list: list)
                .environmentObject(viewModel)
        }

        .onAppear {
            viewModel.setModelContext(modelContext)
        }
    }

    private var filteredTasks: [Task] {
        let filtered =
            viewModel.searchText.isEmpty
            ? tasks
            : tasks.filter {
                $0.title.localizedCaseInsensitiveContains(viewModel.searchText)
                    || $0.notes.localizedCaseInsensitiveContains(viewModel.searchText)
            }

        let filteredByStatus = filtered.filter { task in
            switch viewModel.selectedFilter {
            case .all: return true
            case .pending: return !task.isCompleted
            case .completed: return task.isCompleted
            case .overdue: return task.isOverdue
            case .dueToday: return task.isDueToday
            case .highPriority: return task.priority == .high || task.priority == .urgent
            }
        }

        return filteredByStatus.sorted { task1, task2 in
            switch viewModel.selectedSortOption {
            case .dateCreated:
                return task1.createdAt > task2.createdAt
            case .dueDate:
                if let date1 = task1.dueDate, let date2 = task2.dueDate {
                    return date1 < date2
                }
                return task1.dueDate != nil
            case .priority:
                return task1.priority.rawValue > task2.priority.rawValue
            case .alphabetical:
                return task1.title < task2.title
            }
        }
    }

    private func deleteTasks(offsets: IndexSet) {
        for index in offsets {
            viewModel.deleteTask(filteredTasks[index])
        }
        appViewModel.triggerHaptic(.medium)
    }
}

struct TaskRowView: View {
    let task: Task
    @EnvironmentObject var viewModel: TasksViewModel
    @EnvironmentObject var appViewModel: AppViewModel
    @State private var showingTaskDetail = false

    var body: some View {
        HStack(spacing: 12) {
            Button {
                viewModel.toggleTaskCompletion(task)
                appViewModel.triggerHaptic(.light)
            } label: {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(task.isCompleted ? .green : .gray)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(task.title)
                        .font(.body)
                        .strikethrough(task.isCompleted)
                        .foregroundColor(task.isCompleted ? .secondary : .primary)

                    Spacer()

                    if task.isOverdue {
                        Text("Overdue")
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.red.opacity(0.1))
                            .foregroundColor(.red)
                            .cornerRadius(4)
                    } else if task.isDueToday {
                        Text("Today")
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.orange.opacity(0.1))
                            .foregroundColor(.orange)
                            .cornerRadius(4)
                    }
                }

                if !task.notes.isEmpty {
                    Text(task.notes)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                HStack {
                    Image(systemName: task.priority.iconName)
                        .font(.caption)
                        .foregroundColor(task.priority.color)

                    Text(task.priority.displayName)
                        .font(.caption)
                        .foregroundColor(task.priority.color)

                    if let dueDate = task.dueDate {
                        Spacer()
                        Text(dueDate, style: .date)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    if task.totalSubtasksCount > 0 {
                        Spacer()
                        Text("\(task.completedSubtasksCount)/\(task.totalSubtasksCount)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            showingTaskDetail = true
        }
        .sheet(isPresented: $showingTaskDetail) {
            TaskDetailView(task: task)
                .environmentObject(viewModel)
        }
    }
}

struct TasksEmptyStateView: View {
    let listName: String

    var body: some View {
        ContentUnavailableView(
            "No Tasks in \(listName)",
            systemImage: "checkmark.circle",
            description: Text("Add your first task to start being productive!")
        )
    }
}

#Preview {
    let container = try! ModelContainer(
        for: DoList.self, Task.self, Subtask.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    let list = DoList(title: "Work Tasks")

    return TasksView(list: list)
        .environmentObject(AppViewModel())
        .modelContainer(container)
}
