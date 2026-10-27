//
//  Note.swift
//  Capcho
//
//  Created by Capcho on 27/10/26.
//

import Foundation
import SwiftData

@Model
final class Note: Identifiable {
    @Attribute(.unique) var id: UUID
    var title: String
    var content: String
    var createdAt: Date
    var updatedAt: Date
    var isPinned: Bool
    
    init(
        id: UUID = UUID(),
        title: String = "",
        content: String = "",
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        isPinned: Bool = false
    ) {
        self.id = id
        self.title = title
        self.content = content
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isPinned = isPinned
    }
    
    // MARK: - Computed Properties
    
    /// Returns true if the note contains no meaningful text
    var isEmpty: Bool {
        title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    /// Returns title if available, otherwise generates a clean excerpt from the first line of content
    var displayTitle: String {
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        if !cleanTitle.isEmpty {
            return cleanTitle
        }
        
        let lines = content.components(separatedBy: .newlines)
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                return trimmed.count > 50 ? String(trimmed.prefix(50)) + "…" : trimmed
            }
        }
        
        return "Untitled Note"
    }
    
    /// Short preview snippet of the body content
    var snippet: String {
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let lines = content.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        if lines.isEmpty {
            return "No additional text"
        }
        
        if cleanTitle.isEmpty && lines.count > 1 {
            return lines.dropFirst().joined(separator: " ")
        }
        
        return lines.joined(separator: " ")
    }
    
    /// Combined word count
    var wordCount: Int {
        let fullText = "\(title) \(content)"
        let words = fullText.split { $0.isWhitespace || $0.isPunctuation }
        return words.count
    }
    
    /// Combined character count
    var characterCount: Int {
        title.count + content.count
    }
    
    /// Formatted last edited timestamp
    var formattedLastEdited: String {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        
        if calendar.isDateInToday(updatedAt) {
            formatter.timeStyle = .short
            return "Today, \(formatter.string(from: updatedAt))"
        } else if calendar.isDateInYesterday(updatedAt) {
            formatter.timeStyle = .short
            return "Yesterday, \(formatter.string(from: updatedAt))"
        } else if calendar.isDate(updatedAt, equalTo: Date(), toGranularity: .year) {
            formatter.dateFormat = "MMM d"
            return formatter.string(from: updatedAt)
        } else {
            formatter.dateFormat = "MMM d, yyyy"
            return formatter.string(from: updatedAt)
        }
    }
}
