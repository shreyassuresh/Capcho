//
//  SettingsView.swift
//  Capcho
//
//  Created by Capcho on 27/10/26.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    
    // SwiftData Queries to retrieve all entries and notes for export
    @Query private var entries: [JournalEntry]
    @Query private var notes: [Note]
    
    // Persistent Preferences
    @AppStorage("appAppearance") private var appAppearance: String = "system"
    @AppStorage("hapticsEnabled") private var hapticsEnabled: Bool = true
    
    // Export State
    @State private var isExporting: Bool = false
    @State private var exportURL: URL? = nil
    @State private var showExportShareSheet: Bool = false
    
    // Import State
    @State private var showImportPicker: Bool = false
    @State private var pendingImportSummary: CapchoImportSummary? = nil
    @State private var showImportConfirmation: Bool = false
    @State private var importErrorMessage: String? = nil
    @State private var showImportErrorAlert: Bool = false
    @State private var showImportSuccessAlert: Bool = false
    @State private var importedCounts: (entries: Int, notes: Int) = (0, 0)
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background(for: colorScheme)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Title
                        Text("Settings")
                            .font(AppTypography.journalHeading)
                            .foregroundStyle(AppColors.primaryText(for: colorScheme))
                            .padding(.horizontal, 20)
                            .padding(.top, 12)
                        
                        // Appearance Section
                        VStack(alignment: .leading, spacing: 12) {
                            sectionHeader("APPEARANCE")
                            
                            CapchoCard {
                                VStack(alignment: .leading, spacing: 14) {
                                    Text("Theme")
                                        .font(.system(.body, design: .serif, weight: .medium))
                                        .foregroundStyle(AppColors.primaryText(for: colorScheme))
                                    
                                    Picker("Appearance", selection: $appAppearance) {
                                        Text("System").tag("system")
                                        Text("Light").tag("light")
                                        Text("Dark").tag("dark")
                                    }
                                    .pickerStyle(.segmented)
                                    .onChange(of: appAppearance) { _, _ in
                                        HapticsService.shared.selection()
                                    }
                                }
                                .padding(16)
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Experience Section
                        VStack(alignment: .leading, spacing: 12) {
                            sectionHeader("EXPERIENCE")
                            
                            CapchoCard {
                                Toggle(isOn: $hapticsEnabled) {
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text("Haptic Feedback")
                                            .font(.system(.body, design: .serif, weight: .medium))
                                            .foregroundStyle(AppColors.primaryText(for: colorScheme))
                                        
                                        Text("Gentle tactile responses when writing, pinning, and saving")
                                            .font(AppTypography.metaText)
                                            .foregroundStyle(AppColors.secondaryText(for: colorScheme))
                                    }
                                }
                                .tint(AppColors.cottonRose)
                                .padding(16)
                                .onChange(of: hapticsEnabled) { _, newValue in
                                    if newValue {
                                        HapticsService.shared.light()
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Data & Backup Section
                        VStack(alignment: .leading, spacing: 12) {
                            sectionHeader("DATA & BACKUP")
                            
                            CapchoCard {
                                VStack(spacing: 0) {
                                    // Export Button
                                    Button {
                                        handleExport()
                                    } label: {
                                        HStack {
                                            VStack(alignment: .leading, spacing: 3) {
                                                Text("Export Journal Data")
                                                    .font(.system(.body, design: .serif, weight: .medium))
                                                    .foregroundStyle(AppColors.primaryText(for: colorScheme))
                                                
                                                Text("Create a complete backup with entries, notes, and photos")
                                                    .font(AppTypography.metaText)
                                                    .foregroundStyle(AppColors.secondaryText(for: colorScheme))
                                            }
                                            
                                            Spacer()
                                            
                                            if isExporting {
                                                ProgressView()
                                                    .tint(AppColors.darkRose)
                                            } else {
                                                Image(systemName: "square.and.arrow.up")
                                                    .font(.system(size: 15))
                                                    .foregroundStyle(AppColors.darkRose)
                                            }
                                        }
                                        .padding(16)
                                    }
                                    .disabled(isExporting)
                                    
                                    Divider()
                                        .overlay(AppColors.divider(for: colorScheme))
                                    
                                    // Import Button
                                    Button {
                                        HapticsService.shared.light()
                                        showImportPicker = true
                                    } label: {
                                        HStack {
                                            VStack(alignment: .leading, spacing: 3) {
                                                Text("Restore from Backup")
                                                    .font(.system(.body, design: .serif, weight: .medium))
                                                    .foregroundStyle(AppColors.primaryText(for: colorScheme))
                                                
                                                Text("Import a previously saved Capcho backup file")
                                                    .font(AppTypography.metaText)
                                                    .foregroundStyle(AppColors.secondaryText(for: colorScheme))
                                            }
                                            
                                            Spacer()
                                            
                                            Image(systemName: "square.and.arrow.down")
                                                .font(.system(size: 15))
                                                .foregroundStyle(AppColors.darkRose)
                                        }
                                        .padding(16)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Privacy & Architecture Statement
                        VStack(alignment: .leading, spacing: 12) {
                            sectionHeader("PRIVACY")
                            
                            CapchoCard {
                                VStack(alignment: .leading, spacing: 10) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "lock.shield.fill")
                                            .font(.system(size: 16))
                                            .foregroundStyle(AppColors.darkRose)
                                        
                                        Text("100% Offline & Private")
                                            .font(.system(.subheadline, design: .serif, weight: .medium))
                                            .foregroundStyle(AppColors.primaryText(for: colorScheme))
                                    }
                                    
                                    Text("Every thought, memory, and photo remains stored solely on your device in your private app sandbox. Capcho contains no accounts, no trackers, no cloud sync, and requires zero network access. It is completely usable in Airplane Mode.")
                                        .font(.system(.footnote, design: .default))
                                        .foregroundStyle(AppColors.secondaryText(for: colorScheme))
                                        .lineSpacing(3)
                                    
                                    Text("Note on Device Backups: Standard device-level backups (such as encrypted iOS backups or your Mac/PC backups) will include your Capcho journal data.")
                                        .font(.system(size: 11, design: .default))
                                        .foregroundStyle(AppColors.secondaryText(for: colorScheme).opacity(0.8))
                                        .lineSpacing(2)
                                        .padding(.top, 2)
                                }
                                .padding(16)
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // About Capcho
                        VStack(alignment: .leading, spacing: 12) {
                            sectionHeader("ABOUT")
                            
                            CapchoCard {
                                VStack(spacing: 14) {
                                    HStack(spacing: 12) {
                                        // App Brand Mark
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                .fill(AppColors.cottonRose)
                                                .frame(width: 44, height: 44)
                                            
                                            Image(systemName: "book.pages")
                                                .font(.system(size: 20, weight: .light))
                                                .foregroundStyle(Color(hex: 0x3D3436))
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("Capcho")
                                                .font(.system(.headline, design: .serif, weight: .medium))
                                                .foregroundStyle(AppColors.primaryText(for: colorScheme))
                                            
                                            Text("Minimal Offline Digital Journal")
                                                .font(AppTypography.metaText)
                                                .foregroundStyle(AppColors.secondaryText(for: colorScheme))
                                        }
                                        
                                        Spacer()
                                        
                                        Text("v1.0 (Build 1)")
                                            .font(AppTypography.metaText)
                                            .foregroundStyle(AppColors.secondaryText(for: colorScheme))
                                    }
                                    
                                    Divider()
                                        .overlay(AppColors.divider(for: colorScheme))
                                    
                                    Text("Designed for quiet reflection, peaceful thoughts, and the joy of honest words.")
                                        .font(.system(.footnote, design: .serif, weight: .regular))
                                        .foregroundStyle(AppColors.secondaryText(for: colorScheme))
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .padding(16)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 36)
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showExportShareSheet) {
                if let url = exportURL {
                    ShareActivitySheet(activityItems: [url])
                }
            }
            .fileImporter(
                isPresented: $showImportPicker,
                allowedContentTypes: [.data, .json, UTType(filenameExtension: "capcho") ?? .data],
                allowsMultipleSelection: false
            ) { result in
                handleImportSelection(result)
            }
            .confirmationDialog(
                "Restore Backup?",
                isPresented: $showImportConfirmation,
                titleVisibility: .visible
            ) {
                Button("Restore Backup", role: .none) {
                    executeImport()
                }
                Button("Cancel", role: .cancel) {
                    pendingImportSummary = nil
                }
            } message: {
                if let summary = pendingImportSummary {
                    Text("Found \(summary.entryCount) journal entries, \(summary.noteCount) notes, and \(summary.imageCount) photos.\n\nThese items will be safely merged into your journal without overwriting existing entries.")
                } else {
                    Text("Would you like to import this backup?")
                }
            }
            .alert("Import Error", isPresented: $showImportErrorAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(importErrorMessage ?? "An unknown error occurred during import.")
            }
            .alert("Backup Restored", isPresented: $showImportSuccessAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Successfully imported \(importedCounts.entries) journal entries and \(importedCounts.notes) notes.")
            }
        }
    }
    
    // MARK: - Section Header
    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 11, weight: .semibold, design: .serif))
            .foregroundStyle(AppColors.darkRose)
            .tracking(1.2)
            .padding(.leading, 4)
    }
    
    // MARK: - Export Logic
    private func handleExport() {
        HapticsService.shared.light()
        isExporting = true
        
        Task {
            do {
                let fileURL = try ExportImportService.shared.generateBackupFile(
                    entries: entries,
                    notes: notes
                )
                await MainActor.run {
                    self.exportURL = fileURL
                    self.isExporting = false
                    self.showExportShareSheet = true
                    HapticsService.shared.success()
                }
            } catch {
                await MainActor.run {
                    self.isExporting = false
                    self.importErrorMessage = "Failed to export data: \(error.localizedDescription)"
                    self.showImportErrorAlert = true
                }
            }
        }
    }
    
    // MARK: - Import Logic
    private func handleImportSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let fileURL = urls.first else { return }
            do {
                let summary = try ExportImportService.shared.inspectBackup(from: fileURL)
                pendingImportSummary = summary
                showImportConfirmation = true
                HapticsService.shared.light()
            } catch {
                importErrorMessage = error.localizedDescription
                showImportErrorAlert = true
                HapticsService.shared.warning()
            }
        case .failure(let error):
            importErrorMessage = error.localizedDescription
            showImportErrorAlert = true
            HapticsService.shared.warning()
        }
    }
    
    private func executeImport() {
        guard let summary = pendingImportSummary else { return }
        do {
            try ExportImportService.shared.importBackup(summary.backupData, into: modelContext)
            importedCounts = (entries: summary.entryCount, notes: summary.noteCount)
            pendingImportSummary = nil
            showImportSuccessAlert = true
            HapticsService.shared.success()
        } catch {
            importErrorMessage = "Failed to restore backup: \(error.localizedDescription)"
            showImportErrorAlert = true
            HapticsService.shared.warning()
        }
    }
}

// MARK: - Native UIActivityViewController Wrapper
struct ShareActivitySheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    let applicationActivities: [UIActivity]? = nil
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: applicationActivities
        )
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
