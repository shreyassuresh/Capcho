//
//  JournalEntryRow.swift
//  Capcho
//
//  Created by Capcho on 27/10/26.
//

import SwiftUI

struct JournalEntryRow: View {
    let entry: JournalEntry
    var onTogglePin: (() -> Void)? = nil
    var onDelete: (() -> Void)? = nil
    
    @Environment(\.colorScheme) private var colorScheme
    @State private var thumbnailImage: UIImage? = nil
    
    var body: some View {
        CapchoCard {
            VStack(alignment: .leading, spacing: 10) {
                // Header: Date, Time, Mood, Pin
                HStack(alignment: .center, spacing: 8) {
                    HStack(spacing: 4) {
                        Text(entry.formattedDate)
                            .font(AppTypography.dateHeader)
                            .foregroundStyle(AppColors.primaryText(for: colorScheme))
                        
                        Text("·")
                            .font(AppTypography.dateSubhead)
                            .foregroundStyle(AppColors.secondaryText(for: colorScheme))
                        
                        Text(entry.formattedTime)
                            .font(AppTypography.dateSubhead)
                            .foregroundStyle(AppColors.secondaryText(for: colorScheme))
                    }
                    
                    Spacer()
                    
                    if let moodStr = entry.mood, let mood = CapchoMood.from(string: moodStr) {
                        MoodBadge(mood: mood, isCompact: true)
                    }
                    
                    if entry.isPinned {
                        Image(systemName: "pin.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(AppColors.darkRose)
                            .accessibilityLabel("Pinned entry")
                    }
                }
                
                // Content Body: Title, Snippet, Image Thumbnail
                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(entry.displayTitle)
                            .font(AppTypography.cardTitle)
                            .foregroundStyle(AppColors.primaryText(for: colorScheme))
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                        
                        Text(entry.snippet)
                            .font(AppTypography.cardSnippet)
                            .foregroundStyle(AppColors.secondaryText(for: colorScheme))
                            .lineLimit(3)
                            .lineSpacing(3)
                            .multilineTextAlignment(.leading)
                    }
                    
                    Spacer(minLength: 0)
                    
                    // Thumbnail if image attachment exists
                    if let filename = entry.imageFilename, !filename.isEmpty {
                        Group {
                            if let thumb = thumbnailImage {
                                Image(uiImage: thumb)
                                    .resizable()
                                    .scaledToFill()
                            } else {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(AppColors.badgeBackground(for: colorScheme))
                                    .overlay(
                                        Image(systemName: "photo")
                                            .font(.system(size: 16))
                                            .foregroundStyle(AppColors.secondaryText(for: colorScheme))
                                    )
                            }
                        }
                        .frame(width: 64, height: 64)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(AppColors.divider(for: colorScheme), lineWidth: 0.6)
                        )
                        .accessibilityLabel("Attached photo")
                        .task {
                            loadThumbnail(for: filename)
                        }
                    }
                }
            }
            .padding(.all, 16)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(entry.displayTitle), \(entry.formattedDate) at \(entry.formattedTime). \(entry.snippet)")
    }
    
    private func loadThumbnail(for filename: String) {
        if thumbnailImage == nil {
            thumbnailImage = ImageStorageService.shared.loadThumbnail(named: filename, targetSize: CGSize(width: 140, height: 140))
        }
    }
}
