//
//  TaskDetailView.swift
//  MyDoList
//
//  Created by Arpit Patel on 04/12/25.
//

import SwiftData
import SwiftUI

struct TaskDetailView: View {
    let task: Task
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var viewModel: TasksViewModel
    @EnvironmentObject var appViewModel: AppViewModel
    @Environment(\.modelContext) private var modelContext

    @State private var isEditing = false
    @State private var editTitle = ""
    @State private var editNotes = ""
    @State private var editPriority: TaskPriority = .medium
    @State private var editHasDueDate = false
    @State private var editDueDate = Date()
    @State private var newSubtaskTitle = ""
    @State private var showingAddSubtask = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Task Header
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Button {
                                viewModel.toggleTaskCompletion(task)
                                appViewModel.triggerHaptic(.light)
                            } label: {
                                Image(
                                    systemName: task.isCompleted
                                        ? "checkmark.circle.fill" : "circle"
                                )
                                .font(.title)
                                .foregroundColor(task.isCompleted ? .green : .gray)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                if isEditing {
                                    TextField("Task title", text: $editTitle)
                                        .textFieldStyle(.roundedBorder)
                                        .font(.title2)
                                } else {
                                    Text(task.title)
                                        .font(.title2)
                                        .fontWeight(.semibold)
                                        .strikethrough(task.isCompleted)
                                        .foregroundColor(task.isCompleted ? .secondary : .primary)
                                }

                                HStack {
                                    Image(systemName: task.priority.iconName)
                                        .foregroundColor(task.priority.color)
                                    Text(task.priority.displayName)
                                        .foregroundColor(task.priority.color)

                                    if let dueDate = task.dueDate {
                                        Spacer()
                                        Text(dueDate, style: .date)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .font(.caption)
                            }

                            Spacer()
                        }

                        if task.isOverdue {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.red)
                                Text("This task is overdue")
                                    .foregroundColor(.red)
                            }
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)

                    // Notes Section
                    if !task.notes.isEmpty || isEditing {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Notes")
                                .font(.headline)

                            if isEditing {
                                TextField("Notes", text: $editNotes, axis: .vertical)
                                    .textFieldStyle(.roundedBorder)
                                    .lineLimit(3...10)
                            } else {
                                Text(task.notes.isEmpty ? "No notes" : task.notes)
                                    .foregroundColor(task.notes.isEmpty ? .secondary : .primary)
                            }
                        }
                        .padding()
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                    }

                    // Subtasks Section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Subtasks")
                                .font(.headline)

                            Spacer()

                            Button {
                                showingAddSubtask = true
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(.blue)
                            }
                        }

                        if task.subtasks.isEmpty {
                            Text("No subtasks yet")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        } else {
                            ForEach(task.subtasks.sorted(by: { $0.createdAt < $1.createdAt })) {
                                subtask in
                                SubtaskRowView(subtask: subtask)
                                    .environmentObject(viewModel)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)

                    // Task Info
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Task Information")
                            .font(.headline)

                        VStack(spacing: 8) {
                            InfoRow(
                                title: "Created",
                                value: task.createdAt.formatted(
                                    date: .abbreviated, time: .shortened))
                            InfoRow(
                                title: "Last Updated",
                                value: task.updatedAt.formatted(
                                    date: .abbreviated, time: .shortened))

                            if let completedAt = task.completedAt {
                                InfoRow(
                                    title: "Completed",
                                    value: completedAt.formatted(
                                        date: .abbreviated, time: .shortened))
                            }
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                }
                .padding()
            }
            .navigationTitle("Task Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") {
                        if isEditing {
                            saveChanges()
                        }
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button(isEditing ? "Save" : "Edit") {
                        if isEditing {
                            saveChanges()
                        } else {
                            startEditing()
                        }
                        isEditing.toggle()
                        appViewModel.triggerHaptic(.light)
                    }
                }
            }
            .alert("Add Subtask", isPresented: $showingAddSubtask) {
                TextField("Subtask title", text: $newSubtaskTitle)
                Button("Add") {
                    viewModel.addSubtask(to: task, title: newSubtaskTitle)
                    newSubtaskTitle = ""
                    appViewModel.triggerHaptic(.medium)
                }
                .disabled(newSubtaskTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                Button("Cancel", role: .cancel) {
                    newSubtaskTitle = ""
                }
            }
        }
        .onAppear {
            viewModel.setModelContext(modelContext)
            startEditing()
        }
    }

    private func startEditing() {
        editTitle = task.title
        editNotes = task.notes
        editPriority = task.priority
        editHasDueDate = task.dueDate != nil
        editDueDate = task.dueDate ?? Date()
    }

    private func saveChanges() {
        task.title = editTitle
        task.notes = editNotes
        task.priority = editPriority
        task.dueDate = editHasDueDate ? editDueDate : nil
        viewModel.updateTask(task)
    }
}

struct SubtaskRowView: View {
    let subtask: Subtask
    @EnvironmentObject var viewModel: TasksViewModel
    @EnvironmentObject var appViewModel: AppViewModel

    var body: some View {
        HStack {
            Button {
                viewModel.toggleSubtaskCompletion(subtask)
                appViewModel.triggerHaptic(.light)
            } label: {
                Image(systemName: subtask.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(subtask.isCompleted ? .green : .gray)
            }

            Text(subtask.title)
                .strikethrough(subtask.isCompleted)
                .foregroundColor(subtask.isCompleted ? .secondary : .primary)

            Spacer()
        }
        .padding(.vertical, 4)
    }
}

struct InfoRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
        }
        .font(.caption)
    }
}

#Preview {
    let task = Task(
        title: "Sample Task", notes: "This is a sample task with notes", priority: .high)
    return TaskDetailView(task: task)
        .environmentObject(TasksViewModel())
        .environmentObject(AppViewModel())
}
