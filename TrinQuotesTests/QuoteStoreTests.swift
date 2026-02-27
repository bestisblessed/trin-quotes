import XCTest
import AppKit
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
            rotationMinutes: 45,
            menuBarStyle: MenuBarStyle(
                fontPreset: .monospaced,
                textSizePreset: .large,
                colorPreset: .blue,
                isBold: true
            ),
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
            rotationMinutes: 999,
            menuBarStyle: MenuBarStyle(
                fontPreset: .rounded,
                textSizePreset: .small,
                colorPreset: .green
            ),
            currentIndex: 25,
            lastRotationAt: Date(timeIntervalSince1970: 10)
        )

        let encoded = try JSONEncoder().encode(invalidState)
        defaults.set(encoded, forKey: "state")

        let loaded = store.load()

        XCTAssertEqual(loaded.rotationHours, AppState.maxRotationHours)
        XCTAssertEqual(loaded.rotationMinutes, AppState.maxRotationMinutes)
        XCTAssertEqual(loaded.currentIndex, 0)
        XCTAssertEqual(loaded.menuBarStyle.colorPreset, .green)
        XCTAssertFalse(loaded.menuBarStyle.isBold)
    }

    func testLoadBackwardCompatibleStateWithoutMinutes() throws {
        let store = UserDefaultsQuoteStore(defaults: defaults, key: "state")

        let legacyPayload: [String: Any] = [
            "quotes": ["Legacy quote"],
            "rotationHours": 2,
            "currentIndex": 0,
            "lastRotationAt": Date(timeIntervalSince1970: 10).timeIntervalSince1970
        ]
        let data = try JSONSerialization.data(withJSONObject: legacyPayload)
        defaults.set(data, forKey: "state")

        let loaded = store.load()
        XCTAssertEqual(loaded.rotationHours, 2)
        XCTAssertEqual(loaded.rotationMinutes, AppState.defaultRotationMinutes)
        XCTAssertEqual(loaded.menuBarStyle, .default)
    }

    func testMenuBarFontPresetMappingResolvesFonts() {
        for preset in MenuBarFontPreset.allCases {
            let style = MenuBarStyle(
                fontPreset: preset,
                textSizePreset: .regular,
                colorPreset: .label
            )
            let font = StatusBarController.font(for: style)

            XCTAssertGreaterThan(font.pointSize, 0)
        }
    }

    func testMenuBarColorPresetMappingResolvesExpectedColors() {
        let expected: [MenuBarColorPreset: NSColor] = [
            .label: .labelColor,
            .red: .systemRed,
            .orange: .systemOrange,
            .green: .systemGreen,
            .blue: .systemBlue,
            .pink: .systemPink,
            .yellow: .systemYellow,
            .purple: .systemPurple,
            .indigo: .systemIndigo,
            .teal: .systemTeal,
            .cyan: .systemCyan,
            .brown: .systemBrown,
            .gray: .systemGray,
            .black: .black
        ]

        for preset in MenuBarColorPreset.allCases {
            let style = MenuBarStyle(
                fontPreset: .system,
                textSizePreset: .regular,
                colorPreset: preset
            )
            let mapped = StatusBarController.color(for: style)
            let target = expected[preset] ?? .labelColor

            XCTAssertTrue(mapped.isEqual(target))
        }
    }
}
