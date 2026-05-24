//
//  ForkitApp.swift
//  Forkit
//
//  Created by VERDVANA on 2026/5/24.
//

import SwiftUI
import SwiftData

@main
struct ForkitApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Dish.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
