//
//  AppTypography.swift
//  Capcho
//
//  Created by Capcho on 27/10/26.
//

import SwiftUI

enum AppTypography {
    // MARK: - Wordmark
    static var wordmark: Font {
        .system(size: 26, weight: .light, design: .serif)
    }
    
    // MARK: - Journal Headings
    static var journalHeading: Font {
        .system(.title, design: .serif, weight: .medium)
    }
    
    static var journalSubheading: Font {
        .system(.title3, design: .serif, weight: .regular)
    }
    
    static var dateHeader: Font {
        .system(.subheadline, design: .serif, weight: .medium)
    }
    
    static var dateSubhead: Font {
        .system(.footnote, design: .default, weight: .regular)
    }
    
    // MARK: - Editor Typography
    static var editorTitle: Font {
        .system(.title2, design: .serif, weight: .medium)
    }
    
    static var editorBody: Font {
        .system(.body, design: .default, weight: .regular)
    }
    
    // MARK: - Card Previews
    static var cardTitle: Font {
        .system(.headline, design: .serif, weight: .semibold)
    }
    
    static var cardSnippet: Font {
        .system(.subheadline, design: .default, weight: .regular)
    }
    
    static var metaText: Font {
        .system(.caption, design: .default, weight: .medium)
    }
    
    // MARK: - Empty States
    static var emptyTitle: Font {
        .system(.title3, design: .serif, weight: .medium)
    }
    
    static var emptySubtitle: Font {
        .system(.subheadline, design: .default, weight: .regular)
    }
}
