//
//  XVisionBoardAIApp.swift
//  XVisionBoardAI
//
//  Created by AI Assistant
//  Copyright © 2025 XVisionBoard AI. All rights reserved.
//

import SwiftUI
import RevenueCat

@main
struct XVisionBoardAIApp: App {
    @State private var storeManager = StoreManager()
    @State private var userManager = UserManager()
    @State private var visionBoardManager = VisionBoardManager()

    init() {
        // Configure RevenueCat before any Purchases.shared access.
        StoreManager.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(storeManager)
                .environment(userManager)
                .environment(visionBoardManager)
                .onAppear {
                    #if DEBUG && targetEnvironment(simulator)
                    configureDebugEnvironment()
                    #endif
                }
                // Sync RevenueCat user identity whenever the logged-in user changes.
                .task(id: userManager.currentUser?.id) {
                    if let user = userManager.currentUser {
                        await storeManager.login(userID: user.id.uuidString)
                    }
                }
                // Keep CustomerInfo fresh after the app returns to foreground.
                .task {
                    await storeManager.refreshCustomerInfo()
                    await storeManager.fetchCurrentOffering()
                }
        }
    }
}
