//
//  ListsView.swift
//  MyDoList
//
//  Created by Arpit Patel on 04/12/25.
//

import SwiftData
import SwiftUI

struct ListsView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var appViewModel: AppViewModel
    @StateObject private var viewModel = ListsViewModel()
    @Query private var lists: [DoList]

    var body: some View {
        NavigationStack {
            Group {
                if lists.isEmpty {
                    EmptyStateView()
                } else {
                    ScrollView {
                        LazyVGrid(columns: gridColumns, spacing: 20) {
                            ForEach(Array(filteredLists.enumerated()), id: \.element.id) {
                                index, list in
                                NavigationLink(destination: TasksView(list: list)) {
                                    ListCardView(list: list)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("My Lists")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $viewModel.searchText, prompt: "Search lists...")
            .background {
                LinearGradient(
                    colors: [Color(.systemBackground), Color(.systemGray6).opacity(0.3)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            }
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Menu {
                        Picker("Sort by", selection: $viewModel.selectedSortOption) {
                            ForEach(ListsViewModel.SortOption.allCases, id: \.self) { option in
                                Text(option.rawValue).tag(option)
                            }
                        }
                    } label: {
                        Image(systemName: "arrow.up.arrow.down")
                    }

                    Button {
                        viewModel.showingCreateList = true
                        appViewModel.triggerHaptic(.light)
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $viewModel.showingCreateList) {
                CreateListView()
            }
        }
        .onAppear {
            viewModel.setModelContext(modelContext)
        }
        .onChange(of: modelContext) {
            viewModel.setModelContext(modelContext)
        }
    }

    private var gridColumns: [GridItem] {
        [GridItem(.adaptive(minimum: 160, maximum: 200), spacing: 16)]
    }

    private var filteredLists: [DoList] {
        let filtered =
            viewModel.searchText.isEmpty
            ? lists
            : lists.filter {
                $0.title.localizedCaseInsensitiveContains(viewModel.searchText)
            }

        return filtered.sorted { list1, list2 in
            switch viewModel.selectedSortOption {
            case .dateCreated:
                return list1.createdAt > list2.createdAt
            case .alphabetical:
                return list1.title < list2.title
            case .taskCount:
                return list1.totalTasksCount > list2.totalTasksCount
            case .progress:
                return list1.progress > list2.progress
            }
        }
    }
}

struct ListCardView: View {
    let list: DoList
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var appViewModel: AppViewModel
    @State private var isPressed = false
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                ZStack {
                    Circle()
                        .fill(list.color.gradient)
                        .frame(width: 50, height: 50)
                        .shadow(color: list.color.opacity(0.3), radius: 8)

                    Image(systemName: list.iconName)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                }

                Spacer()

                Menu {
                    Button("Edit", systemImage: "pencil") {
                        showingEditSheet = true
                        appViewModel.triggerHaptic(.light)
                    }
                    Button("Duplicate", systemImage: "doc.on.doc") {
                        duplicateList()
                        appViewModel.triggerHaptic(.light)
                    }
                    Divider()
                    Button("Delete", systemImage: "trash", role: .destructive) {
                        showingDeleteAlert = true
                        appViewModel.triggerHaptic(.heavy)
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.title3)
                        .foregroundColor(.secondary)
                        .padding(8)
                        .background(Color(.systemGray6))
                        .clipShape(Circle())
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(list.title)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .lineLimit(2)

                HStack {
                    Text("\(list.completedTasksCount)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(list.color)
                    Text("of \(list.totalTasksCount) tasks")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()

                    if list.totalTasksCount > 0 {
                        Text("\(Int(list.progress * 100))%")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundColor(list.color)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(list.color.opacity(0.1))
                            .cornerRadius(8)
                    }
                }

                if list.totalTasksCount > 0 {
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(.systemGray5))
                            .frame(height: 6)

                        RoundedRectangle(cornerRadius: 8)
                            .fill(list.color.gradient)
                            .frame(width: CGFloat(list.progress) * 140, height: 6)
                            .animation(
                                .spring(response: 0.8, dampingFraction: 0.8), value: list.progress)
                    }
                }
            }
        }
        .padding(20)
        .background(.ultraThinMaterial)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(list.color.opacity(0.2), lineWidth: 1)
        )
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .shadow(color: list.color.opacity(0.2), radius: isPressed ? 5 : 15)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
        .sheet(isPresented: $showingEditSheet) {
            EditListView(list: list)
        }
        .alert("Delete List", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                deleteList()
            }
        } message: {
            Text("Are you sure you want to delete '\(list.title)'? This action cannot be undone.")
        }
    }

    private func duplicateList() {
        let newList = DoList(
            title: "\(list.title) Copy",
            colorHex: list.colorHex,
            iconName: list.iconName
        )
        modelContext.insert(newList)

        for task in list.tasks {
            let newTask = Task(
                title: task.title,
                notes: task.notes,
                priority: task.priority
            )
            newTask.list = newList
            newTask.dueDate = task.dueDate
            newTask.isCompleted = false
            modelContext.insert(newTask)

            for subtask in task.subtasks {
                let newSubtask = Subtask(
                    title: subtask.title
                )
                newSubtask.parentTask = newTask
                newSubtask.isCompleted = false
                modelContext.insert(newSubtask)
            }
        }

        try? modelContext.save()
    }

    private func deleteList() {
        modelContext.delete(list)
        try? modelContext.save()
    }
}

struct EmptyStateView: View {
    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: 30) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                    .scaleEffect(isAnimating ? 1.1 : 1.0)
                    .animation(
                        .easeInOut(duration: 2).repeatForever(autoreverses: true),
                        value: isAnimating)

                Image(systemName: "list.bullet.rectangle")
                    .font(.system(size: 50, weight: .light))
                    .foregroundColor(.white)
            }

            VStack(spacing: 12) {
                Text("No Lists Yet")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)

                Text("Create your first list to get organized\nand boost your productivity!")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
}

#Preview {
    ListsView()
        .environmentObject(AppViewModel())
        .modelContainer(for: [DoList.self, Task.self, Subtask.self], inMemory: true)
}
