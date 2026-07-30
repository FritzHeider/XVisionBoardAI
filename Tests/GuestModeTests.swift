//
//  GuestModeTests.swift
//  XVisionBoardAITests
//
//  Locks in the guest path added for App Store Guideline 5.1.1(ii): the app must
//  be usable without handing over an email, because nothing here needs an
//  account (boards are device-local, and subscriptions bill the Apple Account).
//
//  The subtle one is `guestSessionSurvivesRelaunch`. `loadUserData()` requires
//  BOTH a stored token and a Keychain user, and resets to the auth wall if
//  either is missing. `continueAsGuest()` therefore has to save a token even
//  though a guest has nothing to authenticate. Drop that line and the bug is
//  invisible in a single session — guests only get kicked back to the welcome
//  screen on the *next* launch, which is exactly the kind of thing that ships.
//
//  ⚠️ These tests mutate the real UserDefaults suite and the Keychain, and the
//  deletion case wipes Documents/VisionBoards. Fine on a simulator; do not run
//  against a device holding real user data.
//

import Foundation
import Testing
@testable import XVisionBoardAI

@Suite("The app is usable without an account")
@MainActor
struct GuestModeTests {

    /// Clears the guest flag around each case and restores whatever was there.
    /// UserManager reads and writes UserDefaults.standard directly, so there is
    /// no injection seam.
    private func withCleanGuestState(_ body: () async -> Void) async {
        let key = UserManager.guestKey
        let previous = UserDefaults.standard.object(forKey: key)
        UserDefaults.standard.removeObject(forKey: key)

        await body()

        if let previous {
            UserDefaults.standard.set(previous, forKey: key)
        } else {
            UserDefaults.standard.removeObject(forKey: key)
        }
    }

    @Test("continueAsGuest lets the user in without credentials")
    func continueAsGuestSignsIn() async {
        await withCleanGuestState {
            let userManager = UserManager(tokenStore: InMemoryTokenStore())

            userManager.continueAsGuest()

            #expect(userManager.isLoggedIn, "the guest must clear ContentView's isLoggedIn gate")
            #expect(userManager.isGuest)
            #expect(userManager.currentUser != nil, "downstream views read currentUser for the profile header")
        }
    }

    @Test("A guest session survives relaunch")
    func guestSessionSurvivesRelaunch() async {
        await withCleanGuestState {
            // One shared store models the same device across two launches.
            let tokenStore = InMemoryTokenStore()

            let firstLaunch = UserManager(tokenStore: tokenStore)
            firstLaunch.continueAsGuest()
            #expect(firstLaunch.isLoggedIn)

            let secondLaunch = UserManager(tokenStore: tokenStore)

            #expect(
                secondLaunch.isLoggedIn,
                "loadUserData() treats a missing token as a dead session; a guest without one is silently signed out on next launch"
            )
            #expect(secondLaunch.isGuest, "the guest flag must persist too, or Profile shows a blank email line")
        }
    }

    @Test("Signing up converts a guest into a real account")
    func signUpConvertsGuest() async {
        await withCleanGuestState {
            let userManager = UserManager(tokenStore: InMemoryTokenStore())
            userManager.continueAsGuest()

            let created = await userManager.signUp(
                email: "converted@example.com",
                username: "Converted",
                password: "secret123"
            )

            #expect(created)
            #expect(userManager.isGuest == false, "a converted guest is no longer a guest")
            #expect(userManager.currentUser?.email == "converted@example.com")
        }
    }

    @Test("Signing in clears the guest flag")
    func signInClearsGuestFlag() async {
        await withCleanGuestState {
            let userManager = UserManager(tokenStore: InMemoryTokenStore())
            userManager.continueAsGuest()

            _ = await userManager.signIn(email: "returning@example.com", password: "secret123")

            #expect(userManager.isGuest == false)
        }
    }

    @Test("Signing out clears the guest flag")
    func signOutClearsGuestFlag() async {
        await withCleanGuestState {
            let userManager = UserManager(tokenStore: InMemoryTokenStore())
            userManager.continueAsGuest()

            userManager.signOut()

            #expect(userManager.isGuest == false, "a stale guest flag would mislabel the next real account's profile")
            #expect(!userManager.isLoggedIn)
        }
    }

    @Test("A guest can still delete everything")
    func guestCanDeleteAllData() async {
        await withCleanGuestState {
            let userManager = UserManager(tokenStore: InMemoryTokenStore())
            let boardManager = VisionBoardManager()
            userManager.continueAsGuest()
            boardManager.visionBoards.append(
                VisionBoard(
                    title: "Seeded by GuestModeTests",
                    description: "seeded",
                    userImageFilename: "test-\(UUID().uuidString).jpg",
                    layout: .grid3x3,
                    style: .cinematic
                )
            )

            let succeeded = await userManager.deleteAccount(boardManager: boardManager)

            #expect(succeeded)
            #expect(boardManager.visionBoards.isEmpty, "\"Delete All My Data\" must honour its own copy for guests too")
            #expect(!userManager.isLoggedIn)
            #expect(userManager.isGuest == false)
        }
    }
}
