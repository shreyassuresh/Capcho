//
//  PersistenceController.swift
//  Capcho
//
//  Created by Capcho on 27/10/26.
//

import Foundation
import SwiftData

@MainActor
final class PersistenceController {
    static let shared = PersistenceController(inMemory: false)
    
    let container: ModelContainer
    
    init(inMemory: Bool = false) {
        let schema = Schema([
            JournalEntry.self,
            Note.self
        ])
        
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: inMemory,
            allowsSave: true
        )
        
        do {
            self.container = try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            print("PersistenceController: Error initializing ModelContainer: \(error). Falling back to in-memory store.")
            // Fallback to in-memory container so the user does not experience a hard crash
            let fallbackConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            do {
                self.container = try ModelContainer(for: schema, configurations: [fallbackConfig])
            } catch {
                fatalError("PersistenceController: Critical failure initializing ModelContainer: \(error)")
            }
        }
    }
    
    // MARK: - Preview Helper
    static var preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        let context = controller.container.mainContext
        
        // Add sample entries for SwiftUI Previews
        let entry1 = JournalEntry(
            title: "Morning light in the studio",
            content: "The autumn sun poured across the wooden desk this morning, catching the steam rising from a cup of earl grey. Spent a quiet half hour listening to the rain gently tapping on the windowpane before the city woke up.",
            createdAt: Date(),
            updatedAt: Date(),
            mood: "peaceful",
            isPinned: true
        )
        
        let entry2 = JournalEntry(
            title: "Little moments of gratitude",
            content: "Met an old friend at the corner bakery. We talked for an hour about old books and how strange time feels. Sometimes the simplest conversations leave the longest resonance.",
            createdAt: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date(),
            updatedAt: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date(),
            mood: "grateful",
            isPinned: false
        )
        
        let note1 = Note(
            title: "Books to read next",
            content: "• The Summer Book — Tove Jansson\n• The Architecture of Happiness — Alain de Botton\n• Letters to a Young Poet — Rainer Maria Rilke",
            createdAt: Date(),
            updatedAt: Date(),
            isPinned: true
        )
        
        let note2 = Note(
            title: "Weekend thoughts",
            content: "Restock watercolor paper, pick up roasted coffee beans from the roastery, and take a long walk along the botanical gardens.",
            createdAt: Calendar.current.date(byAdding: .day, value: -2, to: Date()) ?? Date(),
            updatedAt: Calendar.current.date(byAdding: .day, value: -2, to: Date()) ?? Date(),
            isPinned: false
        )
        
        context.insert(entry1)
        context.insert(entry2)
        context.insert(note1)
        context.insert(note2)
        
        try? context.save()
        return controller
    }()
}
