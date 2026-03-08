//
//  MyDoListApp.swift
//  MyDoList
//
//  Created by Arpit Patel on 04/12/25.
//

import SwiftUI
import SwiftData

@main
struct MyDoListApp: App {
    @StateObject private var appViewModel = AppViewModel()
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(appViewModel)
                .modelContainer(for: [DoList.self, Task.self, Subtask.self])
                .preferredColorScheme(colorScheme)
        }
    }
    
    private var colorScheme: ColorScheme? {
        switch appViewModel.darkModePreference {
        case .light: return .light
        case .dark: return .dark
        case .system: return nil
        }
    }
}
