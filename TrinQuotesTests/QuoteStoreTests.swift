import XCTest
@testable import TrinQuotes

final class QuoteStoreTests: XCTestCase {
    private var suiteName: String!
    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        suiteName = "TrinQuotesTests-\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
        defaults.removePersistentDomain(forName: suiteName)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        suiteName = nil
        super.tearDown()
    }

    func testRoundTripPersistence() {
        let store = UserDefaultsQuoteStore(defaults: defaults, key: "state")
        let timestamp = Date(timeIntervalSince1970: 123_456)
        let input = AppState(
            quotes: ["Quote A", "Quote B"],
            rotationHours: 12,
            currentIndex: 1,
            lastRotationAt: timestamp
        )

        store.save(input)
        let loaded = store.load()

        XCTAssertEqual(loaded, input)
    }

    func testLoadReturnsEmptyWhenNoStateExists() {
        let store = UserDefaultsQuoteStore(defaults: defaults, key: "missing")
        XCTAssertEqual(store.load(), .empty)
    }

    func testLoadNormalizesInvalidState() throws {
        let store = UserDefaultsQuoteStore(defaults: defaults, key: "state")

        let invalidState = AppState(
            quotes: ["Only quote"],
            rotationHours: 999,
            currentIndex: 25,
            lastRotationAt: Date(timeIntervalSince1970: 10)
        )

        let encoded = try JSONEncoder().encode(invalidState)
        defaults.set(encoded, forKey: "state")

        let loaded = store.load()

        XCTAssertEqual(loaded.rotationHours, AppState.maxRotationHours)
        XCTAssertEqual(loaded.currentIndex, 0)
    }
}
