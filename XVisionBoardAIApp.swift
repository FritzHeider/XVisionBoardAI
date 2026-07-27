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
    @Environment(\.scenePhase) private var scenePhase
    @State private var storeManager = StoreManager()
    @State private var userManager = UserManager()
    @State private var visionBoardManager = VisionBoardManager()

    init() {
        // Configure RevenueCat before any Purchases.shared access.
        StoreManager.configure()
        loadRocketSimConnect()
    }

    private func loadRocketSimConnect() {
        #if DEBUG
        guard (Bundle(path: "/Applications/RocketSim.app/Contents/Frameworks/RocketSimConnectLinker.nocache.framework")?.load() == true) else {
            print("Failed to load linker framework")
            return
        }
        print("RocketSim Connect successfully linked")
        #endif
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
                // Initial load at cold launch.
                .task {
                    await storeManager.refreshCustomerInfo()
                    await storeManager.fetchCurrentOffering()
                }
                // Actually keep CustomerInfo fresh on foreground. A bare .task runs
                // once when the root view appears, so without this a renewal, refund,
                // or purchase made elsewhere never lands until the process restarts.
                .onChange(of: scenePhase) { _, newPhase in
                    guard newPhase == .active else { return }
                    Task { await storeManager.refreshCustomerInfo() }
                }
                // Register an App Attest key with the proxy (no-op unless the
                // proxy is configured and the device supports App Attest).
                .task {
                    await AppAttestManager.shared.prepare()
                }
        }
    }
}
