import XCTest
@testable import TrinQuotes

final class QuoteRotatorTests: XCTestCase {
    func testEmptyListRemainsSafe() {
        var state = AppState.empty

        let changed = QuoteRotator.applyRotationIfNeeded(
            state: &state,
            now: Date(timeIntervalSince1970: 100)
        )

        XCTAssertFalse(changed)
        XCTAssertNil(state.currentIndex)
        XCTAssertNil(state.lastRotationAt)
    }

    func testSequentialWrapRotation() {
        var state = AppState(
            quotes: ["A", "B", "C"],
            rotationHours: 1,
            currentIndex: 2,
            lastRotationAt: Date(timeIntervalSince1970: 0)
        )

        let changed = QuoteRotator.applyRotationIfNeeded(
            state: &state,
            now: Date(timeIntervalSince1970: 3600)
        )

        XCTAssertTrue(changed)
        XCTAssertEqual(state.currentIndex, 0)
        XCTAssertEqual(state.lastRotationAt, Date(timeIntervalSince1970: 3600))
    }

    func testMultiStepCatchUp() {
        var state = AppState(
            quotes: ["A", "B", "C", "D"],
            rotationHours: 1,
            currentIndex: 0,
            lastRotationAt: Date(timeIntervalSince1970: 0)
        )

        let changed = QuoteRotator.applyRotationIfNeeded(
            state: &state,
            now: Date(timeIntervalSince1970: 3 * 3600 + 120)
        )

        XCTAssertTrue(changed)
        XCTAssertEqual(state.currentIndex, 3)
        XCTAssertEqual(state.lastRotationAt, Date(timeIntervalSince1970: 3 * 3600))
    }

    func testRotationHoursAreClampedByNormalization() {
        var state = AppState(
            quotes: ["A"],
            rotationHours: 0,
            currentIndex: 0,
            lastRotationAt: Date(timeIntervalSince1970: 0)
        )

        _ = QuoteRotator.applyRotationIfNeeded(
            state: &state,
            now: Date(timeIntervalSince1970: 0)
        )

        XCTAssertEqual(state.rotationHours, AppState.minRotationHours)
    }

    func testForceNextQuoteAdvancesAndSetsTimestamp() {
        var state = AppState(
            quotes: ["A", "B", "C"],
            rotationHours: 6,
            currentIndex: 1,
            lastRotationAt: Date(timeIntervalSince1970: 0)
        )

        let now = Date(timeIntervalSince1970: 555)
        let changed = QuoteRotator.forceNextQuote(state: &state, now: now)

        XCTAssertTrue(changed)
        XCTAssertEqual(state.currentIndex, 2)
        XCTAssertEqual(state.lastRotationAt, now)
    }

    func testLaunchStateUsesRandomIndexAndKeepsWithinBounds() {
        let stored = AppState(
            quotes: ["A", "B", "C"],
            rotationHours: 6,
            currentIndex: nil,
            lastRotationAt: nil
        )
        let now = Date(timeIntervalSince1970: 42)

        let launchState = AppState.launchState(
            from: stored,
            now: now,
            randomIndexProvider: { _ in 8 }
        )

        XCTAssertEqual(launchState.currentIndex, 2)
        XCTAssertEqual(launchState.lastRotationAt, now)
    }
}
