//
//  JournalHomeView.swift
//  Capcho
//
//  Created by Capcho on 27/10/26.
//

import SwiftUI
import SwiftData

struct JournalHomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    
    // SwiftData Query for all entries ordered by creation date descending
    @Query(sort: \JournalEntry.createdAt, order: .reverse) private var entries: [JournalEntry]
    
    // State
    @State private var showingNewEditor: Bool = false
    @State private var selectedEntryForEdit: JournalEntry? = nil
    @State private var entryToDelete: JournalEntry? = nil
    @State private var showDeleteConfirmation: Bool = false
    @State private var searchText: String = ""
    @State private var selectedMoodFilter: String? = nil
    
    // Greeting helper
    private var personalizedGreeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<22: return "Good evening"
        default: return "Good night"
        }
    }
    
    private var formattedToday: String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: Date())
    }
    
    // Filtered entries
    private var filteredEntries: [JournalEntry] {
        entries.filter { entry in
            let matchesSearch: Bool
            if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                matchesSearch = true
            } else {
                let query = searchText.lowercased()
                matchesSearch = entry.title.lowercased().contains(query) ||
                                entry.content.lowercased().contains(query) ||
                                (entry.mood?.lowercased().contains(query) ?? false)
            }
            
            let matchesMood: Bool
            if let mood = selectedMoodFilter {
                matchesMood = (entry.mood == mood)
            } else {
                matchesMood = true
            }
            
            return matchesSearch && matchesMood
        }
    }
    
    private var pinnedEntries: [JournalEntry] {
        filteredEntries.filter { $0.isPinned }
    }
    
    private var unpinnedEntries: [JournalEntry] {
        filteredEntries.filter { !$0.isPinned }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background(for: colorScheme)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Header: Capcho Wordmark & Natural Greeting
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Capcho")
                                    .font(AppTypography.wordmark)
                                    .foregroundStyle(AppColors.primaryText(for: colorScheme))
                                
                                Spacer()
                                
                                // Direct New Entry Button
                                Button {
                                    HapticsService.shared.light()
                                    showingNewEditor = true
                                } label: {
                                    Image(systemName: "square.and.pencil")
                                        .font(.system(size: 17, weight: .medium))
                                        .foregroundStyle(AppColors.darkRose)
                                        .padding(8)
                                        .background(
                                            Circle()
                                                .fill(AppColors.badgeBackground(for: colorScheme))
                                        )
                                }
                                .accessibilityLabel("Write a new entry")
                            }
                            
                            HStack(spacing: 6) {
                                Text("\(personalizedGreeting) ·")
                                    .font(AppTypography.dateSubhead)
                                    .foregroundStyle(AppColors.secondaryText(for: colorScheme))
                                
                                Text(formattedToday)
                                    .font(AppTypography.dateSubhead)
                                    .foregroundStyle(AppColors.secondaryText(for: colorScheme))
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                        
                        // Prominent "Capture a thought..." Card
                        quickCaptureButton
                            .padding(.horizontal, 20)
                        
                        // Subtle Search & Mood Filter Bar
                        if !entries.isEmpty {
                            searchAndFilterBar
                                .padding(.horizontal, 20)
                        }
                        
                        // Entry List or Empty State
                        if entries.isEmpty {
                            CapchoEmptyState(
                                title: "Your story starts here.",
                                subtitle: "A quiet, private space to preserve your days, reflections, and little memories.",
                                iconName: "book.pages",
                                actionTitle: "Write your first entry",
                                action: {
                                    HapticsService.shared.light()
                                    showingNewEditor = true
                                }
                            )
                            .padding(.top, 24)
                        } else if filteredEntries.isEmpty {
                            CapchoEmptyState(
                                title: "No entries found",
                                subtitle: "Try adjusting your search terms or mood filter.",
                                iconName: "magnifyingglass"
                            )
                            .padding(.top, 24)
                        } else {
                            entriesListView
                                .padding(.horizontal, 20)
                        }
                    }
                    .padding(.bottom, 36)
                }
            }
            .navigationBarHidden(true)
            .fullScreenCover(isPresented: $showingNewEditor) {
                JournalEditorView()
            }
            .fullScreenCover(item: $selectedEntryForEdit) { entry in
                JournalEditorView(entry: entry)
            }
            .confirmationDialog(
                "Delete this entry?",
                isPresented: $showDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete Entry", role: .destructive) {
                    if let target = entryToDelete {
                        deleteEntry(target)
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This action cannot be undone.")
            }
        }
    }
    
    // MARK: - Quick Capture Entry Point
    private var quickCaptureButton: some View {
        Button {
            HapticsService.shared.light()
            showingNewEditor = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "feather")
                    .font(.system(size: 18, weight: .light))
                    .foregroundStyle(AppColors.darkRose)
                
                Text("Capture a thought…")
                    .font(.system(.body, design: .serif, weight: .regular))
                    .foregroundStyle(AppColors.secondaryText(for: colorScheme))
                
                Spacer()
                
                Image(systemName: "plus")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppColors.darkRose)
                    .padding(6)
                    .background(
                        Circle()
                            .fill(AppColors.cottonRose.opacity(0.3))
                    )
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(AppColors.cardBackground(for: colorScheme))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(AppColors.cottonRose.opacity(0.35), lineWidth: 0.8)
            )
            .shadow(color: colorScheme == .dark ? Color.black.opacity(0.15) : AppColors.cottonRose.opacity(0.15), radius: 6, x: 0, y: 2)
        }
        .accessibilityLabel("Quick capture: start writing an entry")
    }
    
    // MARK: - Search & Filter Bar
    private var searchAndFilterBar: some View {
        VStack(spacing: 10) {
            // Search Input
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 14))
                    .foregroundStyle(AppColors.secondaryText(for: colorScheme))
                
                TextField("Search memories, thoughts, feelings…", text: $searchText)
                    .font(.system(size: 14))
                    .foregroundStyle(AppColors.primaryText(for: colorScheme))
                
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(AppColors.secondaryText(for: colorScheme))
                    }
                    .accessibilityLabel("Clear search")
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(AppColors.inputBackground(for: colorScheme))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            
            // Mood Filter Chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    // "All" Chip
                    Button {
                        HapticsService.shared.selection()
                        selectedMoodFilter = nil
                    } label: {
                        Text("All")
                            .font(.system(size: 12, weight: selectedMoodFilter == nil ? .semibold : .regular))
                            .foregroundStyle(selectedMoodFilter == nil ? Color(hex: 0x3D3436) : AppColors.secondaryText(for: colorScheme))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(
                                Capsule()
                                    .fill(selectedMoodFilter == nil ? AppColors.cottonRose : AppColors.badgeBackground(for: colorScheme))
                            )
                    }
                    .accessibilityLabel("All entries filter")
                    
                    ForEach(CapchoMood.allCases) { mood in
                        let isSelected = (selectedMoodFilter == mood.rawValue)
                        Button {
                            HapticsService.shared.selection()
                            selectedMoodFilter = isSelected ? nil : mood.rawValue
                        } label: {
                            HStack(spacing: 4) {
                                Text(mood.emoji)
                                    .font(.system(size: 11))
                                Text(mood.displayName)
                                    .font(.system(size: 12, weight: isSelected ? .semibold : .regular))
                                    .foregroundStyle(isSelected ? Color(hex: 0x3D3436) : AppColors.secondaryText(for: colorScheme))
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(
                                Capsule()
                                    .fill(isSelected ? AppColors.cottonRose : AppColors.badgeBackground(for: colorScheme))
                            )
                        }
                        .accessibilityLabel("\(mood.displayName) mood filter")
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }
    
    // MARK: - Entries List View
    private var entriesListView: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Pinned Section
            if !pinnedEntries.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 6) {
                        Image(systemName: "pin.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(AppColors.darkRose)
                        
                        Text("PINNED")
                            .font(.system(size: 11, weight: .semibold, design: .serif))
                            .foregroundStyle(AppColors.darkRose)
                            .tracking(1.0)
                    }
                    
                    ForEach(pinnedEntries) { entry in
                        entryCardRow(for: entry)
                    }
                }
            }
            
            // Your Journal Section
            if !unpinnedEntries.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Your Journal")
                            .font(.system(.headline, design: .serif, weight: .medium))
                            .foregroundStyle(AppColors.primaryText(for: colorScheme))
                        
                        Spacer()
                        
                        Text("\(unpinnedEntries.count) \(unpinnedEntries.count == 1 ? "entry" : "entries")")
                            .font(AppTypography.metaText)
                            .foregroundStyle(AppColors.secondaryText(for: colorScheme))
                    }
                    .padding(.top, pinnedEntries.isEmpty ? 4 : 8)
                    
                    ForEach(unpinnedEntries) { entry in
                        entryCardRow(for: entry)
                    }
                }
            }
        }
    }
    
    // MARK: - Entry Card Row Builder
    private func entryCardRow(for entry: JournalEntry) -> some View {
        JournalEntryRow(entry: entry)
            .contentShape(Rectangle())
            .onTapGesture {
                HapticsService.shared.light()
                selectedEntryForEdit = entry
            }
            .contextMenu {
                Button {
                    togglePin(for: entry)
                } label: {
                    Label(entry.isPinned ? "Unpin Entry" : "Pin Entry", systemImage: entry.isPinned ? "pin.slash" : "pin")
                }
                
                Button(role: .destructive) {
                    entryToDelete = entry
                    showDeleteConfirmation = true
                } label: {
                    Label("Delete Entry", systemImage: "trash")
                }
            }
    }
    
    // MARK: - Actions
    private func togglePin(for entry: JournalEntry) {
        HapticsService.shared.selection()
        entry.isPinned.toggle()
        try? modelContext.save()
    }
    
    private func deleteEntry(_ entry: JournalEntry) {
        HapticsService.shared.medium()
        if let filename = entry.imageFilename {
            ImageStorageService.shared.deleteImage(named: filename)
        }
        modelContext.delete(entry)
        try? modelContext.save()
        entryToDelete = nil
    }
}
