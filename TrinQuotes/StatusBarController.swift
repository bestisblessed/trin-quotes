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
        if let quote = state.currentQuote {
            statusItem.button?.title = Self.truncatedTitle(from: quote)
            currentQuoteItem.title = quote
        } else {
            statusItem.button?.title = "No quotes"
            currentQuoteItem.title = "No quotes configured"
        }

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
}
