//
//  ExportImportService.swift
//  Capcho
//
//  Created by Capcho on 27/10/26.
//

import Foundation
import SwiftData

// MARK: - DTOs for Versioned Backup
struct JournalEntryDTO: Codable {
    let id: UUID
    let title: String
    let content: String
    let createdAt: Date
    let updatedAt: Date
    let mood: String?
    let imageFilename: String?
    let imageBase64: String?
    let isPinned: Bool
}

struct NoteDTO: Codable {
    let id: UUID
    let title: String
    let content: String
    let createdAt: Date
    let updatedAt: Date
    let isPinned: Bool
}

struct CapchoBackupData: Codable {
    var app: String = "Capcho"
    var version: Int = 1
    var exportedAt: Date = Date()
    var entries: [JournalEntryDTO]
    var notes: [NoteDTO]
}

struct CapchoImportSummary {
    let entryCount: Int
    let noteCount: Int
    let imageCount: Int
    let backupData: CapchoBackupData
}

enum ImportError: LocalizedError {
    case invalidFileFormat
    case unsupportedVersion(Int)
    case corruptedData(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidFileFormat:
            return "The selected file is not a valid Capcho backup."
        case .unsupportedVersion(let v):
            return "This backup was created with a newer version of Capcho (v\(v)) and cannot be imported."
        case .corruptedData(let details):
            return "Unable to parse backup data: \(details)"
        }
    }
}

final class ExportImportService {
    static let shared = ExportImportService()
    
    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }()
    
    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
    
    private init() {}
    
    // MARK: - Export
    func generateBackupFile(entries: [JournalEntry], notes: [Note]) throws -> URL {
        let entryDTOs: [JournalEntryDTO] = entries.map { entry in
            var base64String: String? = nil
            if let imgFile = entry.imageFilename, let data = ImageStorageService.shared.imageData(for: imgFile) {
                base64String = data.base64EncodedString()
            }
            return JournalEntryDTO(
                id: entry.id,
                title: entry.title,
                content: entry.content,
                createdAt: entry.createdAt,
                updatedAt: entry.updatedAt,
                mood: entry.mood,
                imageFilename: entry.imageFilename,
                imageBase64: base64String,
                isPinned: entry.isPinned
            )
        }
        
        let noteDTOs: [NoteDTO] = notes.map { note in
            NoteDTO(
                id: note.id,
                title: note.title,
                content: note.content,
                createdAt: note.createdAt,
                updatedAt: note.updatedAt,
                isPinned: note.isPinned
            )
        }
        
        let backup = CapchoBackupData(
            entries: entryDTOs,
            notes: noteDTOs
        )
        
        let data = try encoder.encode(backup)
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HHmm"
        let timestamp = dateFormatter.string(from: Date())
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("Capcho_Backup_\(timestamp).capcho")
        
        try data.write(to: fileURL, options: .atomic)
        return fileURL
    }
    
    // MARK: - Validate Import File
    func inspectBackup(from fileURL: URL) throws -> CapchoImportSummary {
        // Need security scoped resource access if picked from document picker
        let isAccessing = fileURL.startAccessingSecurityScopedResource()
        defer {
            if isAccessing {
                fileURL.stopAccessingSecurityScopedResource()
            }
        }
        
        let data = try Data(contentsOf: fileURL)
        let backup: CapchoBackupData
        do {
            backup = try decoder.decode(CapchoBackupData.self, from: data)
        } catch {
            throw ImportError.invalidFileFormat
        }
        
        guard backup.app == "Capcho" else {
            throw ImportError.invalidFileFormat
        }
        
        guard backup.version <= 1 else {
            throw ImportError.unsupportedVersion(backup.version)
        }
        
        let imageCount = backup.entries.filter { $0.imageBase64 != nil }.count
        
        return CapchoImportSummary(
            entryCount: backup.entries.count,
            noteCount: backup.notes.count,
            imageCount: imageCount,
            backupData: backup
        )
    }
    
    // MARK: - Perform Import
    @MainActor
    func importBackup(
        _ backup: CapchoBackupData,
        into context: ModelContext
    ) throws {
        // Fetch existing IDs to avoid silent overwrite
        let existingEntriesDescriptor = FetchDescriptor<JournalEntry>()
        let existingEntries = (try? context.fetch(existingEntriesDescriptor)) ?? []
        let existingEntryIds = Set(existingEntries.map { $0.id })
        
        let existingNotesDescriptor = FetchDescriptor<Note>()
        let existingNotes = (try? context.fetch(existingNotesDescriptor)) ?? []
        let existingNoteIds = Set(existingNotes.map { $0.id })
        
        // Import entries
        for dto in backup.entries {
            // Restore image if present
            var savedFilename = dto.imageFilename
            if let base64 = dto.imageBase64, let imgData = Data(base64Encoded: base64) {
                let filename = dto.imageFilename ?? "\(UUID().uuidString).jpg"
                ImageStorageService.shared.saveRawData(imgData, filename: filename)
                savedFilename = filename
            }
            
            // If ID already exists in local DB, create a distinct record to avoid silent overwrite
            let entryId = existingEntryIds.contains(dto.id) ? UUID() : dto.id
            
            let entry = JournalEntry(
                id: entryId,
                title: dto.title,
                content: dto.content,
                createdAt: dto.createdAt,
                updatedAt: dto.updatedAt,
                mood: dto.mood,
                imageFilename: savedFilename,
                isPinned: dto.isPinned
            )
            context.insert(entry)
        }
        
        // Import notes
        for dto in backup.notes {
            let noteId = existingNoteIds.contains(dto.id) ? UUID() : dto.id
            
            let note = Note(
                id: noteId,
                title: dto.title,
                content: dto.content,
                createdAt: dto.createdAt,
                updatedAt: dto.updatedAt,
                isPinned: dto.isPinned
            )
            context.insert(note)
        }
        
        try context.save()
    }
}
