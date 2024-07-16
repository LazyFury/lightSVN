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
                .frame(minWidth: 1080,minHeight: 540)
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
