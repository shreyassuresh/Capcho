//
//  AppColors.swift
//  Capcho
//
//  Created by Capcho on 27/10/26.
//

import SwiftUI

enum AppColors {
    // MARK: - Core Brand Palette
    /// Primary Cotton Rose: #CEB5B7
    static let cottonRose = Color(hex: 0xCEB5B7)
    
    /// Dark Rose: #A8898C
    static let darkRose = Color(hex: 0xA8898C)
    
    /// Soft Blush: #E8D7D7
    static let softBlush = Color(hex: 0xE8D7D7)
    
    // MARK: - Light Mode Constants
    static let lightBackground = Color(hex: 0xF8F4F1)
    static let lightCardBackground = Color(hex: 0xFFFCFA)
    static let lightPrimaryText = Color(hex: 0x3D3436)
    static let lightSecondaryText = Color(hex: 0x85777A)
    static let lightDivider = Color(hex: 0xE8DEDB)
    
    // MARK: - Dark Mode Constants
    static let darkBackground = Color(hex: 0x181415)
    static let darkCardBackground = Color(hex: 0x241E20)
    static let darkPrimaryText = Color(hex: 0xF7F1F2)
    static let darkSecondaryText = Color(hex: 0xA89B9E)
    static let darkDivider = Color(hex: 0x382E30)
    static let darkSoftBlush = Color(hex: 0x3A2B2E)
    
    // MARK: - Semantic Dynamic Colors (Adapts to ColorScheme)
    
    /// Primary page background (warm paper tone)
    static func background(for scheme: ColorScheme) -> Color {
        scheme == .dark ? darkBackground : lightBackground
    }
    
    /// Card and surface background
    static func cardBackground(for scheme: ColorScheme) -> Color {
        scheme == .dark ? darkCardBackground : lightCardBackground
    }
    
    /// Primary high-contrast body text
    static func primaryText(for scheme: ColorScheme) -> Color {
        scheme == .dark ? darkPrimaryText : lightPrimaryText
    }
    
    /// Secondary subtitle/date text
    static func secondaryText(for scheme: ColorScheme) -> Color {
        scheme == .dark ? darkSecondaryText : lightSecondaryText
    }
    
    /// Subtle line divider
    static func divider(for scheme: ColorScheme) -> Color {
        scheme == .dark ? darkDivider : lightDivider
    }
    
    /// Soft pill background for badges and chips
    static func badgeBackground(for scheme: ColorScheme) -> Color {
        scheme == .dark ? darkSoftBlush : softBlush.opacity(0.4)
    }
    
    /// Input field / search bar background
    static func inputBackground(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(hex: 0x2C2326) : Color(hex: 0xF0E9E6)
    }
}

// MARK: - Color Hex Initializer
extension Color {
    init(hex: UInt, alpha: Double = 1.0) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0,
            opacity: alpha
        )
    }
    
    init?(hexString: String) {
        var cleanHex = hexString.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleanHex.hasPrefix("#") {
            cleanHex.removeFirst()
        }
        guard let hexVal = UInt(cleanHex, radix: 16) else { return nil }
        self.init(hex: hexVal)
    }
}
