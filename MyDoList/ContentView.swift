//
//  ContentView.swift
//  MyDoList
//
//  Created by Arpit Patel on 04/12/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    // Used to perform CRUD Operations
    @Environment(\.modelContext)
    private var modelContext
    
    @Query private var lists: [DoList]
    
    @State private var title: String = ""
    @State private var isAlertShowing: Bool = false
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(lists) { list in
                    Text(list.title)
                        .font(.title2)
                        .fontWeight(.light)
                        .padding(.horizontal, 1)
                        .swipeActions{
                            Button("Delete",role:.destructive){
                                modelContext.delete(list)
                            }
                        }
                }
            }
            .navigationTitle("My DO List")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isAlertShowing.toggle()
                    } label: {
                        Image(systemName: "plus")
                            .imageScale(.large)
                    }
                }
            }
            .alert("Create a new list", isPresented: $isAlertShowing) {
                TextField("Enter a list", text: $title)
                
                Button("Save") {
                    let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
                    modelContext.insert(DoList(title: trimmed))
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
                        "My Do lists are not available",
                        systemImage: "plus.circle.fill",
                        description: Text("No do lists are added yet. Click on '+' to get started")
                    )
                }
            }
        }
    }
}

#Preview("Second List") {
    let container = try! ModelContainer(
        for: DoList.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    
    let context = container.mainContext
    context.insert(DoList(title: "Swift Coding Club"))
    context.insert(DoList(title: "Good Morning!"))
    context.insert(DoList(title: "Good Afternoon!"))
    
    return ContentView()
        .modelContainer(container)
}

#Preview("Main List") {
    ContentView()
        .modelContainer(for: DoList.self, inMemory: true)
}
