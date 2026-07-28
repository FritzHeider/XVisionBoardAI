//
//  ReminderScheduleTests.swift
//  XVisionBoardAITests
//
//  Locks in the daily-reminder fix. The feature was implemented twice and never
//  connected: ProfileView wrote "reminderTime" to UserDefaults while
//  VisionBoardDetailView scheduled a hardcoded 08:00 and never read the key, so
//  picking a time in Settings silently did nothing.
//
//  UserManager is now the single source of truth. These tests assert the picked
//  time actually reaches the notification trigger.
//

import Testing
import Foundation
@testable import XVisionBoardAI

@Suite("Daily reminder time is honoured")
@MainActor
struct ReminderScheduleTests {

    private func makeTime(hour: Int, minute: Int) -> Date {
        Calendar.current.date(from: DateComponents(hour: hour, minute: minute))!
    }

    @Test("reminderComponents reflects the chosen time, not a hardcoded 08:00")
    func componentsFollowChosenTime() {
        let manager = UserManager(tokenStore: InMemoryTokenStore())
        manager.reminderTime = makeTime(hour: 21, minute: 30)

        let components = manager.reminderComponents
        #expect(components.hour == 21, "scheduler must use the picked hour")
        #expect(components.minute == 30, "scheduler must use the picked minute")
    }

    @Test("Default reminder time is 08:00", arguments: [0])
    func defaultIsEightAM(_: Int) {
        let components = Calendar.current.dateComponents(
            [.hour, .minute],
            from: UserManager.defaultReminderTime
        )
        #expect(components.hour == 8)
        #expect(components.minute == 0)
    }

    @Test(
        "Components round-trip for times across the day",
        arguments: [(0, 0), (6, 15), (12, 45), (18, 5), (23, 59)]
    )
    func componentsRoundTrip(hour: Int, minute: Int) {
        let manager = UserManager(tokenStore: InMemoryTokenStore())
        manager.reminderTime = makeTime(hour: hour, minute: minute)

        #expect(manager.reminderComponents.hour == hour)
        #expect(manager.reminderComponents.minute == minute)
    }

    @Test("Formatted time is non-empty so the confirmation message reads correctly")
    func formattedTimeIsPresentable() {
        let manager = UserManager(tokenStore: InMemoryTokenStore())
        manager.reminderTime = makeTime(hour: 21, minute: 30)

        // The confirmation copy interpolates this; an empty string would ship
        // "You'll get a nudge every day at ." to the user.
        #expect(!manager.formattedReminderTime.isEmpty)
    }
}
