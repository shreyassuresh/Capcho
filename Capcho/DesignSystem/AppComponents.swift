//
//  AppComponents.swift
//  Capcho
//
//  Created by Capcho on 27/10/26.
//

import SwiftUI

// MARK: - Card Surface
struct CapchoCard<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .background(AppColors.cardBackground(for: colorScheme))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(AppColors.divider(for: colorScheme).opacity(0.7), lineWidth: 0.8)
            )
            .shadow(color: colorScheme == .dark ? Color.black.opacity(0.2) : AppColors.cottonRose.opacity(0.12), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Primary Button Style
struct CapchoPrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.body, design: .serif, weight: .medium))
            .foregroundStyle(Color(hex: 0x3D3436))
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(AppColors.cottonRose.opacity(isEnabled ? (configuration.isPressed ? 0.75 : 1.0) : 0.4))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(AppColors.darkRose.opacity(0.25), lineWidth: 0.5)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Secondary Button Style
struct CapchoSecondaryButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) private var colorScheme
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.callout, design: .default, weight: .medium))
            .foregroundStyle(AppColors.primaryText(for: colorScheme))
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(AppColors.badgeBackground(for: colorScheme))
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Mood Badge
struct MoodBadge: View {
    @Environment(\.colorScheme) private var colorScheme
    let mood: CapchoMood
    var isCompact: Bool = false
    
    var body: some View {
        HStack(spacing: 5) {
            Text(mood.emoji)
                .font(.system(size: isCompact ? 11 : 13))
            
            if !isCompact {
                Text(mood.displayName)
                    .font(.system(size: 12, weight: .medium, design: .default))
                    .foregroundStyle(AppColors.primaryText(for: colorScheme))
            }
        }
        .padding(.horizontal, isCompact ? 6 : 10)
        .padding(.vertical, isCompact ? 3 : 5)
        .background(
            Capsule()
                .fill(AppColors.badgeBackground(for: colorScheme))
        )
        .overlay(
            Capsule()
                .stroke(AppColors.cottonRose.opacity(0.35), lineWidth: 0.6)
        )
        .accessibilityLabel("Mood: \(mood.displayName)")
    }
}

// MARK: - Pin Badge
struct PinnedBadge: View {
    var body: some View {
        Image(systemName: "pin.fill")
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(AppColors.darkRose)
            .padding(6)
            .background(
                Circle()
                    .fill(AppColors.softBlush.opacity(0.6))
            )
            .accessibilityLabel("Pinned item")
    }
}

// MARK: - Save Status Indicator
struct CapchoSaveIndicator: View {
    enum Status: Equatable {
        case idle
        case saving
        case saved
    }
    
    let status: Status
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(spacing: 6) {
            switch status {
            case .idle:
                EmptyView()
            case .saving:
                ProgressView()
                    .scaleEffect(0.65)
                    .tint(AppColors.darkRose)
                Text("Saving…")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(AppColors.secondaryText(for: colorScheme))
            case .saved:
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(AppColors.darkRose)
                Text("Saved")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(AppColors.secondaryText(for: colorScheme))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: status)
    }
}

// MARK: - Empty State View
struct CapchoEmptyState: View {
    let title: String
    let subtitle: String
    let iconName: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(AppColors.badgeBackground(for: colorScheme))
                    .frame(width: 80, height: 80)
                
                Image(systemName: iconName)
                    .font(.system(size: 32, weight: .light))
                    .foregroundStyle(AppColors.darkRose)
            }
            .padding(.bottom, 6)
            
            Text(title)
                .font(AppTypography.emptyTitle)
                .foregroundStyle(AppColors.primaryText(for: colorScheme))
                .multilineTextAlignment(.center)
            
            Text(subtitle)
                .font(AppTypography.emptySubtitle)
                .foregroundStyle(AppColors.secondaryText(for: colorScheme))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .lineSpacing(3)
            
            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    HStack(spacing: 8) {
                        Image(systemName: "square.and.pencil")
                        Text(actionTitle)
                    }
                }
                .buttonStyle(CapchoPrimaryButtonStyle())
                .padding(.top, 12)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
    }
}
