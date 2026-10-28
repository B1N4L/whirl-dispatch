//
//  whirl_dispatch_appApp.swift
//  whirl-dispatch-app
//
//  Created by Binal on 2026-10-04.
//

import SwiftUI
import CoreData

@main
struct whirl_dispatch_appApp: App {
    let persistenceController = PersistenceController.shared

    init() {
        _ = NotificationService.shared
        _ = LocationManager.shared
        Task { @MainActor in
            _ = await NotificationService.shared.requestAuthorization()
            LocationManager.shared.requestAuthorization()
        }
    }

    var body: some Scene {
        WindowGroup {
            RootCoordinatorView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
