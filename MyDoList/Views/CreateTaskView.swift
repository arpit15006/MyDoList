//
//  CreateTaskView.swift
//  MyDoList
//
//  Created by Arpit Patel on 04/12/25.
//

import SwiftUI
import SwiftData

struct CreateTaskView: View {
    let list: DoList
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var appViewModel: AppViewModel
    
    @State private var title = ""
    @State private var notes = ""
    @State private var priority: TaskPriority = .medium
    @State private var hasDueDate = false
    @State private var dueDate = Date()
    @State private var showPreview = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 25) {
                    // Header Preview
                    VStack(spacing: 16) {
                        HStack {
                            ZStack {
                                Circle()
                                    .fill(list.color.gradient)
                                    .frame(width: 50, height: 50)
                                    .shadow(color: list.color.opacity(0.3), radius: 8)
                                
                                Image(systemName: list.iconName)
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(list.title)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                Text("New Task")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                        .padding(20)
                        .background(.ultraThinMaterial)
                        .cornerRadius(16)
                    }
                    
                    // Task Details Card
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Task Details")
                            .font(.title3)
                            .fontWeight(.bold)
                        
                        VStack(spacing: 16) {
                            TextField("What needs to be done?", text: $title)
                                .font(.body)
                                .padding(16)
                                .background(.ultraThinMaterial)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(priority.color.opacity(0.3), lineWidth: 2)
                                )
                            
                            TextField("Add notes (optional)", text: $notes, axis: .vertical)
                                .font(.body)
                                .padding(16)
                                .background(.ultraThinMaterial)
                                .cornerRadius(12)
                                .lineLimit(3...6)
                        }
                    }
                    .padding(20)
                    .background(.ultraThinMaterial)
                    .cornerRadius(20)
                    
                    // Priority Card
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Priority Level")
                            .font(.title3)
                            .fontWeight(.bold)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                            ForEach(TaskPriority.allCases, id: \.self) { taskPriority in
                                Button {
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                        priority = taskPriority
                                    }
                                    appViewModel.triggerHaptic(.light)
                                } label: {
                                    HStack {
                                        Image(systemName: taskPriority.iconName)
                                            .font(.title3)
                                            .foregroundColor(priority == taskPriority ? .white : taskPriority.color)
                                        
                                        Text(taskPriority.displayName)
                                            .font(.body)
                                            .fontWeight(.medium)
                                            .foregroundColor(priority == taskPriority ? .white : taskPriority.color)
                                        
                                        Spacer()
                                    }
                                    .padding(16)
                                    .background {
                                        if priority == taskPriority {
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(taskPriority.color.gradient)
                                                .shadow(color: taskPriority.color.opacity(0.3), radius: 8)
                                        } else {
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(.ultraThinMaterial)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 12)
                                                        .stroke(taskPriority.color.opacity(0.2), lineWidth: 1)
                                                )
                                        }
                                    }
                                    .scaleEffect(priority == taskPriority ? 1.05 : 1.0)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                    .padding(20)
                    .background(.ultraThinMaterial)
                    .cornerRadius(20)
                    
                    // Due Date Card
                    VStack(alignment: .leading, spacing: 20) {
                        HStack {
                            Text("Due Date")
                                .font(.title3)
                                .fontWeight(.bold)
                            
                            Spacer()
                            
                            Toggle("", isOn: $hasDueDate)
                                .toggleStyle(SwitchToggleStyle(tint: priority.color))
                        }
                        
                        if hasDueDate {
                            DatePicker("Select date and time", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
                                .datePickerStyle(.compact)
                                .accentColor(priority.color)
                                .transition(.scale.combined(with: .opacity))
                        }
                    }
                    .padding(20)
                    .background(.ultraThinMaterial)
                    .cornerRadius(20)
                    
                    // Preview Card
                    if !title.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Preview")
                                .font(.title3)
                                .fontWeight(.bold)
                            
                            HStack(spacing: 12) {
                                Image(systemName: "circle")
                                    .font(.title2)
                                    .foregroundColor(.gray)
                                
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(title)
                                        .font(.body)
                                        .fontWeight(.medium)
                                    
                                    if !notes.isEmpty {
                                        Text(notes)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .lineLimit(2)
                                    }
                                    
                                    HStack {
                                        Image(systemName: priority.iconName)
                                            .font(.caption)
                                            .foregroundColor(priority.color)
                                        
                                        Text(priority.displayName)
                                            .font(.caption)
                                            .foregroundColor(priority.color)
                                        
                                        if hasDueDate {
                                            Spacer()
                                            Text(dueDate, style: .date)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }
                                
                                Spacer()
                            }
                            .padding(16)
                            .background(priority.color.opacity(0.1))
                            .cornerRadius(12)
                        }
                        .padding(20)
                        .background(.ultraThinMaterial)
                        .cornerRadius(20)
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                .padding()
            }
            .background {
                LinearGradient(
                    colors: [Color(.systemBackground), list.color.opacity(0.05)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            }
            .navigationTitle("New Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.primary)
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        let newTask = Task(
                            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines),
                            priority: priority
                        )
                        newTask.list = list
                        if hasDueDate {
                            newTask.dueDate = dueDate
                        }
                        modelContext.insert(newTask)
                        try? modelContext.save()
                        appViewModel.triggerHaptic(.medium)
                        dismiss()
                    } label: {
                        Text("Create")
                            .fontWeight(.semibold)
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.2)) {
                showPreview = true
            }
        }
        }
    
}

#Preview {
    let list = DoList(title: "Work Tasks")
    return CreateTaskView(list: list)
        .environmentObject(AppViewModel())
        .modelContainer(for: [DoList.self, Task.self], inMemory: true)
}
