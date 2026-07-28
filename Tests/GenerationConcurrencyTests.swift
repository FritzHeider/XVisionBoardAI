//
//  GenerationConcurrencyTests.swift
//  XVisionBoardAITests
//
//  Locks in the generation-serialisation fix.
//
//  isGenerating / generationProgress / currentGeneratingBoard are manager-level
//  properties, not scoped per attempt. A swipe-dismissed run keeps executing, so
//  starting a second one had both tasks writing the same three properties: the
//  progress bar and preview grid flickered between runs, and one task finishing
//  could flip isGenerating to false while the other was still in flight.
//
//  createVisionBoard now rejects a concurrent call. These tests assert it bails
//  out immediately and does no work, so they never touch the network.
//

import Testing
import UIKit
@testable import XVisionBoardAI

/// Time-limited on purpose. When the guard is present each test returns in
/// milliseconds because `createVisionBoard` bails out before doing any work.
/// If the guard is ever removed these tests would instead run a *real*
/// generation — minutes of fal.ai calls, billed, per test. The limit caps that.
@Suite("Vision board generation is serialised", .timeLimit(.minutes(1)))
@MainActor
struct GenerationConcurrencyTests {

    private func makeImage() -> UIImage {
        UIGraphicsImageRenderer(size: CGSize(width: 4, height: 4)).image { context in
            UIColor.gray.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 4, height: 4))
        }
    }

    private func startGeneration(on manager: VisionBoardManager) async -> VisionBoard? {
        await manager.createVisionBoard(
            title: "Second board",
            description: "Started while another run is in flight",
            userImage: makeImage(),
            layout: .grid3x3,
            style: .cinematic,
            manifestationGoals: ["Ship the app"]
        )
    }

    @Test("A concurrent call is rejected instead of corrupting shared state")
    func concurrentCallIsRejected() async {
        let manager = VisionBoardManager()
        let boardsBefore = manager.visionBoards.count

        // Simulate a generation already in flight (e.g. one the user swipe-dismissed).
        manager.isGenerating = true

        let result = await startGeneration(on: manager)

        #expect(result == nil, "a second concurrent generation must not start")
        #expect(
            manager.visionBoards.count == boardsBefore,
            "a rejected generation must not append a board"
        )
    }

    @Test("Rejection explains itself to the user")
    func rejectionSetsErrorMessage() async {
        let manager = VisionBoardManager()
        manager.isGenerating = true

        _ = await startGeneration(on: manager)

        // CreateVisionBoardView surfaces errorMessage in its "Generation Failed"
        // alert, so a silent nil would leave the user staring at a dead button.
        #expect(manager.errorMessage != nil, "rejection must surface a reason")
    }

    @Test("Rejection leaves the in-flight run's state untouched")
    func rejectionDoesNotDisturbInFlightState() async {
        let manager = VisionBoardManager()
        manager.isGenerating = true
        manager.generationProgress = 0.6

        _ = await startGeneration(on: manager)

        // The whole point: the rejected call must not reset progress or clear the
        // flag out from under the run that is actually still going.
        #expect(manager.isGenerating, "in-flight generation must stay marked as running")
        #expect(manager.generationProgress == 0.6, "in-flight progress must not be reset")
    }
}
