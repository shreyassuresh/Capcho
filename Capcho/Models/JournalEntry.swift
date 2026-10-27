//
//  JournalEntry.swift
//  Capcho
//
//  Created by Capcho on 27/10/26.
//

import Foundation
import SwiftData

@Model
final class JournalEntry: Identifiable {
    @Attribute(.unique) var id: UUID
    var title: String
    var content: String
    var createdAt: Date
    var updatedAt: Date
    var mood: String?
    var imageFilename: String?
    var isPinned: Bool
    
    init(
        id: UUID = UUID(),
        title: String = "",
        content: String = "",
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        mood: String? = nil,
        imageFilename: String? = nil,
        isPinned: Bool = false
    ) {
        self.id = id
        self.title = title
        self.content = content
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.mood = mood
        self.imageFilename = imageFilename
        self.isPinned = isPinned
    }
    
    // MARK: - Computed Properties
    
    /// Returns true if the entry contains no meaningful text and no image
    var isEmpty: Bool {
        title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        (imageFilename == nil || imageFilename?.isEmpty == true)
    }
    
    /// Returns title if available, otherwise generates a clean excerpt from the first line of content
    var displayTitle: String {
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        if !cleanTitle.isEmpty {
            return cleanTitle
        }
        
        // Derive from first non-empty line of content
        let lines = content.components(separatedBy: .newlines)
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                return trimmed.count > 60 ? String(trimmed.prefix(60)) + "…" : trimmed
            }
        }
        
        return "Untitled Entry"
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
        
        // If the title was empty and first line was used as title, start snippet from line 2 if available
        if cleanTitle.isEmpty && lines.count > 1 {
            return lines.dropFirst().joined(separator: " ")
        }
        
        return lines.joined(separator: " ")
    }
    
    /// Word count of title and content combined
    var wordCount: Int {
        let fullText = "\(title) \(content)"
        let words = fullText.split { $0.isWhitespace || $0.isPunctuation }
        return words.count
    }
    
    /// Character count of title and content combined
    var characterCount: Int {
        title.count + content.count
    }
    
    /// Friendly date formatting (e.g., "Tuesday, Oct 27" or "Oct 27, 2026")
    var formattedDate: String {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        
        if calendar.isDateInToday(createdAt) {
            return "Today"
        } else if calendar.isDateInYesterday(createdAt) {
            return "Yesterday"
        } else if calendar.isDate(createdAt, equalTo: Date(), toGranularity: .year) {
            formatter.dateFormat = "EEEE, MMM d"
            return formatter.string(from: createdAt)
        } else {
            formatter.dateFormat = "MMM d, yyyy"
            return formatter.string(from: createdAt)
        }
    }
    
    /// Formatted time string (e.g. "2:30 PM")
    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.timeStyle = .short
        return formatter.string(from: createdAt)
    }
}

// MARK: - Curated Mood Enum
enum CapchoMood: String, CaseIterable, Identifiable {
    case peaceful = "peaceful"
    case grateful = "grateful"
    case reflective = "reflective"
    case joyful = "joyful"
    case inspired = "inspired"
    case tender = "tender"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .peaceful: return "Peaceful"
        case .grateful: return "Grateful"
        case .reflective: return "Reflective"
        case .joyful: return "Joyful"
        case .inspired: return "Inspired"
        case .tender: return "Tender"
        }
    }
    
    var emoji: String {
        switch self {
        case .peaceful: return "🌿"
        case .grateful: return "🌸"
        case .reflective: return "🌙"
        case .joyful: return "☀️"
        case .inspired: return "✨"
        case .tender: return "🕊️"
        }
    }
    
    var iconName: String {
        switch self {
        case .peaceful: return "leaf.fill"
        case .grateful: return "heart.fill"
        case .reflective: return "moon.stars.fill"
        case .joyful: return "sun.max.fill"
        case .inspired: return "sparkles"
        case .tender: return "bird.fill"
        }
    }
    
    static func from(string: String?) -> CapchoMood? {
        guard let string = string?.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) else { return nil }
        return CapchoMood(rawValue: string)
    }
}
