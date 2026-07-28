//
//  AccountDeletionTests.swift
//  XVisionBoardAITests
//
//  Locks in the account-deletion fix. The Delete Account alert promises "This will
//  permanently delete your account and all vision boards", but deleteAccount() only
//  cleared the Keychain. Boards live in a single device-wide Documents/VisionBoards
//  directory that is not namespaced per account, so a user who deleted their account
//  and made a new one on the same device saw all their "deleted" boards reappear.
//
//  That is a broken data-deletion promise and an App Store Guideline 5.1.1(v) risk,
//  which is why it is worth a test rather than a screenshot.
//
//  ⚠️ These tests are DESTRUCTIVE by nature: they exercise a wipe of
//  Documents/VisionBoards. That is fine on a simulator. Do not run this suite
//  against a device holding real user data.
//

import Testing
import UIKit
@testable import XVisionBoardAI

@Suite("Deleting an account removes the boards it promised to remove")
@MainActor
struct AccountDeletionTests {

    private func makeBoard(title: String) -> VisionBoard {
        VisionBoard(
            title: title,
            description: "seeded by AccountDeletionTests",
            userImageFilename: "test-\(UUID().uuidString).jpg",
            layout: .grid3x3,
            style: .cinematic
        )
    }

    /// Seeds boards straight into the manager's in-memory array and persists them,
    /// avoiding createVisionBoard (which would hit the network).
    private func seedBoards(on manager: VisionBoardManager, count: Int) {
        for i in 0..<count {
            manager.visionBoards.append(makeBoard(title: "Seeded board \(i)"))
        }
    }

    @Test("deleteAllVisionBoards empties the collection")
    func deleteAllEmptiesCollection() {
        let manager = VisionBoardManager()
        seedBoards(on: manager, count: 3)
        #expect(manager.visionBoards.count >= 3)

        manager.deleteAllVisionBoards()

        #expect(manager.visionBoards.isEmpty, "no board may survive an account deletion")
    }

    @Test("deleteAllVisionBoards is idempotent")
    func deleteAllIsIdempotent() {
        let manager = VisionBoardManager()
        seedBoards(on: manager, count: 2)

        manager.deleteAllVisionBoards()
        manager.deleteAllVisionBoards()  // must not trap on an already-removed directory

        #expect(manager.visionBoards.isEmpty)
    }

    @Test("Deleted boards do not reappear for the next account on the device")
    func deletedBoardsDoNotReappear() {
        let manager = VisionBoardManager()
        seedBoards(on: manager, count: 3)
        manager.deleteAllVisionBoards()

        // A fresh manager models the next account signing in on the same device:
        // its init() loads from Documents/VisionBoards. This is the exact bug —
        // boards used to survive the wipe and show up under the new account.
        let nextAccountManager = VisionBoardManager()

        #expect(
            nextAccountManager.visionBoards.isEmpty,
            "boards from a deleted account must not load for the next account"
        )
    }

    @Test("deleteAccount wipes boards and signs the user out")
    func deleteAccountWipesBoardsAndSignsOut() async {
        let userManager = UserManager(tokenStore: InMemoryTokenStore())
        let boardManager = VisionBoardManager()
        seedBoards(on: boardManager, count: 2)

        let succeeded = await userManager.deleteAccount(boardManager: boardManager)

        #expect(succeeded)
        #expect(boardManager.visionBoards.isEmpty, "deleteAccount must honour its own alert copy")
        #expect(!userManager.isLoggedIn, "deleteAccount must sign the user out")
        #expect(userManager.currentUser == nil, "deleteAccount must clear the profile")
    }
}
