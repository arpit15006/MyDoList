//
//  SearchView.swift
//  MyDoList
//
//  Created by Arpit Patel on 04/12/25.
//

import SwiftData
import SwiftUI

struct SearchView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var appViewModel: AppViewModel
    @Query private var allTasks: [Task]
    @Query private var allLists: [DoList]

    @State private var searchText = ""
    @State private var selectedScope: SearchScope = .all
    @State private var selectedFilter: SearchFilter = .all

    enum SearchScope: String, CaseIterable {
        case all = "All"
        case tasks = "Tasks"
        case lists = "Lists"
    }

    enum SearchFilter: String, CaseIterable {
        case all = "All"
        case completed = "Completed"
        case pending = "Pending"
        case overdue = "Overdue"
        case highPriority = "High Priority"
    }

    var searchResults: (tasks: [Task], lists: [DoList]) {
        let filteredTasks = allTasks.filter { task in
            let matchesSearch =
                searchText.isEmpty || task.title.localizedCaseInsensitiveContains(searchText)
                || task.notes.localizedCaseInsensitiveContains(searchText)

            let matchesFilter: Bool
            switch selectedFilter {
            case .all: matchesFilter = true
            case .completed: matchesFilter = task.isCompleted
            case .pending: matchesFilter = !task.isCompleted
            case .overdue: matchesFilter = task.isOverdue
            case .highPriority: matchesFilter = task.priority == .high || task.priority == .urgent
            }

            return matchesSearch && matchesFilter
        }

        let filteredLists = allLists.filter { list in
            searchText.isEmpty || list.title.localizedCaseInsensitiveContains(searchText)
        }

        return (filteredTasks, filteredLists)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search Filters
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(SearchFilter.allCases, id: \.self) { filter in
                            FilterChip(
                                title: filter.rawValue,
                                isSelected: selectedFilter == filter
                            ) {
                                selectedFilter = filter
                                appViewModel.triggerHaptic(.light)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 8)

                // Search Results
                List {
                    if selectedScope == .all || selectedScope == .lists {
                        if !searchResults.lists.isEmpty {
                            Section("Lists") {
                                ForEach(searchResults.lists) { list in
                                    NavigationLink(destination: TasksView(list: list)) {
                                        SearchListRowView(list: list)
                                    }
                                }
                            }
                        }
                    }

                    if selectedScope == .all || selectedScope == .tasks {
                        if !searchResults.tasks.isEmpty {
                            Section("Tasks") {
                                ForEach(searchResults.tasks) { task in
                                    SearchTaskRowView(task: task, searchText: searchText)
                                }
                            }
                        }
                    }

                    if searchResults.tasks.isEmpty && searchResults.lists.isEmpty {
                        if searchText.isEmpty {
                            SearchEmptyStateView()
                        } else {
                            Section {
                                NoResultsView(searchText: searchText)
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchText, prompt: "Search tasks and lists...")
            .searchScopes($selectedScope) {
                ForEach(SearchScope.allCases, id: \.self) { scope in
                    Text(scope.rawValue).tag(scope)
                }
            }
        }
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.blue : Color(.systemGray5))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(16)
        }
    }
}

struct SearchListRowView: View {
    let list: DoList

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: list.iconName)
                .font(.title2)
                .foregroundColor(list.color)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 4) {
                Text(list.title)
                    .font(.body)
                    .fontWeight(.medium)

                Text("\(list.completedTasksCount) of \(list.totalTasksCount) tasks completed")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            if list.totalTasksCount > 0 {
                CircularProgressView(progress: list.progress, color: list.color)
                    .frame(width: 30, height: 30)
            }
        }
        .padding(.vertical, 4)
    }
}

struct SearchTaskRowView: View {
    let task: Task
    let searchText: String
    @StateObject private var viewModel = TasksViewModel()
    @EnvironmentObject var appViewModel: AppViewModel
    @Environment(\.modelContext) private var modelContext
    @State private var showingTaskDetail = false

    var body: some View {
        HStack(spacing: 12) {
            Button {
                viewModel.toggleTaskCompletion(task)
                appViewModel.triggerHaptic(.light)
            } label: {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(task.isCompleted ? .green : .gray)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(highlightedText(task.title, searchText: searchText))
                    .font(.body)
                    .strikethrough(task.isCompleted)
                    .foregroundColor(task.isCompleted ? .secondary : .primary)

                if !task.notes.isEmpty {
                    Text(highlightedText(task.notes, searchText: searchText))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                HStack {
                    if let list = task.list {
                        Text(list.title)
                            .font(.caption)
                            .foregroundColor(list.color)
                    }

                    Spacer()

                    Image(systemName: task.priority.iconName)
                        .font(.caption)
                        .foregroundColor(task.priority.color)

                    if let dueDate = task.dueDate {
                        Text(dueDate, style: .date)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()
        }
        .contentShape(Rectangle())
        .onTapGesture {
            showingTaskDetail = true
        }
        .sheet(isPresented: $showingTaskDetail) {
            TaskDetailView(task: task)
                .environmentObject(viewModel)
        }
        .onAppear {
            viewModel.setModelContext(modelContext)
        }
    }

    private func highlightedText(_ text: String, searchText: String) -> AttributedString {
        var attributedString = AttributedString(text)

        if !searchText.isEmpty {
            let ranges = text.ranges(of: searchText, options: .caseInsensitive)
            for range in ranges {
                let start = AttributedString.Index(range.lowerBound, within: attributedString)
                let end = AttributedString.Index(range.upperBound, within: attributedString)
                if let start = start, let end = end {
                    attributedString[start..<end].backgroundColor = .yellow.opacity(0.3)
                }
            }
        }

        return attributedString
    }
}

struct SearchEmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(.secondary)

            Text("Search Your Tasks & Lists")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Find tasks by title, notes, or search for specific lists to stay organized.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Spacer()
        }
    }
}

struct NoResultsView: View {
    let searchText: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "questionmark.circle")
                .font(.title)
                .foregroundColor(.secondary)

            Text("No results for \"\(searchText)\"")
                .font(.headline)

            Text("Try searching with different keywords or check your spelling.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 20)
    }
}

struct CircularProgressView: View {
    let progress: Double
    let color: Color

    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.2), lineWidth: 3)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(color, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.5), value: progress)
        }
    }
}

extension String {
    func ranges(of searchString: String, options: String.CompareOptions = []) -> [Range<
        String.Index
    >] {
        var ranges: [Range<String.Index>] = []
        var searchStartIndex = self.startIndex

        while searchStartIndex < self.endIndex,
            let range = self.range(
                of: searchString, options: options, range: searchStartIndex..<self.endIndex)
        {
            ranges.append(range)
            searchStartIndex = range.upperBound
        }

        return ranges
    }
}

#Preview {
    SearchView()
        .environmentObject(AppViewModel())
        .modelContainer(for: [DoList.self, Task.self, Subtask.self], inMemory: true)
}
