//
//  AIConsentTests.swift
//  XVisionBoardAITests
//
//  Locks in the third-party AI consent gate.
//
//  Generating a board sends the user's selfie to fal.ai and their goal text to
//  Google Gemini. App Review Guideline 5.1.2(i) requires explicit permission
//  before personal data is shared with a third party, and a photo of someone's
//  face is the most personal payload this app has. The gate lives in
//  CreateVisionBoardView.generateVisionBoard(), which cannot be unit-tested
//  without UI automation — so these tests pin the state it reads instead.
//
//  The failure this guards against is quiet and expensive: someone defaults
//  `hasConsentedToAIProcessing` to true (or "helpfully" sets it during sign-up)
//  to skip a sheet during development, the gate silently stops firing, and the
//  app ships uploading faces with no disclosure.
//
//  ⚠️ These tests mutate the real UserDefaults suite, so they save and restore
//  the consent key around each case.
//

import Foundation
import Testing
@testable import XVisionBoardAI

@Suite("Third-party AI processing requires explicit consent")
@MainActor
struct AIConsentTests {

    /// Runs `body` with the consent flag reset, restoring whatever the
    /// simulator's defaults held before. UserManager reads and writes
    /// UserDefaults.standard directly, so there is no injection seam here.
    private func withCleanConsentState(_ body: () async -> Void) async {
        let key = UserManager.aiConsentKey
        let previous = UserDefaults.standard.object(forKey: key)
        UserDefaults.standard.removeObject(forKey: key)

        await body()

        if let previous {
            UserDefaults.standard.set(previous, forKey: key)
        } else {
            UserDefaults.standard.removeObject(forKey: key)
        }
    }

    @Test("Consent is denied by default on a fresh install")
    func consentDefaultsToDenied() async {
        await withCleanConsentState {
            let userManager = UserManager(tokenStore: InMemoryTokenStore())

            #expect(
                userManager.hasConsentedToAIProcessing == false,
                "a fresh install must not assume consent — this is the gate that keeps the selfie on-device"
            )
        }
    }

    @Test("Granted consent persists so the user is asked once, not every run")
    func consentPersists() async {
        await withCleanConsentState {
            let first = UserManager(tokenStore: InMemoryTokenStore())
            first.hasConsentedToAIProcessing = true

            // A second instance models the next app launch.
            let relaunched = UserManager(tokenStore: InMemoryTokenStore())

            #expect(
                relaunched.hasConsentedToAIProcessing,
                "consent must survive relaunch or the sheet becomes a per-generation nag"
            )
        }
    }

    @Test("Signing up does not grant consent on the user's behalf")
    func signUpDoesNotGrantConsent() async {
        await withCleanConsentState {
            let userManager = UserManager(tokenStore: InMemoryTokenStore())

            let created = await userManager.signUp(
                email: "consent-test@example.com",
                username: "ConsentTester",
                password: "secret123"
            )

            #expect(created)
            #expect(
                userManager.hasConsentedToAIProcessing == false,
                "agreeing to the Terms checkbox is not consent to third-party AI processing; they are separate disclosures"
            )
        }
    }

    @Test("Deleting the account withdraws consent")
    func deleteAccountWithdrawsConsent() async {
        await withCleanConsentState {
            let userManager = UserManager(tokenStore: InMemoryTokenStore())
            let boardManager = VisionBoardManager()
            userManager.hasConsentedToAIProcessing = true

            _ = await userManager.deleteAccount(boardManager: boardManager)

            #expect(
                userManager.hasConsentedToAIProcessing == false,
                "the next person to use this device must be asked again rather than inheriting consent"
            )
        }
    }
}
