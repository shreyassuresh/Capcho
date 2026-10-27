//
//  ContentView.swift
//  Capcho
//
//  Created by Capcho on 27/10/26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @AppStorage("appAppearance") private var appAppearance: String = "system"
    @State private var selectedTab: Int = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            JournalHomeView()
                .tabItem {
                    Label("Journal", systemImage: "book.pages")
                }
                .tag(0)
            
            NotesHomeView()
                .tabItem {
                    Label("Notes", systemImage: "note.text")
                }
                .tag(1)
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
                .tag(2)
        }
        .tint(AppColors.darkRose)
        .preferredColorScheme(AppConfiguration.colorScheme(for: appAppearance))
        .onChange(of: selectedTab) { _, _ in
            HapticsService.shared.selection()
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(PersistenceController.preview.container)
}
