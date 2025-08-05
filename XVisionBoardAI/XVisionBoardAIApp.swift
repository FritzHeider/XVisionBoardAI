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
    @StateObject private var storeManager = StoreManager()
    @StateObject private var userManager = UserManager()
    @StateObject private var visionBoardManager = VisionBoardManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(storeManager)
                .environmentObject(userManager)
                .environmentObject(visionBoardManager)
                .onAppear {
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

