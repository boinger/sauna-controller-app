//
//  SaunaControllerApp.swift
//  SaunaController
//
//  Created by Jeff Vier on 1/14/26.
//

import SwiftUI
import SwiftData

@main
struct SaunaControllerApp: App {
    @StateObject private var saunaManager = SaunaManager()

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            SaunaSession.self
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
                .environmentObject(saunaManager)
        }
        .modelContainer(sharedModelContainer)
    }
}
