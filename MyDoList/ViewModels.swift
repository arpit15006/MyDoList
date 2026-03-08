//
//  ViewModels.swift
//  MyDoList
//
//  Created by Arpit Patel on 04/12/25.
//

import Combine
import Foundation
import SwiftData
import SwiftUI

@MainActor
class ListsViewModel: ObservableObject {
    @Published var searchText = ""
    @Published var selectedSortOption: SortOption = .dateCreated
    @Published var showingCreateList = false
    @Published var selectedList: DoList?

    private var modelContext: ModelContext?

    enum SortOption: String, CaseIterable {
        case dateCreated = "Date Created"
        case alphabetical = "Alphabetical"
        case taskCount = "Task Count"
        case progress = "Progress"
    }

    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }

    func createList(title: String, colorHex: String, iconName: String) {
        guard let context = modelContext else { return }
        let newList = DoList(title: title, colorHex: colorHex, iconName: iconName)
        context.insert(newList)
        do {
            try context.save()
        } catch {
            print("Failed to save list: \(error)")
        }
    }

    func deleteList(_ list: DoList) {
        guard let context = modelContext else { return }
        context.delete(list)
        try? context.save()
    }

    func updateList(_ list: DoList) {
        guard let context = modelContext else { return }
        list.updatedAt = Date()
        try? context.save()
    }
}

@MainActor
class TasksViewModel: ObservableObject {
    @Published var searchText = ""
    @Published var selectedFilter: TaskFilter = .all
    @Published var selectedSortOption: TaskSortOption = .dateCreated
    @Published var showingCreateTask = false
    @Published var selectedTask: Task?

    private var modelContext: ModelContext?

    enum TaskFilter: String, CaseIterable {
        case all = "All"
        case pending = "Pending"
        case completed = "Completed"
        case overdue = "Overdue"
        case dueToday = "Due Today"
        case highPriority = "High Priority"
    }

    enum TaskSortOption: String, CaseIterable {
        case dateCreated = "Date Created"
        case dueDate = "Due Date"
        case priority = "Priority"
        case alphabetical = "Alphabetical"
    }

    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }

    func createTask(
        title: String, notes: String, priority: TaskPriority, dueDate: Date?, list: DoList
    ) {
        guard let context = modelContext else { return }
        let newTask = Task(title: title, notes: notes, priority: priority, dueDate: dueDate)
        newTask.list = list
        context.insert(newTask)

        do {
            try context.save()
            // Schedule notification after successfully saving and gaining a persistent ID
            NotificationManager.shared.scheduleNotification(for: newTask)
        } catch {
            print("Failed to save and schedule task: \(error)")
        }
    }

    func toggleTaskCompletion(_ task: Task) {
        guard let context = modelContext else { return }
        task.isCompleted.toggle()
        task.completedAt = task.isCompleted ? Date() : nil
        task.updatedAt = Date()
        try? context.save()

        if task.isCompleted {
            NotificationManager.shared.removeNotification(for: task)
        } else if task.dueDate != nil {
            NotificationManager.shared.scheduleNotification(for: task)
        }
    }

    func deleteTask(_ task: Task) {
        guard let context = modelContext else { return }
        NotificationManager.shared.removeNotification(for: task)
        context.delete(task)
        try? context.save()
    }

    func updateTask(_ task: Task) {
        guard let context = modelContext else { return }
        task.updatedAt = Date()
        try? context.save()

        // Re-schedule based on new updates
        NotificationManager.shared.scheduleNotification(for: task)
    }

    func addSubtask(to task: Task, title: String) {
        guard let context = modelContext else { return }
        let subtask = Subtask(title: title)
        subtask.parentTask = task
        context.insert(subtask)
        try? context.save()
    }

    func toggleSubtaskCompletion(_ subtask: Subtask) {
        guard let context = modelContext else { return }
        subtask.isCompleted.toggle()
        try? context.save()
    }
}

@MainActor
class AppViewModel: ObservableObject {
    @Published var selectedTab: Tab = .lists
    @Published var showingSettings = false

    // User Preferences synced with UserDefaults
    @AppStorage("hapticFeedback") var hapticFeedback = true
    @AppStorage("soundEffects") var soundEffects = true
    @AppStorage("darkModePreference") var darkModePreference: DarkModePreference = .system
    @AppStorage("hasSeenOnboarding") var hasSeenOnboarding = false

    enum Tab: String, CaseIterable {
        case lists = "Lists"
        case today = "Today"
        case search = "Search"
        case settings = "Settings"

        var iconName: String {
            switch self {
            case .lists: return "list.bullet"
            case .today: return "calendar"
            case .search: return "magnifyingglass"
            case .settings: return "gear"
            }
        }
    }

    enum DarkModePreference: String, CaseIterable, Codable {
        case light = "Light"
        case dark = "Dark"
        case system = "System"

        var colorScheme: ColorScheme? {
            switch self {
            case .light: return .light
            case .dark: return .dark
            case .system: return nil
            }
        }
    }

    func triggerHaptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        guard hapticFeedback else { return }
        let impactFeedback = UIImpactFeedbackGenerator(style: style)
        impactFeedback.impactOccurred()
    }
}
