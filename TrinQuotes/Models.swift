import Foundation

struct AppState: Codable, Equatable {
    static let defaultRotationHours = 6
    static let minRotationHours = 1
    static let maxRotationHours = 168

    var quotes: [String]
    var rotationHours: Int
    var currentIndex: Int?
    var lastRotationAt: Date?

    static var empty: AppState {
        AppState(
            quotes: [],
            rotationHours: defaultRotationHours,
            currentIndex: nil,
            lastRotationAt: nil
        )
    }

    var currentQuote: String? {
        guard let currentIndex, quotes.indices.contains(currentIndex) else {
            return nil
        }
        return quotes[currentIndex]
    }

    mutating func normalize() {
        rotationHours = Self.clampedRotationHours(rotationHours)

        guard !quotes.isEmpty else {
            currentIndex = nil
            lastRotationAt = nil
            return
        }

        if let currentIndex {
            self.currentIndex = Self.wrappedIndex(currentIndex, count: quotes.count)
        } else {
            currentIndex = 0
        }
    }

    func normalized() -> AppState {
        var state = self
        state.normalize()
        return state
    }

    static func launchState(
        from storedState: AppState,
        now: Date,
        randomIndexProvider: (Int) -> Int = { Int.random(in: 0..<$0) }
    ) -> AppState {
        var state = storedState.normalized()

        guard !state.quotes.isEmpty else {
            state.currentIndex = nil
            state.lastRotationAt = nil
            return state
        }

        let rawIndex = randomIndexProvider(state.quotes.count)
        state.currentIndex = wrappedIndex(rawIndex, count: state.quotes.count)
        state.lastRotationAt = now
        return state
    }

    static func clampedRotationHours(_ hours: Int) -> Int {
        min(max(hours, minRotationHours), maxRotationHours)
    }

    private static func wrappedIndex(_ index: Int, count: Int) -> Int {
        guard count > 0 else { return 0 }
        let remainder = index % count
        return remainder >= 0 ? remainder : remainder + count
    }
}
