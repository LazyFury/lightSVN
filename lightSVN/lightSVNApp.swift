//
//  lightSVNApp.swift
//  lightSVN
//
//  Created by suke on 2024/7/15.
//

import SwiftUI

@main
struct lightSVNApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
