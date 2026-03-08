//
//  ContentView.swift
//  MyDoList
//
//  Created by Arpit Patel on 04/12/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var lists: [DoList]
    @State private var title = ""
    @State private var isAlertShowing = false
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(lists) { list in
                    HStack {
                        Image(systemName: list.iconName)
                            .foregroundColor(list.color)
                        Text(list.title)
                            .font(.headline)
                        Spacer()
                    }
                    .padding(.vertical, 4)
                    .swipeActions {
                        Button("Delete", role: .destructive) {
                            modelContext.delete(list)
                        }
                    }
                }
            }
            .navigationTitle("My Lists")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isAlertShowing.toggle()
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .alert("Create List", isPresented: $isAlertShowing) {
                TextField("List name", text: $title)
                Button("Create") {
                    let newList = DoList(title: title.trimmingCharacters(in: .whitespacesAndNewlines))
                    modelContext.insert(newList)
                    title = ""
                }
                .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                Button("Cancel", role: .cancel) {
                    title = ""
                }
            }
            .overlay {
                if lists.isEmpty {
                    ContentUnavailableView(
                        "No Lists Yet",
                        systemImage: "list.bullet.rectangle",
                        description: Text("Create your first list to get started!")
                    )
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppViewModel())
        .modelContainer(for: [DoList.self, Task.self, Subtask.self], inMemory: true)
}
