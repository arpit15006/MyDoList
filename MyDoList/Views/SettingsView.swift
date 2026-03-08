//
//  SettingsView.swift
//  MyDoList
//
//  Created by Arpit Patel on 04/12/25.
//

import SwiftData
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @Environment(\.modelContext) private var modelContext
    @Query private var allTasks: [Task]
    @Query private var allLists: [DoList]

    @State private var showingDeleteAllAlert = false
    @State private var showingExportSheet = false

    var body: some View {
        NavigationStack {
            List {
                // App Statistics
                Section("Statistics") {
                    StatisticRow(
                        title: "Total Lists", value: "\(allLists.count)", icon: "list.bullet")
                    StatisticRow(
                        title: "Total Tasks", value: "\(allTasks.count)", icon: "checkmark.circle")
                    StatisticRow(
                        title: "Completed Tasks", value: "\(completedTasksCount)",
                        icon: "checkmark.circle.fill")
                    StatisticRow(title: "Completion Rate", value: completionRate, icon: "chart.pie")
                }

                // Preferences
                Section("Preferences") {
                    HStack {
                        Image(systemName: "hand.tap")
                            .foregroundColor(.blue)
                            .frame(width: 24)

                        Toggle("Haptic Feedback", isOn: $appViewModel.hapticFeedback)
                    }

                    HStack {
                        Image(systemName: "speaker.wave.2")
                            .foregroundColor(.green)
                            .frame(width: 24)

                        Toggle("Sound Effects", isOn: $appViewModel.soundEffects)
                    }

                    HStack {
                        Image(systemName: "moon")
                            .foregroundColor(.purple)
                            .frame(width: 24)

                        Picker("Appearance", selection: $appViewModel.darkModePreference) {
                            ForEach(AppViewModel.DarkModePreference.allCases, id: \.self) {
                                preference in
                                Text(preference.rawValue).tag(preference)
                            }
                        }
                    }
                }

                // Data Management
                Section("Data Management") {
                    Button {
                        showingExportSheet = true
                    } label: {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundColor(.blue)
                                .frame(width: 24)
                            Text("Export Data")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .foregroundColor(.primary)

                    Button {
                        showingDeleteAllAlert = true
                    } label: {
                        HStack {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                                .frame(width: 24)
                            Text("Delete All Data")
                        }
                    }
                    .foregroundColor(.red)
                }

                // About
                Section("About") {
                    AboutRow(title: "Version", value: "1.0.0")
                    AboutRow(title: "Build", value: "2024.12.04")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
        }
        .alert("Delete All Data", isPresented: $showingDeleteAllAlert) {
            Button("Delete", role: .destructive) {
                deleteAllData()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(
                "This will permanently delete all your lists and tasks. This action cannot be undone."
            )
        }
        .sheet(isPresented: $showingExportSheet) {
            ExportDataView(tasks: allTasks, lists: allLists)
        }
    }

    private var completedTasksCount: Int {
        allTasks.filter { $0.isCompleted }.count
    }

    private var completionRate: String {
        guard allTasks.count > 0 else { return "0%" }
        let rate = Double(completedTasksCount) / Double(allTasks.count) * 100
        return String(format: "%.1f%%", rate)
    }

    private func deleteAllData() {
        for task in allTasks {
            modelContext.delete(task)
        }
        for list in allLists {
            modelContext.delete(list)
        }
        try? modelContext.save()
        appViewModel.triggerHaptic(.heavy)
    }
}

struct StatisticRow: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24)

            Text(title)

            Spacer()

            Text(value)
                .foregroundColor(.secondary)
                .fontWeight(.medium)
        }
    }
}

struct AboutRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .foregroundColor(.secondary)
        }
    }
}

struct ExportDataView: View {
    let tasks: [Task]
    let lists: [DoList]
    @Environment(\.dismiss) private var dismiss
    @State private var exportFormat: ExportFormat = .csv
    @State private var showingShareSheet = false
    @State private var exportURL: URL?

