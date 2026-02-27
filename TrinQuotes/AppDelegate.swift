import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let store: QuoteStore = UserDefaultsQuoteStore()

    private var state: AppState = .empty
    private var statusBarController: StatusBarController?
    private var manageQuotesWindowController: ManageQuotesWindowController?
    private var rotator: QuoteRotator?
    private var wakeObserver: NSObjectProtocol?

    func applicationDidFinishLaunching(_ notification: Notification) {
        state = AppState.launchState(from: store.load(), now: Date())
        store.save(state)

        let statusBarController = StatusBarController()
        statusBarController.onNextQuote = { [weak self] in
            self?.rotator?.forceNextQuote()
        }
        statusBarController.onManageQuotes = { [weak self] in
            self?.showManageQuotesWindow()
        }
        statusBarController.onQuit = {
            NSApplication.shared.terminate(nil)
        }
        self.statusBarController = statusBarController

        rotator = QuoteRotator(
            stateProvider: { [weak self] in
                self?.state ?? .empty
            },
            stateConsumer: { [weak self] newState in
                self?.updateState(newState)
            }
        )

        rotator?.start()

        wakeObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.rotator?.onTick(now: Date())
        }

        render()
    }

    func applicationWillTerminate(_ notification: Notification) {
        rotator?.stop()

        if let wakeObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(wakeObserver)
        }
    }

    private func showManageQuotesWindow() {
        let controller: ManageQuotesWindowController

        if let existingController = manageQuotesWindowController {
            controller = existingController
        } else {
            controller = ManageQuotesWindowController()
            controller.onAddQuote = { [weak self] quote in
                self?.addQuote(quote)
            }
            controller.onEditQuoteAtIndex = { [weak self] index, quote in
                self?.editQuote(at: index, with: quote)
            }
            controller.onRemoveQuoteAtIndex = { [weak self] index in
                self?.removeQuote(at: index)
            }
            controller.onRotationIntervalChanged = { [weak self] hours, minutes in
                self?.setRotationInterval(hours: hours, minutes: minutes)
            }
            controller.onMenuBarStyleChanged = { [weak self] style in
                self?.setMenuBarStyle(style)
            }
            manageQuotesWindowController = controller
        }

        controller.render(state: state)
        controller.showWindow(nil)
        controller.window?.makeKeyAndOrderFront(nil)
        NSApplication.shared.activate(ignoringOtherApps: true)
    }

    private func addQuote(_ quote: String) {
        mutateState { state in
            state.quotes.append(quote)
            if state.currentIndex == nil {
                state.currentIndex = 0
                state.lastRotationAt = Date()
            }
        }
    }

    private func removeQuote(at index: Int) {
        mutateState { state in
            guard state.quotes.indices.contains(index) else { return }

            state.quotes.remove(at: index)

            guard !state.quotes.isEmpty else {
                state.currentIndex = nil
                state.lastRotationAt = nil
                return
            }

            if let currentIndex = state.currentIndex {
                if index < currentIndex {
                    state.currentIndex = currentIndex - 1
                } else if index == currentIndex {
                    state.currentIndex = min(currentIndex, state.quotes.count - 1)
                }
            }

            state.lastRotationAt = Date()
        }
    }

    private func editQuote(at index: Int, with quote: String) {
        let trimmedQuote = quote.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuote.isEmpty else { return }

        mutateState { state in
            guard state.quotes.indices.contains(index) else { return }
            state.quotes[index] = trimmedQuote
            state.lastRotationAt = Date()
        }
    }

    private func setRotationInterval(hours: Int, minutes: Int) {
        let normalized = AppState.clampedRotationInterval(hours: hours, minutes: minutes)
        guard normalized.hours != 0 || normalized.minutes != 0 else { return }

        mutateState { state in
            state.rotationHours = normalized.hours
            state.rotationMinutes = normalized.minutes
            state.lastRotationAt = Date()
        }
    }

    private func setMenuBarStyle(_ style: MenuBarStyle) {
        mutateState { state in
            state.menuBarStyle = style
        }
    }

    private func mutateState(_ mutation: (inout AppState) -> Void) {
        var newState = state
        mutation(&newState)
        updateState(newState)
    }

    private func updateState(_ newState: AppState) {
        state = newState.normalized()
        store.save(state)
        render()
    }

    private func render() {
        statusBarController?.render(state: state)
        manageQuotesWindowController?.render(state: state)
    }
}
