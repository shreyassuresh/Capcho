//
//  NotesHomeView.swift
//  Capcho
//
//  Created by Capcho on 27/10/26.
//

import SwiftUI
import SwiftData

struct NotesHomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    
    // SwiftData Query for all notes ordered by updatedAt descending
    @Query(sort: \Note.updatedAt, order: .reverse) private var notes: [Note]
    
    // State
    @State private var showingNewNoteEditor: Bool = false
    @State private var selectedNoteForEdit: Note? = nil
    @State private var noteToDelete: Note? = nil
    @State private var showDeleteConfirmation: Bool = false
    @State private var searchText: String = ""
    
    // Filtered notes
    private var filteredNotes: [Note] {
        if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return notes
        }
        let query = searchText.lowercased()
        return notes.filter { note in
            note.title.lowercased().contains(query) ||
            note.content.lowercased().contains(query)
        }
    }
    
    private var pinnedNotes: [Note] {
        filteredNotes.filter { $0.isPinned }
    }
    
    private var unpinnedNotes: [Note] {
        filteredNotes.filter { !$0.isPinned }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background(for: colorScheme)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        // Title & Create Button
                        HStack {
                            Text("Notes")
                                .font(AppTypography.journalHeading)
                                .foregroundStyle(AppColors.primaryText(for: colorScheme))
                            
                            Spacer()
                            
                            Button {
                                HapticsService.shared.light()
                                showingNewNoteEditor = true
                            } label: {
                                Image(systemName: "plus")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(Color(hex: 0x3D3436))
                                    .padding(8)
                                    .background(
                                        Circle()
                                            .fill(AppColors.cottonRose)
                                    )
                            }
                            .accessibilityLabel("Create new note")
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 12)
                        
                        // Search bar
                        if !notes.isEmpty {
                            HStack(spacing: 8) {
                                Image(systemName: "magnifyingglass")
                                    .font(.system(size: 14))
                                    .foregroundStyle(AppColors.secondaryText(for: colorScheme))
                                
                                TextField("Search notes…", text: $searchText)
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
                            .padding(.horizontal, 20)
                        }
                        
                        // Content
                        if notes.isEmpty {
                            CapchoEmptyState(
                                title: "A little space for every thought.",
                                subtitle: "Keep quick notes, daily checklists, lists of books, or ideas you want to remember.",
                                iconName: "note.text",
                                actionTitle: "Create a Note",
                                action: {
                                    HapticsService.shared.light()
                                    showingNewNoteEditor = true
                                }
                            )
                            .padding(.top, 36)
                        } else if filteredNotes.isEmpty {
                            CapchoEmptyState(
                                title: "No matching notes",
                                subtitle: "No notes matched your search query.",
                                iconName: "magnifyingglass"
                            )
                            .padding(.top, 36)
                        } else {
                            notesListView
                                .padding(.horizontal, 20)
                        }
                    }
                    .padding(.bottom, 36)
                }
            }
            .navigationBarHidden(true)
            .fullScreenCover(isPresented: $showingNewNoteEditor) {
                NoteEditorView()
            }
            .fullScreenCover(item: $selectedNoteForEdit) { note in
                NoteEditorView(note: note)
            }
            .confirmationDialog(
                "Delete this note?",
                isPresented: $showDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete Note", role: .destructive) {
                    if let target = noteToDelete {
                        deleteNote(target)
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This action cannot be undone.")
            }
        }
    }
    
    // MARK: - Notes List
    private var notesListView: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Pinned Notes
            if !pinnedNotes.isEmpty {
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
                    
                    ForEach(pinnedNotes) { note in
                        noteCardRow(for: note)
                    }
                }
            }
            
            // Other Notes
            if !unpinnedNotes.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    if !pinnedNotes.isEmpty {
                        Text("All Notes")
                            .font(.system(.headline, design: .serif, weight: .medium))
                            .foregroundStyle(AppColors.primaryText(for: colorScheme))
                            .padding(.top, 6)
                    }
                    
                    ForEach(unpinnedNotes) { note in
                        noteCardRow(for: note)
                    }
                }
            }
        }
    }
    
    private func noteCardRow(for note: Note) -> some View {
        NoteRow(note: note)
            .contentShape(Rectangle())
            .onTapGesture {
                HapticsService.shared.light()
                selectedNoteForEdit = note
            }
            .contextMenu {
                Button {
                    togglePin(for: note)
                } label: {
                    Label(note.isPinned ? "Unpin Note" : "Pin Note", systemImage: note.isPinned ? "pin.slash" : "pin")
                }
                
                Button(role: .destructive) {
                    noteToDelete = note
                    showDeleteConfirmation = true
                } label: {
                    Label("Delete Note", systemImage: "trash")
                }
            }
    }
    
    // MARK: - Actions
    private func togglePin(for note: Note) {
        HapticsService.shared.selection()
        note.isPinned.toggle()
        try? modelContext.save()
    }
    
    private func deleteNote(_ note: Note) {
        HapticsService.shared.medium()
        modelContext.delete(note)
        try? modelContext.save()
        noteToDelete = nil
    }
}
