import AppKit

final class StatusBarController: NSObject {
    private static let maxVisibleCharacters = 48

    private let statusItem: NSStatusItem
    private let menu = NSMenu()

    private let currentQuoteItem = NSMenuItem(title: "No quotes configured", action: nil, keyEquivalent: "")
    private let nextQuoteItem = NSMenuItem(title: "Next Quote Now", action: nil, keyEquivalent: "")
    private let manageQuotesItem = NSMenuItem(title: "Manage Quotes…", action: nil, keyEquivalent: "")
    private let quitItem = NSMenuItem(title: "Quit Trin Quotes", action: nil, keyEquivalent: "")

    var onNextQuote: (() -> Void)?
    var onManageQuotes: (() -> Void)?
    var onQuit: (() -> Void)?

    init(statusBar: NSStatusBar = .system) {
        self.statusItem = statusBar.statusItem(withLength: NSStatusItem.variableLength)
        super.init()
        configureMenu()
        render(state: .empty)
    }

    func render(state: AppState) {
        let displayText: String
        if let quote = state.currentQuote {
            displayText = Self.truncatedTitle(from: quote)
            currentQuoteItem.title = quote
        } else {
            displayText = "No quotes"
            currentQuoteItem.title = "No quotes configured"
        }

        statusItem.button?.attributedTitle = Self.attributedTitle(for: displayText, style: state.menuBarStyle)
        currentQuoteItem.isEnabled = false
        nextQuoteItem.isEnabled = !state.quotes.isEmpty
    }

    private func configureMenu() {
        currentQuoteItem.isEnabled = false

        nextQuoteItem.target = self
        nextQuoteItem.action = #selector(handleNextQuote)

        manageQuotesItem.target = self
        manageQuotesItem.action = #selector(handleManageQuotes)

        quitItem.target = self
        quitItem.action = #selector(handleQuit)

        menu.addItem(currentQuoteItem)
        menu.addItem(.separator())
        menu.addItem(nextQuoteItem)
        menu.addItem(manageQuotesItem)
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    @objc private func handleNextQuote() {
        onNextQuote?()
    }

    @objc private func handleManageQuotes() {
        onManageQuotes?()
    }

    @objc private func handleQuit() {
        onQuit?()
    }

    private static func truncatedTitle(from quote: String) -> String {
        guard quote.count > maxVisibleCharacters else {
            return quote
        }

        let prefix = quote.prefix(maxVisibleCharacters)
        return "\(prefix)…"
    }

    private static func attributedTitle(for text: String, style: MenuBarStyle) -> NSAttributedString {
        NSAttributedString(
            string: text,
            attributes: [
                .font: font(for: style),
                .foregroundColor: color(for: style)
            ]
        )
    }

    static func font(for style: MenuBarStyle) -> NSFont {
        let size = CGFloat(style.textSizePreset.rawValue)
        let weight: NSFont.Weight = style.isBold ? .bold : .regular

        switch style.fontPreset {
        case .system:
            return .systemFont(ofSize: size, weight: weight)
        case .rounded:
            if let descriptor = NSFont.systemFont(ofSize: size, weight: weight).fontDescriptor.withDesign(.rounded),
               let font = NSFont(descriptor: descriptor, size: size) {
                return font
            }
            return .systemFont(ofSize: size, weight: weight)
        case .monospaced:
            return .monospacedSystemFont(ofSize: size, weight: weight)
        case .serif:
            let base = NSFont(name: "Times New Roman", size: size) ?? .systemFont(ofSize: size, weight: .regular)
            guard style.isBold else { return base }
            return NSFontManager.shared.convert(base, toHaveTrait: .boldFontMask)
        }
    }

    static func color(for style: MenuBarStyle) -> NSColor {
        switch style.colorPreset {
        case .label:
            return .labelColor
        case .red:
            return .systemRed
        case .orange:
            return .systemOrange
        case .green:
            return .systemGreen
        case .blue:
            return .systemBlue
        case .pink:
            return .systemPink
        case .yellow:
            return .systemYellow
        case .purple:
            return .systemPurple
        case .indigo:
            return .systemIndigo
        case .teal:
            return .systemTeal
        case .cyan:
            return .systemCyan
        case .brown:
            return .systemBrown
        case .gray:
            return .systemGray
        case .black:
            return .black
        }
    }
}
