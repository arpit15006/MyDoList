//
//  EditListView.swift
//  MyDoList
//
//  Created by Arpit Patel on 04/12/25.
//

import SwiftData
import SwiftUI

struct EditListView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var appViewModel: AppViewModel

    let list: DoList
    @State private var title: String
    @State private var selectedColor: String
    @State private var selectedIcon: String
    @State private var showPreview = false

    private let colors = [
        "007AFF", "FF3B30", "FF9500", "FFCC00", "34C759",
        "00C7BE", "AF52DE", "FF2D92", "A2845E", "8E8E93",
    ]

    private let icons = [
        "list.bullet", "checkmark.circle", "star.fill", "heart.fill",
        "house.fill", "briefcase.fill", "cart.fill", "book.fill",
        "gamecontroller.fill", "music.note", "camera.fill", "airplane",
    ]

    init(list: DoList) {
        self.list = list
        self._title = State(initialValue: list.title)
        self._selectedColor = State(initialValue: list.colorHex)
        self._selectedIcon = State(initialValue: list.iconName)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 30) {
                    // Header with gradient
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color(hex: selectedColor) ?? .blue,
                                            (Color(hex: selectedColor) ?? .blue).opacity(0.6),
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 80, height: 80)
                                .scaleEffect(showPreview ? 1.1 : 1.0)
                                .animation(
                                    .spring(response: 0.6, dampingFraction: 0.8),
                                    value: selectedColor
                                )
                                .animation(
                                    .spring(response: 0.6, dampingFraction: 0.8), value: showPreview
                                )

                            Image(systemName: selectedIcon)
                                .font(.system(size: 35, weight: .semibold))
                                .foregroundColor(.white)
                                .scaleEffect(showPreview ? 1.1 : 1.0)
                                .animation(
                                    .spring(response: 0.6, dampingFraction: 0.8),
                                    value: selectedIcon)
                        }

                        Text(title.isEmpty ? "Edit List" : title)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                            .animation(.easeInOut, value: title)
                    }
                    .padding(.top, 20)

                    // List Details Card
                    VStack(alignment: .leading, spacing: 20) {
                        Text("List Details")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)

                        TextField("Enter list name", text: $title)
                            .font(.body)
                            .padding(16)
                            .background(.ultraThinMaterial)
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(
                                        (Color(hex: selectedColor) ?? .blue).opacity(0.3),
                                        lineWidth: 2)
                            )
                            .onChange(of: title) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    showPreview = !title.isEmpty
                                }
                            }
                    }
                    .padding(20)
                    .background(.ultraThinMaterial)
                    .cornerRadius(20)

                    // Color Selection Card
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Choose Color")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)

                        LazyVGrid(
                            columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 16
                        ) {
                            ForEach(colors, id: \.self) { colorHex in
                                Button {
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                        selectedColor = colorHex
                                    }
                                    appViewModel.triggerHaptic(.light)
                                } label: {
                                    ZStack {
                                        Circle()
                                            .fill(
                                                LinearGradient(
                                                    colors: [
                                                        Color(hex: colorHex) ?? .blue,
                                                        (Color(hex: colorHex) ?? .blue).opacity(
                                                            0.7),
                                                    ],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                            .frame(width: 50, height: 50)
                                            .scaleEffect(selectedColor == colorHex ? 1.2 : 1.0)
                                            .shadow(
                                                color: (Color(hex: colorHex) ?? .blue).opacity(0.4),
                                                radius: selectedColor == colorHex ? 8 : 0)

                                        if selectedColor == colorHex {
                                            Image(systemName: "checkmark")
                                                .font(.title3)
                                                .fontWeight(.bold)
                                                .foregroundColor(.white)
                                                .transition(.scale.combined(with: .opacity))
                                        }
                                    }
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                    .padding(20)
                    .background(.ultraThinMaterial)
                    .cornerRadius(20)

                    // Icon Selection Card
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Choose Icon")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)

                        LazyVGrid(
                            columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 16
                        ) {
                            ForEach(icons, id: \.self) { iconName in
                                Button {
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                        selectedIcon = iconName
                                    }
                                    appViewModel.triggerHaptic(.light)
                                } label: {
                                    Image(systemName: iconName)
                                        .font(.title2)
                                        .fontWeight(.semibold)
                                        .foregroundColor(
                                            selectedIcon == iconName ? .white : .secondary
                                        )
                                        .frame(width: 45, height: 45)
                                        .background {
                                            if selectedIcon == iconName {
                                                RoundedRectangle(cornerRadius: 12)
                                                    .fill(
                                                        (Color(hex: selectedColor) ?? .blue)
                                                            .gradient
                                                    )
                                                    .shadow(
                                                        color: (Color(hex: selectedColor) ?? .blue)
                                                            .opacity(0.3), radius: 8)
                                            } else {
                                                RoundedRectangle(cornerRadius: 12)
                                                    .fill(Color(.systemGray6))
                                            }
                                        }
                                        .scaleEffect(selectedIcon == iconName ? 1.1 : 1.0)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                    .padding(20)
                    .background(.ultraThinMaterial)
                    .cornerRadius(20)
                }
                .padding()
            }
            .background {
                LinearGradient(
                    colors: [Color(.systemBackground), Color(.systemGray6).opacity(0.3)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            }
            .navigationTitle("Edit List")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        updateList()
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .onAppear {
            showPreview = !title.isEmpty
        }
    }

    private func updateList() {
        list.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        list.colorHex = selectedColor
        list.iconName = selectedIcon

        try? modelContext.save()
        appViewModel.triggerHaptic(.medium)
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: DoList.self, Task.self, Subtask.self, configurations: config)

    let sampleList = DoList(title: "Sample List", colorHex: "007AFF", iconName: "list.bullet")
    container.mainContext.insert(sampleList)

    return EditListView(list: sampleList)
        .environmentObject(AppViewModel())
        .modelContainer(container)
}
