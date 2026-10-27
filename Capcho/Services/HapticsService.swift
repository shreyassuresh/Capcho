//
//  HapticsService.swift
//  Capcho
//
//  Created by Capcho on 27/10/26.
//

import UIKit

final class HapticsService {
    static let shared = HapticsService()
    
    private init() {}
    
    private var isEnabled: Bool {
        // Defaults to true unless explicitly disabled
        UserDefaults.standard.object(forKey: "hapticsEnabled") as? Bool ?? true
    }
    
    func light() {
        guard isEnabled else { return }
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred()
    }
    
    func medium() {
        guard isEnabled else { return }
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
    }
    
    func soft() {
        guard isEnabled else { return }
        let generator = UIImpactFeedbackGenerator(style: .soft)
        generator.prepare()
        generator.impactOccurred()
    }
    
    func success() {
        guard isEnabled else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.success)
    }
    
    func warning() {
        guard isEnabled else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.warning)
    }
    
    func selection() {
        guard isEnabled else { return }
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        generator.selectionChanged()
    }
}
