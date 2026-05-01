//
//  XVisionBoardAIApp.swift
//  XVisionBoardAI
//
//  Created by AI Assistant
//  Copyright © 2025 XVisionBoard AI. All rights reserved.
//

import SwiftUI
import StoreKit

@main
struct XVisionBoardAIApp: App {
    @State private var storeManager = StoreManager()
    @State private var userManager = UserManager()
    @State private var visionBoardManager = VisionBoardManager()
    
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
                    // Initialize app services
                    Task {
                        await storeManager.loadProducts()
                    }
                }
                .task {
                    // Handle App Store transactions
                    for await result in Transaction.updates {
                        if case .verified(let transaction) = result {
                            await storeManager.updatePurchasedProducts()
                            await transaction.finish()
                        }
                    }
                }
        }
    }
}

