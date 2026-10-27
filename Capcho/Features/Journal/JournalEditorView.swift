//
//  JournalEditorView.swift
//  Capcho
//
//  Created by Capcho on 27/10/26.
//

import SwiftUI
import SwiftData
import PhotosUI

struct JournalEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.scenePhase) private var scenePhase
    
    // Existing entry (nil if creating new)
    private let initialEntry: JournalEntry?
    
    // Local draft state
    @State private var activeEntry: JournalEntry?
    @State private var title: String
    @State private var content: String
    @State private var mood: String?
    @State private var imageFilename: String?
    @State private var isPinned: Bool
    
    // Photos Picker & Image State
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var loadedPhoto: UIImage? = nil
    @State private var isProcessingPhoto: Bool = false
    
    // Status & UI State
    @State private var saveStatus: CapchoSaveIndicator.Status = .idle
    @State private var autosaveTask: Task<Void, Never>? = nil
    @State private var showDeleteConfirmation: Bool = false
    @State private var hasUnsavedChanges: Bool = false
    
    // Initializer
    init(entry: JournalEntry? = nil) {
        self.initialEntry = entry
        _activeEntry = State(initialValue: entry)
        _title = State(initialValue: entry?.title ?? "")
        _content = State(initialValue: entry?.content ?? "")
        _mood = State(initialValue: entry?.mood)
        _imageFilename = State(initialValue: entry?.imageFilename)
        _isPinned = State(initialValue: entry?.isPinned ?? false)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Warm paper background
                AppColors.background(for: colorScheme)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Date & Time Banner
                        HStack(alignment: .center) {
                            Text(formattedDisplayDate)
                                .font(AppTypography.dateHeader)
                                .foregroundStyle(AppColors.secondaryText(for: colorScheme))
                            
                            Spacer()
                            
                            CapchoSaveIndicator(status: saveStatus)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 12)
                        
                        // Title Input
                        TextField("Give this moment a title…", text: $title, axis: .vertical)
                            .font(AppTypography.editorTitle)
                            .foregroundStyle(AppColors.primaryText(for: colorScheme))
                            .lineLimit(1...3)
                            .padding(.horizontal, 20)
                            .onChange(of: title) { _, _ in
                                markDirtyAndScheduleSave()
                            }
                            .accessibilityLabel("Journal entry title")
                        
                        // Mood Selector
                        moodSelectorView
                            .padding(.horizontal, 20)
                        
                        // Attached Image View (if present)
                        if let photo = loadedPhoto {
                            attachedImageView(photo)
                                .padding(.horizontal, 20)
                        } else if isProcessingPhoto {
                            HStack {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .tint(AppColors.darkRose)
                                Text("Loading image…")
                                    .font(AppTypography.metaText)
                                    .foregroundStyle(AppColors.secondaryText(for: colorScheme))
                            }
                            .padding(.horizontal, 20)
                        }
                        
                        // Main Writing Canvas
                        ZStack(alignment: .topLeading) {
                            if content.isEmpty {
                                Text("What's on your mind? Capture the feeling, the light, the small details…")
                                    .font(AppTypography.editorBody)
                                    .foregroundStyle(AppColors.secondaryText(for: colorScheme).opacity(0.6))
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 8)
                                    .lineSpacing(6)
                                    .allowsHitTesting(false)
                            }
                            
                            TextEditor(text: $content)
                                .font(AppTypography.editorBody)
                                .foregroundStyle(AppColors.primaryText(for: colorScheme))
                                .scrollContentBackground(.hidden)
                                .background(Color.clear)
                                .lineSpacing(6)
                                .frame(minHeight: 280)
                                .padding(.horizontal, 20)
                                .onChange(of: content) { _, _ in
                                    markDirtyAndScheduleSave()
                                }
                                .accessibilityLabel("Journal entry content")
                        }
                        
                        // Subtle Bottom Counter & Details
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
                    .accessibilityLabel("Back to Journal")
                }
                
                ToolbarItemGroup(placement: .topBarTrailing) {
                    // Pin / Unpin Button
                    Button(action: togglePin) {
                        Image(systemName: isPinned ? "pin.fill" : "pin")
                            .font(.system(size: 15))
                            .foregroundStyle(isPinned ? AppColors.darkRose : AppColors.secondaryText(for: colorScheme))
                    }
                    .accessibilityLabel(isPinned ? "Unpin entry" : "Pin entry")
                    
                    // Photo Attachment Button
                    PhotosPicker(selection: $selectedPhotoItem, matching: .images, photoLibrary: .shared()) {
                        Image(systemName: imageFilename == nil ? "photo" : "photo.badge.checkmark")
                            .font(.system(size: 15))
                            .foregroundStyle(AppColors.darkRose)
                    }
                    .accessibilityLabel("Attach photo")
                    .onChange(of: selectedPhotoItem) { _, newItem in
                        handlePhotoSelection(newItem)
                    }
                    
                    // Options Menu (Delete)
                    if activeEntry != nil || !isDraftEmpty {
                        Menu {
                            Button(role: .destructive, action: { showDeleteConfirmation = true }) {
                                Label("Delete Entry", systemImage: "trash")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                                .font(.system(size: 15))
                                .foregroundStyle(AppColors.secondaryText(for: colorScheme))
                        }
                        .accessibilityLabel("Entry options")
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
                "Delete this entry?",
                isPresented: $showDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete Entry", role: .destructive) {
                    deleteCurrentEntry()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This action cannot be undone and will permanently remove this entry.")
            }
            .onAppear {
                loadExistingPhotoIfNeeded()
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
    
    // MARK: - Mood Selector Subview
    private var moodSelectorView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(CapchoMood.allCases) { moodOption in
                    let isSelected = (mood == moodOption.rawValue)
                    
                    Button {
                        HapticsService.shared.selection()
                        if isSelected {
                            mood = nil
                        } else {
                            mood = moodOption.rawValue
                        }
                        markDirtyAndScheduleSave()
                    } label: {
                        HStack(spacing: 5) {
                            Text(moodOption.emoji)
                                .font(.system(size: 13))
                            Text(moodOption.displayName)
                                .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                                .foregroundStyle(isSelected ? Color(hex: 0x3D3436) : AppColors.secondaryText(for: colorScheme))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(
                            Capsule()
                                .fill(isSelected ? AppColors.cottonRose : AppColors.badgeBackground(for: colorScheme))
                        )
                        .overlay(
                            Capsule()
                                .stroke(isSelected ? AppColors.darkRose.opacity(0.4) : AppColors.divider(for: colorScheme), lineWidth: 0.6)
                        )
                    }
                    .accessibilityLabel("\(moodOption.displayName) mood\(isSelected ? ", selected" : "")")
                }
            }
            .padding(.vertical, 2)
        }
    }
    
    // MARK: - Attached Image Subview
    private func attachedImageView(_ image: UIImage) -> some View {
        ZStack(alignment: .topTrailing) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(maxHeight: 220)
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(AppColors.divider(for: colorScheme), lineWidth: 0.8)
                )
            
            // Remove Photo Button
            Button {
                removeAttachedPhoto()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(Color.white, Color.black.opacity(0.6))
                    .padding(8)
            }
            .accessibilityLabel("Remove attached photo")
        }
    }
    
    // MARK: - Date Formatting Helper
    private var formattedDisplayDate: String {
        let date = activeEntry?.createdAt ?? Date()
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateFormat = "EEEE, MMMM d · h:mm a"
        return formatter.string(from: date)
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
        content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        (imageFilename == nil || imageFilename?.isEmpty == true)
    }
    
    // MARK: - Pin Action
    private func togglePin() {
        HapticsService.shared.light()
        isPinned.toggle()
        markDirtyAndScheduleSave()
    }
    
    // MARK: - Photo Actions
    private func handlePhotoSelection(_ item: PhotosPickerItem?) {
        guard let item = item else { return }
        isProcessingPhoto = true
        
        Task {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                // Delete previous image if any
                if let old = imageFilename {
                    ImageStorageService.shared.deleteImage(named: old)
                }
                
                if let newFilename = ImageStorageService.shared.saveImage(image) {
                    await MainActor.run {
                        self.loadedPhoto = image
                        self.imageFilename = newFilename
                        self.isProcessingPhoto = false
                        self.markDirtyAndScheduleSave()
                    }
                }
            } else {
                await MainActor.run {
                    self.isProcessingPhoto = false
                }
            }
        }
    }
    
    private func loadExistingPhotoIfNeeded() {
        if let filename = imageFilename, loadedPhoto == nil {
            loadedPhoto = ImageStorageService.shared.loadImage(named: filename)
        }
    }
    
    private func removeAttachedPhoto() {
        HapticsService.shared.light()
        if let filename = imageFilename {
            ImageStorageService.shared.deleteImage(named: filename)
        }
        imageFilename = nil
        loadedPhoto = nil
        selectedPhotoItem = nil
        markDirtyAndScheduleSave()
    }
    
    // MARK: - Autosave & Persistence Logic
    private func markDirtyAndScheduleSave() {
        hasUnsavedChanges = true
        autosaveTask?.cancel()
        
        // If entirely empty, avoid premature persistence
        if isDraftEmpty && activeEntry == nil {
            saveStatus = .idle
            return
        }
        
        saveStatus = .saving
        autosaveTask = Task {
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second debounce
            if !Task.isCancelled {
                await MainActor.run {
                    performSave()
                }
            }
        }
    }
    
    @MainActor
    private func performSave() {
        // If empty draft and no active entry, do nothing
        if isDraftEmpty {
            if let entry = activeEntry {
                // Clean up empty entry
                modelContext.delete(entry)
                try? modelContext.save()
                activeEntry = nil
            }
            saveStatus = .idle
            hasUnsavedChanges = false
            return
        }
        
        do {
            if let entry = activeEntry {
                entry.title = title
                entry.content = content
                entry.updatedAt = Date()
                entry.mood = mood
                entry.imageFilename = imageFilename
                entry.isPinned = isPinned
            } else {
                let newEntry = JournalEntry(
                    title: title,
                    content: content,
                    createdAt: Date(),
                    updatedAt: Date(),
                    mood: mood,
                    imageFilename: imageFilename,
                    isPinned: isPinned
                )
                modelContext.insert(newEntry)
                activeEntry = newEntry
            }
            
            try modelContext.save()
            saveStatus = .saved
            hasUnsavedChanges = false
        } catch {
            print("JournalEditorView: Failed to save entry: \(error)")
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
    
    private func deleteCurrentEntry() {
        HapticsService.shared.medium()
        autosaveTask?.cancel()
        
        if let filename = imageFilename {
            ImageStorageService.shared.deleteImage(named: filename)
        }
        
        if let entry = activeEntry {
            modelContext.delete(entry)
            try? modelContext.save()
        }
        
        dismiss()
    }
}
