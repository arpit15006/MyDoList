//
//  TodayView.swift
//  MyDoList
//
//  Created by Arpit Patel on 04/12/25.
//

import SwiftData
import SwiftUI

struct TodayView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var appViewModel: AppViewModel
    @Query private var allTasks: [Task]
    @State private var animateCards = false
    @State private var currentTime = Date()

    private var todayTasks: [Task] {
        allTasks.filter { task in
            guard let dueDate = task.dueDate else { return false }
            return Calendar.current.isDateInToday(dueDate)
        }
    }

    private var overdueTasks: [Task] {
        allTasks.filter { $0.isOverdue }
    }

    private var upcomingTasks: [Task] {
        allTasks.filter { task in
            guard let dueDate = task.dueDate, !task.isCompleted else { return false }
            return dueDate > Calendar.current.startOfDay(for: Date().addingTimeInterval(86400))
        }.sorted { $0.dueDate! < $1.dueDate! }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Solid, professional background
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 24) {
                        // Hero Header
                        ModernHeroHeader(currentTime: currentTime)
                            .scaleEffect(animateCards ? 1 : 0.8)
                            .opacity(animateCards ? 1 : 0)

                        // Stats Cards
                        ModernStatsGrid(
                            todayCount: todayTasks.count,
                            overdueCount: overdueTasks.count,
                            completedToday: todayTasks.filter { $0.isCompleted }.count
                        )
                        .scaleEffect(animateCards ? 1 : 0.8)
                        .opacity(animateCards ? 1 : 0)

                        // Task Sections
                        VStack(spacing: 20) {
                            if !overdueTasks.isEmpty {
                                ModernTaskSection(
                                    title: "Overdue",
                                    tasks: overdueTasks,
                                    accentColor: .red
                                )
                            }

                            ModernTaskSection(
                                title: "Due Today",
                                tasks: todayTasks,
                                accentColor: .blue
                            )

                            if !upcomingTasks.isEmpty {
                                ModernTaskSection(
                                    title: "Coming Up",
                                    tasks: Array(upcomingTasks.prefix(3)),
                                    accentColor: .indigo
                                )
                            }
                        }
                        .scaleEffect(animateCards ? 1 : 0.8)
                        .opacity(animateCards ? 1 : 0)

                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                }
            }
            .navigationTitle("Today")
            .navigationBarTitleDisplayMode(.large)
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.1)) {
                animateCards = true
            }

            Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                currentTime = Date()
            }
        }
    }
}

struct ModernHeroHeader: View {
    let currentTime: Date

    var greeting: String {
        let hour = Calendar.current.component(.hour, from: currentTime)
        switch hour {
        case 5..<12: return "Good Morning"
        case 12..<17: return "Good Afternoon"
        case 17..<22: return "Good Evening"
        default: return "Good Night"
        }
    }

    var greetingIcon: (name: String, color: Color) {
        let hour = Calendar.current.component(.hour, from: currentTime)
        switch hour {
        case 5..<12: return ("sun.max.fill", .orange)
        case 12..<17: return ("sun.max.fill", .yellow)
        case 17..<22: return ("moon.stars.fill", .indigo)
        default: return ("moon.fill", .blue)
        }
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text(greeting)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)

                Text(currentTime.formatted(date: .complete, time: .omitted))
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.secondary)
            }

            Spacer()

            ZStack {
                Circle()
                    .fill(Color(.secondarySystemGroupedBackground))
                    .frame(width: 56, height: 56)
                    .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)

                Image(systemName: greetingIcon.name)
                    .font(.system(size: 24))
                    .foregroundColor(greetingIcon.color)
            }
        }
        .padding(.horizontal, 4)
    }
}

struct ModernStatsGrid: View {
    let todayCount: Int
    let overdueCount: Int
    let completedToday: Int

    var body: some View {
        HStack(spacing: 16) {
            ModernStatCard(
                title: "Due Today",
                count: todayCount,
                accentColor: .blue,
                icon: "calendar"
            )

            ModernStatCard(
                title: "Overdue",
                count: overdueCount,
                accentColor: .red,
                icon: "exclamationmark.circle"
            )

            ModernStatCard(
                title: "Done",
                count: completedToday,
                accentColor: .green,
                icon: "checkmark.circle"
            )
        }
    }
}

struct ModernStatCard: View {
    let title: String
    let count: Int
    let accentColor: Color
    let icon: String

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(accentColor)

            VStack(spacing: 4) {
                Text("\(count)")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)

                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 120)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

struct ModernTaskSection: View {
    let title: String
    let tasks: [Task]
    let accentColor: Color
    @StateObject private var viewModel = TasksViewModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(title)
                    .font(.system(size: 20, weight: .bold, design: .rounded))

                Spacer()

                Text("\(tasks.count)")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(accentColor)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(accentColor.opacity(0.15))
                    )
            }

            if tasks.isEmpty {
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(Color(.systemGray6))
                            .frame(width: 60, height: 60)

                        Image(systemName: "checkmark")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.secondary)
                    }

                    VStack(spacing: 4) {
                        Text("All caught up!")
                            .font(.system(size: 18, weight: .semibold))
                        Text("You're doing great today")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(tasks) { task in
                        TodayTaskRowView(task: task, accentColor: accentColor)
                            .environmentObject(viewModel)
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
}

struct TodayTaskRowView: View {
    let task: Task
    let accentColor: Color
    @StateObject private var viewModel = TasksViewModel()
    @EnvironmentObject var appViewModel: AppViewModel
    @Environment(\.modelContext) private var modelContext
    @State private var showingTaskDetail = false
    @State private var isPressed = false

    var body: some View {
        HStack(spacing: 16) {
            Button {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    viewModel.toggleTaskCompletion(task)
                }
                appViewModel.triggerHaptic(.light)
            } label: {
                ZStack {
                    Circle()
                        .stroke(task.isCompleted ? .green : accentColor.opacity(0.3), lineWidth: 2)
                        .frame(width: 24, height: 24)

                    if task.isCompleted {
                        Circle()
                            .fill(.green)
                            .frame(width: 20, height: 20)

                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(task.title)
                    .font(.system(size: 16, weight: .medium))
                    .strikethrough(task.isCompleted)
                    .foregroundColor(task.isCompleted ? .secondary : .primary)
                    .lineLimit(2)

                HStack(spacing: 8) {
                    if let list = task.list {
                        Text(list.title)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(list.color)
                            )
                    }

                    HStack(spacing: 4) {
                        Image(systemName: task.priority.iconName)
                        Text(task.priority.displayName)
                    }
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(task.priority.color)

                    Spacer()

                    if let dueDate = task.dueDate {
                        Text(dueDate, style: .time)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
        )
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .contentShape(Rectangle())
        .onTapGesture {
            showingTaskDetail = true
            appViewModel.triggerHaptic(.light)
        }
        .onLongPressGesture(
            minimumDuration: 0, maximumDistance: .infinity,
            pressing: { pressing in
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = pressing
                }
            }, perform: {}
        )
        .sheet(isPresented: $showingTaskDetail) {
            TaskDetailView(task: task)
                .environmentObject(viewModel)
        }
        .onAppear {
            viewModel.setModelContext(modelContext)
        }
    }
}

#Preview {
    TodayView()
        .environmentObject(AppViewModel())
        .modelContainer(for: [DoList.self, Task.self, Subtask.self], inMemory: true)
}
