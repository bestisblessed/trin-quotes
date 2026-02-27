import Foundation

enum MenuBarFontPreset: String, Codable, CaseIterable {
    case system
    case rounded
    case monospaced
    case serif

    var displayName: String {
        switch self {
        case .system:
            return "System"
        case .rounded:
            return "Rounded"
        case .monospaced:
            return "Monospaced"
        case .serif:
            return "Serif"
        }
    }
}

enum MenuBarTextSizePreset: Int, Codable, CaseIterable {
    case small = 12
    case regular = 13
    case large = 15

    var displayName: String {
        switch self {
        case .small:
            return "Small"
        case .regular:
            return "Regular"
        case .large:
            return "Large"
        }
    }
}

enum MenuBarColorPreset: String, Codable, CaseIterable {
    case label
    case red
    case orange
    case green
    case blue
    case pink
    case yellow
    case purple
    case indigo
    case teal
    case cyan
    case brown
    case gray
    case black

    var displayName: String {
        switch self {
        case .label:
            return "Label"
        case .red:
            return "Red"
        case .orange:
            return "Orange"
        case .green:
            return "Green"
        case .blue:
            return "Blue"
        case .pink:
            return "Pink"
        case .yellow:
            return "Yellow"
        case .purple:
            return "Purple"
        case .indigo:
            return "Indigo"
        case .teal:
            return "Teal"
        case .cyan:
            return "Cyan"
        case .brown:
            return "Brown"
        case .gray:
            return "Gray"
        case .black:
            return "Black"
        }
    }
}

struct MenuBarStyle: Codable, Equatable {
    var fontPreset: MenuBarFontPreset
    var textSizePreset: MenuBarTextSizePreset
    var colorPreset: MenuBarColorPreset
    var isBold: Bool

    private enum CodingKeys: String, CodingKey {
        case fontPreset
        case textSizePreset
        case colorPreset
        case isBold
    }

    static let `default` = MenuBarStyle(
        fontPreset: .system,
        textSizePreset: .regular,
        colorPreset: .label,
        isBold: false
    )

    init(
        fontPreset: MenuBarFontPreset,
        textSizePreset: MenuBarTextSizePreset,
        colorPreset: MenuBarColorPreset,
        isBold: Bool = false
    ) {
        self.fontPreset = fontPreset
        self.textSizePreset = textSizePreset
        self.colorPreset = colorPreset
        self.isBold = isBold
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        fontPreset = try container.decodeIfPresent(MenuBarFontPreset.self, forKey: .fontPreset) ?? .system
        textSizePreset = try container.decodeIfPresent(MenuBarTextSizePreset.self, forKey: .textSizePreset) ?? .regular
        colorPreset = try container.decodeIfPresent(MenuBarColorPreset.self, forKey: .colorPreset) ?? .label
        isBold = try container.decodeIfPresent(Bool.self, forKey: .isBold) ?? false
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(fontPreset, forKey: .fontPreset)
        try container.encode(textSizePreset, forKey: .textSizePreset)
        try container.encode(colorPreset, forKey: .colorPreset)
        try container.encode(isBold, forKey: .isBold)
    }
}

struct AppState: Codable, Equatable {
    static let defaultRotationHours = 6
    static let defaultRotationMinutes = 0
    static let minRotationHours = 0
    static let maxRotationHours = 168
    static let minRotationMinutes = 0
    static let maxRotationMinutes = 59

    var quotes: [String]
    var rotationHours: Int
    var rotationMinutes: Int
    var menuBarStyle: MenuBarStyle
    var currentIndex: Int?
    var lastRotationAt: Date?

    private enum CodingKeys: String, CodingKey {
        case quotes
        case rotationHours
        case rotationMinutes
        case menuBarStyle
        case currentIndex
        case lastRotationAt
    }

    init(
        quotes: [String],
        rotationHours: Int,
        rotationMinutes: Int = defaultRotationMinutes,
        menuBarStyle: MenuBarStyle = .default,
        currentIndex: Int?,
        lastRotationAt: Date?
    ) {
        self.quotes = quotes
        self.rotationHours = rotationHours
        self.rotationMinutes = rotationMinutes
        self.menuBarStyle = menuBarStyle
        self.currentIndex = currentIndex
        self.lastRotationAt = lastRotationAt
    }

    static var empty: AppState {
        AppState(
            quotes: [],
            rotationHours: defaultRotationHours,
            rotationMinutes: defaultRotationMinutes,
            menuBarStyle: .default,
            currentIndex: nil,
            lastRotationAt: nil
        )
    }

    var rotationIntervalSeconds: Int {
        (rotationHours * 3600) + (rotationMinutes * 60)
    }

    var currentQuote: String? {
        guard let currentIndex, quotes.indices.contains(currentIndex) else {
            return nil
        }
        return quotes[currentIndex]
    }

    mutating func normalize() {
        let interval = Self.clampedRotationInterval(hours: rotationHours, minutes: rotationMinutes)
        rotationHours = interval.hours
        rotationMinutes = interval.minutes

        if rotationIntervalSeconds == 0 {
            rotationHours = Self.defaultRotationHours
            rotationMinutes = Self.defaultRotationMinutes
        }

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
        clampedRotationInterval(hours: hours, minutes: 0).hours
    }

    static func clampedRotationInterval(hours: Int, minutes: Int) -> (hours: Int, minutes: Int) {
        let normalizedHours = min(max(hours, minRotationHours), maxRotationHours)
        let normalizedMinutes = min(max(minutes, minRotationMinutes), maxRotationMinutes)
        return (normalizedHours, normalizedMinutes)
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        quotes = try container.decodeIfPresent([String].self, forKey: .quotes) ?? []
        rotationHours = try container.decodeIfPresent(Int.self, forKey: .rotationHours) ?? Self.defaultRotationHours
        rotationMinutes = try container.decodeIfPresent(Int.self, forKey: .rotationMinutes) ?? Self.defaultRotationMinutes
        menuBarStyle = try container.decodeIfPresent(MenuBarStyle.self, forKey: .menuBarStyle) ?? .default
        currentIndex = try container.decodeIfPresent(Int.self, forKey: .currentIndex)
        lastRotationAt = try container.decodeIfPresent(Date.self, forKey: .lastRotationAt)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(quotes, forKey: .quotes)
        try container.encode(rotationHours, forKey: .rotationHours)
        try container.encode(rotationMinutes, forKey: .rotationMinutes)
        try container.encode(menuBarStyle, forKey: .menuBarStyle)
        try container.encode(currentIndex, forKey: .currentIndex)
        try container.encode(lastRotationAt, forKey: .lastRotationAt)
    }

    static func clampedRotationMinutes(_ minutes: Int) -> Int {
        min(max(minutes, minRotationMinutes), maxRotationMinutes)
    }

    private static func wrappedIndex(_ index: Int, count: Int) -> Int {
        guard count > 0 else { return 0 }
        let remainder = index % count
        return remainder >= 0 ? remainder : remainder + count
    }
}
