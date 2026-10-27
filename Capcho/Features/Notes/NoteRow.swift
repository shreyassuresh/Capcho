//
//  NoteRow.swift
//  Capcho
//
//  Created by Capcho on 27/10/26.
//

import SwiftUI

struct NoteRow: View {
    let note: Note
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        CapchoCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top, spacing: 8) {
                    Text(note.displayTitle)
                        .font(AppTypography.cardTitle)
                        .foregroundStyle(AppColors.primaryText(for: colorScheme))
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    Spacer()
                    
                    if note.isPinned {
                        Image(systemName: "pin.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(AppColors.darkRose)
                            .accessibilityLabel("Pinned note")
                    }
                }
                
                Text(note.snippet)
                    .font(AppTypography.cardSnippet)
                    .foregroundStyle(AppColors.secondaryText(for: colorScheme))
                    .lineLimit(3)
                    .lineSpacing(3)
                    .multilineTextAlignment(.leading)
                
                HStack {
                    Text("Edited \(note.formattedLastEdited)")
                        .font(AppTypography.metaText)
                        .foregroundStyle(AppColors.secondaryText(for: colorScheme).opacity(0.85))
                    
                    Spacer()
                    
                    if note.wordCount > 0 {
                        Text("\(note.wordCount) words")
                            .font(AppTypography.metaText)
                            .foregroundStyle(AppColors.secondaryText(for: colorScheme).opacity(0.7))
                    }
                }
                .padding(.top, 4)
            }
            .padding(.all, 16)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(note.displayTitle). Edited \(note.formattedLastEdited). \(note.snippet)")
    }
}
