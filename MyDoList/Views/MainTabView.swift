//
//  MainTabView.swift
//  MyDoList
//
//  Created by Arpit Patel on 04/12/25.
//

import SwiftData
import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    var body: some View {
        Group {
            if horizontalSizeClass == .regular {
                // iPad layout with sidebar
                NavigationSplitView {
                    SidebarView()
                } detail: {
                    DetailView()
                }
            } else {
                // iPhone layout with tab bar
                TabView(selection: $appViewModel.selectedTab) {
                    ListsView()
                        .tabItem {
                            Label("Lists", systemImage: "list.bullet")
                        }
                        .tag(AppViewModel.Tab.lists)

                    TodayView()
                        .tabItem {
                            Label("Today", systemImage: "calendar")
                        }
                        .tag(AppViewModel.Tab.today)

                    SearchView()
                        .tabItem {
                            Label("Search", systemImage: "magnifyingglass")
                        }
                        .tag(AppViewModel.Tab.search)

                    SettingsView()
                        .tabItem {
                            Label("Settings", systemImage: "gear")
                        }
                        .tag(AppViewModel.Tab.settings)
                }
                .accentColor(.blue)
            }
        }
        .fullScreenCover(
            isPresented: Binding(
                get: { !appViewModel.hasSeenOnboarding },
                set: { _ in }
            )
        ) {
            OnboardingView()
                .environmentObject(appViewModel)
        }
    }
}

struct SidebarView: View {
    @EnvironmentObject var appViewModel: AppViewModel

    var body: some View {
        List {
            Section("Main") {
                ForEach(AppViewModel.Tab.allCases, id: \.self) { tab in
                    Button {
                        appViewModel.selectedTab = tab
                    } label: {
                        Label(tab.rawValue, systemImage: tab.iconName)
                    }
                    .foregroundColor(appViewModel.selectedTab == tab ? .blue : .primary)
                }
            }
        }
        .navigationTitle("Tasca")
        .navigationBarTitleDisplayMode(.large)
    }
}

struct DetailView: View {
    @EnvironmentObject var appViewModel: AppViewModel

    var body: some View {
        Group {
            switch appViewModel.selectedTab {
            case .lists:
                ListsView()
            case .today:
                TodayView()
            case .search:
                SearchView()
            case .settings:
                SettingsView()
            }
        }
    }
}

#Preview {
    MainTabView()
        .environmentObject(AppViewModel())
        .modelContainer(for: [DoList.self, Task.self, Subtask.self], inMemory: true)
}
