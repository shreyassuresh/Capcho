//
//  SearchView.swift
//  Capcho
//
//  Created by Capcho on 27/10/26.
//

import SwiftUI
import SwiftData

struct SearchView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    @Query(sort: \JournalEntry.createdAt, order: .reverse) private var entries: [JournalEntry]
    @Query(sort: \Note.updatedAt, order: .reverse) private var notes: [Note]
    
    @State private var query: String = ""
    @State private var filterScope: SearchScope = .all
    @State private var selectedEntry: JournalEntry? = nil
    @State private var selectedNote: Note? = nil
    
    enum SearchScope: String, CaseIterable, Identifiable {
        case all = "All"
        case journal = "Journal"
        case notes = "Notes"
        
        var id: String { rawValue }
    }
    
    private var matchingEntries: [JournalEntry] {
        guard !cleanQuery.isEmpty else { return [] }
        return entries.filter { entry in
            entry.title.localizedCaseInsensitiveContains(cleanQuery) ||
            entry.content.localizedCaseInsensitiveContains(cleanQuery) ||
            (entry.mood?.localizedCaseInsensitiveContains(cleanQuery) ?? false)
        }
    }
    
    private var matchingNotes: [Note] {
        guard !cleanQuery.isEmpty else { return [] }
        return notes.filter { note in
            note.title.localizedCaseInsensitiveContains(cleanQuery) ||
            note.content.localizedCaseInsensitiveContains(cleanQuery)
        }
    }
    
    private var cleanQuery: String {
        query.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private var totalResultsCount: Int {
        switch filterScope {
        case .all:
            return matchingEntries.count + matchingNotes.count
        case .journal:
            return matchingEntries.count
        case .notes:
            return matchingNotes.count
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background(for: colorScheme)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Search Header Input
                    HStack(spacing: 10) {
                        HStack(spacing: 8) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 15))
                                .foregroundStyle(AppColors.secondaryText(for: colorScheme))
                            
                            TextField("Search words, memories, notes…", text: $query)
                                .font(.system(size: 15))
                                .foregroundStyle(AppColors.primaryText(for: colorScheme))
                                .autocorrectionDisabled()
                            
                            if !query.isEmpty {
                                Button {
                                    query = ""
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 15))
                                        .foregroundStyle(AppColors.secondaryText(for: colorScheme))
                                }
                                .accessibilityLabel("Clear search")
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(AppColors.inputBackground(for: colorScheme))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        
                        Button("Cancel") {
                            dismiss()
                        }
                        .font(.system(.body, design: .serif, weight: .regular))
                        .foregroundStyle(AppColors.darkRose)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    .padding(.bottom, 12)
                    
                    // Scope Selector
                    Picker("Search Scope", selection: $filterScope) {
                        ForEach(SearchScope.allCases) { scope in
                            Text(scope.rawValue).tag(scope)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 14)
                    
                    // Results List
                    ScrollView {
                        VStack(alignment: .leading, spacing: 18) {
                            if cleanQuery.isEmpty {
                                CapchoEmptyState(
                                    title: "Offline Local Search",
                                    subtitle: "Quickly find any journal thought, memory, or note. Everything stays private on this device.",
                                    iconName: "text.magnifyingglass"
                                )
                                .padding(.top, 40)
                            } else if totalResultsCount == 0 {
                                CapchoEmptyState(
                                    title: "No results for \"\(cleanQuery)\"",
                                    subtitle: "Check the spelling or try searching for a different keyword.",
                                    iconName: "magnifyingglass"
                                )
                                .padding(.top, 40)
                            } else {
                                // Journal Results
                                if (filterScope == .all || filterScope == .journal) && !matchingEntries.isEmpty {
                                    VStack(alignment: .leading, spacing: 10) {
                                        HStack {
                                            Text("Journal Entries")
                                                .font(.system(.subheadline, design: .serif, weight: .semibold))
                                                .foregroundStyle(AppColors.darkRose)
                                            
                                            Spacer()
                                            
                                            Text("\(matchingEntries.count)")
                                                .font(AppTypography.metaText)
                                                .foregroundStyle(AppColors.secondaryText(for: colorScheme))
                                        }
                                        
                                        ForEach(matchingEntries) { entry in
                                            JournalEntryRow(entry: entry)
                                                .contentShape(Rectangle())
                                                .onTapGesture {
                                                    HapticsService.shared.light()
                                                    selectedEntry = entry
                                                }
                                        }
                                    }
                                    .padding(.horizontal, 20)
                                }
                                
                                // Notes Results
                                if (filterScope == .all || filterScope == .notes) && !matchingNotes.isEmpty {
                                    VStack(alignment: .leading, spacing: 10) {
                                        HStack {
                                            Text("Notes")
                                                .font(.system(.subheadline, design: .serif, weight: .semibold))
                                                .foregroundStyle(AppColors.darkRose)
                                            
                                            Spacer()
                                            
                                            Text("\(matchingNotes.count)")
                                                .font(AppTypography.metaText)
                                                .foregroundStyle(AppColors.secondaryText(for: colorScheme))
                                        }
                                        .padding(.top, (filterScope == .all && !matchingEntries.isEmpty) ? 12 : 0)
                                        
                                        ForEach(matchingNotes) { note in
                                            NoteRow(note: note)
                                                .contentShape(Rectangle())
                                                .onTapGesture {
                                                    HapticsService.shared.light()
                                                    selectedNote = note
                                                }
                                        }
                                    }
                                    .padding(.horizontal, 20)
                                }
                            }
                        }
                        .padding(.bottom, 36)
                    }
                }
            }
            .navigationBarHidden(true)
            .fullScreenCover(item: $selectedEntry) { entry in
                JournalEditorView(entry: entry)
            }
            .fullScreenCover(item: $selectedNote) { note in
                NoteEditorView(note: note)
            }
        }
    }
}