    enum ExportFormat: String, CaseIterable {
        case csv = "CSV"
        case txt = "Text"
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Export Format") {
                    Picker("Format", selection: $exportFormat) {
                        ForEach(ExportFormat.allCases, id: \.self) { format in
                            Text(format.rawValue).tag(format)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Data Summary") {
                    HStack {
                        Text("Lists")
                        Spacer()
                        Text("\(lists.count)")
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("Tasks")
                        Spacer()
                        Text("\(tasks.count)")
                            .foregroundColor(.secondary)
                    }
                }

                Section {
                    Button("Export Data") {
                        exportData()
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle("Export Data")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            if let url = exportURL {
                ShareSheet(items: [url])
            }
        }
    }

    private func exportData() {
        let timestamp = Date().formatted(date: .numeric, time: .omitted).replacingOccurrences(
            of: "/", with: "-")
        let fileName = "MyDoList_Export_\(timestamp)"

        switch exportFormat {
        case .csv:
            exportURL = createCSVExport(fileName: fileName)
        case .txt:
            exportURL = createTextExport(fileName: fileName)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            showingShareSheet = true
        }
    }
    private func createCSVExport(fileName: String) -> URL? {
        var csvContent = "List,Task,Subtask,Notes,Completed,Priority,Due Date,Created Date\n"

        for task in tasks {
            let listTitle = task.list?.title ?? "No List"
            let notes = task.notes.replacingOccurrences(of: "\"", with: "\"\"")
            let completed = task.isCompleted ? "Yes" : "No"
            let dueDate = task.dueDate?.formatted(date: .abbreviated, time: .omitted) ?? ""
            let createdDate = task.createdAt.formatted(date: .abbreviated, time: .omitted)

            // Parent Task Row
            csvContent +=
                "\"\(listTitle)\",\"\(task.title)\",\"\",\"\(notes)\",\"\(completed)\",\"\(task.priority.displayName)\",\"\(dueDate)\",\"\(createdDate)\"\n"

            // Subtask Rows
            for subtask in task.subtasks.sorted(by: { $0.createdAt < $1.createdAt }) {
                let subCompleted = subtask.isCompleted ? "Yes" : "No"
                csvContent +=
                    "\"\(listTitle)\",\"\(task.title)\",\"\(subtask.title)\",\"\",\"\(subCompleted)\",\"\",\"\",\"\"\n"
            }
        }

        guard
            let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
                .first
        else { return nil }
        let fileURL = cacheDir.appendingPathComponent("\(fileName).csv")

        do {
            try csvContent.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            print("Error writing CSV: \(error)")
            return nil
        }
    }

    private func createTextExport(fileName: String) -> URL? {
        var textContent = "MyDoList Export\n"
        textContent += "Generated: \(Date().formatted(date: .complete, time: .complete))\n\n"

        for list in lists {
            textContent += "📋 \(list.title)\n"
            textContent += "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"

            let listTasks = tasks.filter { $0.list == list }
            if listTasks.isEmpty {
                textContent += "   No tasks\n\n"
            } else {
                for task in listTasks {
                    let checkbox = task.isCompleted ? "✅" : "⬜"
                    textContent += "   \(checkbox) \(task.title)\n"

                    if !task.notes.isEmpty {
                        textContent += "      Notes: \(task.notes)\n"
                    }

                    if !task.subtasks.isEmpty {
                        textContent += "      Subtasks:\n"
                        for subtask in task.subtasks.sorted(by: { $0.createdAt < $1.createdAt }) {
                            let subCheckbox = subtask.isCompleted ? "✅" : "⬜"
                            textContent += "         \(subCheckbox) \(subtask.title)\n"
                        }
                    }

                    if let dueDate = task.dueDate {
                        textContent +=
                            "      Due: \(dueDate.formatted(date: .abbreviated, time: .omitted))\n"
                    }

                    textContent += "      Priority: \(task.priority.displayName)\n\n"
                }
            }
        }

        guard
            let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
                .first
        else { return nil }
        let fileURL = cacheDir.appendingPathComponent("\(fileName).txt")

        do {
            try textContent.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            print("Error writing Text file: \(error)")
            return nil
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    SettingsView()
        .environmentObject(AppViewModel())
        .modelContainer(for: [DoList.self, Task.self, Subtask.self], inMemory: true)
}
