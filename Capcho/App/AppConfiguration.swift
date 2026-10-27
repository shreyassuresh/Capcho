//
//  AppConfiguration.swift
//  Capcho
//
//  Created by Capcho on 27/10/26.
//

import SwiftUI

enum AppConfiguration {
    static let appName = "Capcho"
    static let versionString = "1.0"
    static let buildNumber = "1"
    
    /// Converts stored appearance preference string to SwiftUI ColorScheme?
    static func colorScheme(for preference: String) -> ColorScheme? {
        switch preference {
        case "light":
            return .light
        case "dark":
            return .dark
        default:
            return nil // Follows system
        }
    }
}
