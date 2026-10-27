//
//  NoteEditorView.swift
//  Capcho
//
//  Created by Capcho on 27/10/26.
//

import SwiftUI
import SwiftData

struct NoteEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.scenePhase) private var scenePhase
    
    private let initialNote: Note?
    
    // Local draft state
    @State private var activeNote: Note?
    @State private var title: String
    @State private var content: String
    @State private var isPinned: Bool
    
    // Status & UI State
    @State private var saveStatus: CapchoSaveIndicator.Status = .idle
    @State private var autosaveTask: Task<Void, Never>? = nil
    @State private var showDeleteConfirmation: Bool = false
    @State private var hasUnsavedChanges: Bool = false
    
    init(note: Note? = nil) {
        self.initialNote = note
        _activeNote = State(initialValue: note)
        _title = State(initialValue: note?.title ?? "")
        _content = State(initialValue: note?.content ?? "")
        _isPinned = State(initialValue: note?.isPinned ?? false)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background(for: colorScheme)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        // Header info
                        HStack {
                            Text(activeNote == nil ? "New Note" : "Edited \(activeNote!.formattedLastEdited)")
                                .font(AppTypography.metaText)
                                .foregroundStyle(AppColors.secondaryText(for: colorScheme))
                            
                            Spacer()
                            
                            CapchoSaveIndicator(status: saveStatus)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 12)
                        
                        // Title Field
                        TextField("Note title…", text: $title, axis: .vertical)
                            .font(.system(.title3, design: .serif, weight: .medium))
                            .foregroundStyle(AppColors.primaryText(for: colorScheme))
                            .padding(.horizontal, 20)
                            .onChange(of: title) { _, _ in
                                markDirtyAndScheduleSave()
                            }
                            .accessibilityLabel("Note title")
                        
                        Divider()
                            .overlay(AppColors.divider(for: colorScheme))
                            .padding(.horizontal, 20)
                        
                        // Body Text Canvas
                        ZStack(alignment: .topLeading) {
                            if content.isEmpty {
                                Text("Jot down quick thoughts, lists, quotes, or ideas…")
                                    .font(AppTypography.editorBody)
                                    .foregroundStyle(AppColors.secondaryText(for: colorScheme).opacity(0.6))
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 8)
                                    .lineSpacing(5)
                                    .allowsHitTesting(false)
                            }
                            
                            TextEditor(text: $content)
                                .font(AppTypography.editorBody)
                                .foregroundStyle(AppColors.primaryText(for: colorScheme))
                                .scrollContentBackground(.hidden)
                                .background(Color.clear)
                                .lineSpacing(5)
                                .frame(minHeight: 320)
                                .padding(.horizontal, 20)
                                .onChange(of: content) { _, _ in
                                    markDirtyAndScheduleSave()
                                }
                                .accessibilityLabel("Note content")
                        }
                        
                        // Subtle Word Count Footer
                        HStack {
                            Text("\(currentWordCount) words · \(currentCharacterCount) characters")
                                .font(AppTypography.metaText)
                                .foregroundStyle(AppColors.secondaryText(for: colorScheme).opacity(0.8))
                            
                            Spacer()
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 32)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: handleClose) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(AppColors.darkRose)
                    }
                    .accessibilityLabel("Back to Notes")
                }
                
                ToolbarItemGroup(placement: .topBarTrailing) {
                    // Pin Button
                    Button(action: togglePin) {
                        Image(systemName: isPinned ? "pin.fill" : "pin")
                            .font(.system(size: 15))
                            .foregroundStyle(isPinned ? AppColors.darkRose : AppColors.secondaryText(for: colorScheme))
                    }
                    .accessibilityLabel(isPinned ? "Unpin note" : "Pin note")
                    
                    // Options Menu
                    if activeNote != nil || !isDraftEmpty {
                        Menu {
                            Button(role: .destructive, action: { showDeleteConfirmation = true }) {
                                Label("Delete Note", systemImage: "trash")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                                .font(.system(size: 15))
                                .foregroundStyle(AppColors.secondaryText(for: colorScheme))
                        }
                        .accessibilityLabel("Note options")
                    }
                    
                    // Done Button
                    Button("Done") {
                        handleDone()
                    }
                    .font(.system(.body, design: .serif, weight: .semibold))
                    .foregroundStyle(AppColors.darkRose)
                }
            }
            .confirmationDialog(
                "Delete this note?",
                isPresented: $showDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete Note", role: .destructive) {
                    deleteCurrentNote()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This action cannot be undone.")
            }
            .onDisappear {
                flushSaveSynchronously()
            }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .background || newPhase == .inactive {
                    flushSaveSynchronously()
                }
            }
        }
    }
    
    // MARK: - Word / Character Counters
    private var currentWordCount: Int {
        let fullText = "\(title) \(content)"
        let words = fullText.split { $0.isWhitespace || $0.isPunctuation }
        return words.count
    }
    
    private var currentCharacterCount: Int {
        title.count + content.count
    }
    
    private var isDraftEmpty: Bool {
        title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    // MARK: - Actions
    private func togglePin() {
        HapticsService.shared.light()
        isPinned.toggle()
        markDirtyAndScheduleSave()
    }
    
    private func markDirtyAndScheduleSave() {
        hasUnsavedChanges = true
        autosaveTask?.cancel()
        
        if isDraftEmpty && activeNote == nil {
            saveStatus = .idle
            return
        }
        
        saveStatus = .saving
        autosaveTask = Task {
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            if !Task.isCancelled {
                await MainActor.run {
                    performSave()
                }
            }
        }
    }
    
    @MainActor
    private func performSave() {
        if isDraftEmpty {
            if let note = activeNote {
                modelContext.delete(note)
                try? modelContext.save()
                activeNote = nil
            }
            saveStatus = .idle
            hasUnsavedChanges = false
            return
        }
        
        do {
            if let note = activeNote {
                note.title = title
                note.content = content
                note.updatedAt = Date()
                note.isPinned = isPinned
            } else {
                let newNote = Note(
                    title: title,
                    content: content,
                    createdAt: Date(),
                    updatedAt: Date(),
                    isPinned: isPinned
                )
                modelContext.insert(newNote)
                activeNote = newNote
            }
            
            try modelContext.save()
            saveStatus = .saved
            hasUnsavedChanges = false
        } catch {
            print("NoteEditorView: Failed to save note: \(error)")
            saveStatus = .idle
        }
    }
    
    private func flushSaveSynchronously() {
        autosaveTask?.cancel()
        if hasUnsavedChanges {
            performSave()
        }
    }
    
    private func handleClose() {
        flushSaveSynchronously()
        dismiss()
    }
    
    private func handleDone() {
        flushSaveSynchronously()
        HapticsService.shared.success()
        dismiss()
    }
    
    private func deleteCurrentNote() {
        HapticsService.shared.medium()
        autosaveTask?.cancel()
        
        if let note = activeNote {
            modelContext.delete(note)
            try? modelContext.save()
        }
        
        dismiss()
    }
}
