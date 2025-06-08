//
//  BankAppApp.swift
//  BankApp
//
//  Created by Вадим Семибратов on 01.06.2025.
//

import SwiftUI
@main
struct BankAppApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext) // ✅
        }
    }
}
