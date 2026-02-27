import Foundation

final class QuoteRotator {
    private let stateProvider: () -> AppState
    private let stateConsumer: (AppState) -> Void
    private let nowProvider: () -> Date
    private var timer: Timer?

    init(
        stateProvider: @escaping () -> AppState,
        stateConsumer: @escaping (AppState) -> Void,
        nowProvider: @escaping () -> Date = Date.init
    ) {
        self.stateProvider = stateProvider
        self.stateConsumer = stateConsumer
        self.nowProvider = nowProvider
    }

    deinit {
        stop()
    }

    func start() {
        stop()
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            guard let self else { return }
            self.onTick(now: self.nowProvider())
        }
        if let timer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    func onTick(now: Date) {
        var state = stateProvider()
        let didChange = Self.applyRotationIfNeeded(state: &state, now: now)
        if didChange {
            stateConsumer(state)
        }
    }

    func forceNextQuote() {
        var state = stateProvider()
        let didChange = Self.forceNextQuote(state: &state, now: nowProvider())
        if didChange {
            stateConsumer(state)
        }
    }

    @discardableResult
    static func applyRotationIfNeeded(state: inout AppState, now: Date) -> Bool {
        let originalState = state
        state.normalize()

        guard !state.quotes.isEmpty else {
            return state != originalState
        }

        let intervalSeconds = TimeInterval(state.rotationIntervalSeconds)
        guard intervalSeconds > 0 else {
            return state != originalState
        }

        guard let lastRotationAt = state.lastRotationAt else {
            state.lastRotationAt = now
            return state != originalState
        }

        let elapsed = now.timeIntervalSince(lastRotationAt)
        guard elapsed >= intervalSeconds else {
            return state != originalState
        }

        let steps = max(Int(floor(elapsed / intervalSeconds)), 1)
        let quoteCount = state.quotes.count
        let currentIndex = state.currentIndex ?? 0

        state.currentIndex = (currentIndex + steps) % quoteCount
        state.lastRotationAt = lastRotationAt.addingTimeInterval(intervalSeconds * Double(steps))

        return state != originalState
    }

    @discardableResult
    static func forceNextQuote(state: inout AppState, now: Date) -> Bool {
        let originalState = state
        state.normalize()

        guard !state.quotes.isEmpty else {
            return state != originalState
        }

        let quoteCount = state.quotes.count
        let currentIndex = state.currentIndex ?? -1
        state.currentIndex = (currentIndex + 1) % quoteCount
        state.lastRotationAt = now

        return state != originalState
    }
}
