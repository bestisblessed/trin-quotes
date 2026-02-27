import Foundation

protocol QuoteStore {
    func load() -> AppState
    func save(_ state: AppState)
}

final class UserDefaultsQuoteStore: QuoteStore {
    private let defaults: UserDefaults
    private let storageKey: String

    init(
        defaults: UserDefaults = .standard,
        key: String = "trin_quotes_app_state_v1"
    ) {
        self.defaults = defaults
        self.storageKey = key
    }

    func load() -> AppState {
        guard let data = defaults.data(forKey: storageKey) else {
            return .empty
        }

        do {
            let decodedState = try JSONDecoder().decode(AppState.self, from: data)
            return decodedState.normalized()
        } catch {
            return .empty
        }
    }

    func save(_ state: AppState) {
        do {
            let normalizedState = state.normalized()
            let data = try JSONEncoder().encode(normalizedState)
            defaults.set(data, forKey: storageKey)
        } catch {
            defaults.removeObject(forKey: storageKey)
        }
    }
}
