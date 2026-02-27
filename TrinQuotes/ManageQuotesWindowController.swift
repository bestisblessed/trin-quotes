import AppKit
import UniformTypeIdentifiers

final class QuoteInputTextField: NSTextField {
    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        guard event.modifierFlags.intersection(.deviceIndependentFlagsMask) == .command,
              let key = event.charactersIgnoringModifiers?.lowercased() else {
            return super.performKeyEquivalent(with: event)
        }

        switch key {
        case "v":
            return NSApp.sendAction(#selector(NSText.paste(_:)), to: nil, from: self)
        case "c":
            return NSApp.sendAction(#selector(NSText.copy(_:)), to: nil, from: self)
        case "x":
            return NSApp.sendAction(#selector(NSText.cut(_:)), to: nil, from: self)
        case "a":
            return NSApp.sendAction(#selector(NSResponder.selectAll(_:)), to: nil, from: self)
        default:
            return super.performKeyEquivalent(with: event)
        }
    }
}

final class ManageQuotesWindowController: NSWindowController, NSTableViewDataSource, NSTableViewDelegate, NSTextFieldDelegate {
    var onAddQuote: ((String) -> Void)?
    var onEditQuoteAtIndex: ((Int, String) -> Void)?
    var onRemoveQuoteAtIndex: ((Int) -> Void)?
    var onRotationIntervalChanged: ((Int, Int) -> Void)?

    private var quotes: [String] = []
    private var rotationHours: Int = AppState.defaultRotationHours
    private var rotationMinutes: Int = AppState.defaultRotationMinutes

    private let quoteInputField = QuoteInputTextField(string: "")
    private let addButton = NSButton(title: "Add", target: nil, action: nil)
    private let editButton = NSButton(title: "Edit", target: nil, action: nil)
    private let removeButton = NSButton(title: "Delete", target: nil, action: nil)
    private let exportButton = NSButton(title: "Export", target: nil, action: nil)
    private let doneButton = NSButton(title: "Done", target: nil, action: nil)
    private let rotationHoursField = NSTextField(string: "\(AppState.defaultRotationHours)")
    private let rotationMinutesField = NSTextField(string: "\(AppState.defaultRotationMinutes)")

    private let tableView = NSTableView()

    init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 460, height: 360),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Manage Quotes"
        window.isReleasedWhenClosed = false

        super.init(window: window)
        setupUI()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func render(state: AppState) {
        quotes = state.quotes
        rotationHours = state.rotationHours
        rotationMinutes = state.rotationMinutes
        let previousSelectedRow = tableView.selectedRow

        tableView.reloadData()
        if previousSelectedRow >= 0, previousSelectedRow < quotes.count {
            tableView.selectRowIndexes(IndexSet(integer: previousSelectedRow), byExtendingSelection: false)
            quoteInputField.stringValue = quotes[previousSelectedRow]
        }
        updateSelectionButtons()
        refreshRotationFieldStrings()
    }

    private func setupUI() {
        guard let contentView = window?.contentView else { return }

        let rootStack = NSStackView()
        rootStack.translatesAutoresizingMaskIntoConstraints = false
        rootStack.orientation = .vertical
        rootStack.spacing = 12

        let inputRow = NSStackView()
        inputRow.orientation = .horizontal
        inputRow.spacing = 8

        quoteInputField.placeholderString = "Enter a quote"
        quoteInputField.translatesAutoresizingMaskIntoConstraints = false

        addButton.target = self
        addButton.action = #selector(addQuote)

        inputRow.addArrangedSubview(quoteInputField)
        inputRow.addArrangedSubview(addButton)

        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("QuoteColumn"))
        column.title = "Quotes"
        tableView.addTableColumn(column)
        tableView.headerView = nil
        tableView.dataSource = self
        tableView.delegate = self
        tableView.usesAlternatingRowBackgroundColors = true

        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.documentView = tableView

        let bottomRow = NSStackView()
        bottomRow.orientation = .horizontal
        bottomRow.spacing = 8

        removeButton.target = self
        removeButton.action = #selector(removeSelectedQuote)
        editButton.target = self
        editButton.action = #selector(editSelectedQuote)
        exportButton.target = self
        exportButton.action = #selector(exportQuotes)
        doneButton.target = self
        doneButton.action = #selector(doneManagingQuotes)
        removeButton.isEnabled = false
        editButton.isEnabled = false

        let spacer = NSView()
        spacer.translatesAutoresizingMaskIntoConstraints = false

        let rotationLabel = NSTextField(labelWithString: "Rotation")
        let hourLabel = NSTextField(labelWithString: "h")
        let minuteLabel = NSTextField(labelWithString: "m")

        rotationHoursField.placeholderString = "0"
        rotationMinutesField.placeholderString = "0"

        rotationHoursField.delegate = self
        rotationHoursField.target = self
        rotationHoursField.action = #selector(rotationFieldsAction)
        rotationHoursField.alignment = .right

        rotationMinutesField.delegate = self
        rotationMinutesField.target = self
        rotationMinutesField.action = #selector(rotationFieldsAction)
        rotationMinutesField.alignment = .right

        let hourFormatter = NumberFormatter()
        hourFormatter.numberStyle = .none
        hourFormatter.minimum = NSNumber(value: AppState.minRotationHours)
        hourFormatter.maximum = NSNumber(value: AppState.maxRotationHours)
        rotationHoursField.formatter = hourFormatter

        let minuteFormatter = NumberFormatter()
        minuteFormatter.numberStyle = .none
        minuteFormatter.minimum = NSNumber(value: AppState.minRotationMinutes)
        minuteFormatter.maximum = NSNumber(value: AppState.maxRotationMinutes)
        rotationMinutesField.formatter = minuteFormatter

        bottomRow.addArrangedSubview(editButton)
        bottomRow.addArrangedSubview(removeButton)
        bottomRow.addArrangedSubview(exportButton)
        bottomRow.addArrangedSubview(doneButton)
        bottomRow.addArrangedSubview(spacer)
        bottomRow.addArrangedSubview(rotationLabel)
        bottomRow.addArrangedSubview(rotationHoursField)
        bottomRow.addArrangedSubview(hourLabel)
        bottomRow.addArrangedSubview(rotationMinutesField)
        bottomRow.addArrangedSubview(minuteLabel)

        contentView.addSubview(rootStack)
        rootStack.addArrangedSubview(inputRow)
        rootStack.addArrangedSubview(scrollView)
        rootStack.addArrangedSubview(bottomRow)

        NSLayoutConstraint.activate([
            rootStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            rootStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            rootStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            rootStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16),

            addButton.widthAnchor.constraint(equalToConstant: 72),
            scrollView.heightAnchor.constraint(greaterThanOrEqualToConstant: 220),
            rotationHoursField.widthAnchor.constraint(equalToConstant: 52),
            rotationMinutesField.widthAnchor.constraint(equalToConstant: 52),
            spacer.widthAnchor.constraint(greaterThanOrEqualToConstant: 20)
        ])
    }

    @objc private func addQuote() {
        let quote = quoteInputField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !quote.isEmpty else { return }

        let selectedRow = tableView.selectedRow
        if selectedRow >= 0, selectedRow < quotes.count {
            onEditQuoteAtIndex?(selectedRow, quote)
        } else {
            onAddQuote?(quote)
            quoteInputField.stringValue = ""
        }
    }

    @objc private func removeSelectedQuote() {
        let row = tableView.selectedRow
        guard row >= 0, row < quotes.count else { return }
        onRemoveQuoteAtIndex?(row)
    }

    @objc private func editSelectedQuote() {
        let row = tableView.selectedRow
        guard row >= 0, row < quotes.count else { return }

        let quote = quoteInputField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !quote.isEmpty else { return }

        onEditQuoteAtIndex?(row, quote)
    }

    @objc private func exportQuotes() {
        let panel = NSSavePanel()
        panel.title = "Export Quotes"
        panel.nameFieldStringValue = "trin-quotes.txt"
        panel.allowedContentTypes = [.plainText]

        guard panel.runModal() == .OK, let url = panel.url else { return }

        let output = quotes.joined(separator: "\n")
        do {
            try output.write(to: url, atomically: true, encoding: .utf8)
        } catch {
            NSAlert(error: error).runModal()
        }
    }

    @objc private func doneManagingQuotes() {
        window?.makeFirstResponder(nil)
        close()
    }

    @objc private func rotationFieldsAction() {
        commitRotationInterval()
    }

    func controlTextDidEndEditing(_ obj: Notification) {
        guard let editedField = obj.object as? NSTextField,
              editedField == rotationHoursField || editedField == rotationMinutesField else {
            return
        }
        commitRotationInterval()
    }

    private func commitRotationInterval() {
        let hoursInput = rotationHoursField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        let minutesInput = rotationMinutesField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)

        if hoursInput.isEmpty, minutesInput.isEmpty {
            refreshRotationFieldStrings()
            return
        }

        let enteredHours = hoursInput.isEmpty ? 0 : (Int(hoursInput) ?? rotationHours)
        let enteredMinutes = minutesInput.isEmpty ? 0 : (Int(minutesInput) ?? rotationMinutes)
        let normalized = AppState.clampedRotationInterval(hours: enteredHours, minutes: enteredMinutes)

        guard normalized.hours != 0 || normalized.minutes != 0 else {
            refreshRotationFieldStrings()
            return
        }

        rotationHours = normalized.hours
        rotationMinutes = normalized.minutes
        refreshRotationFieldStrings()

        onRotationIntervalChanged?(rotationHours, rotationMinutes)
    }

    private func refreshRotationFieldStrings() {
        rotationHoursField.stringValue = rotationHours == 0 ? "" : "\(rotationHours)"
        rotationMinutesField.stringValue = "\(rotationMinutes)"
    }

    func numberOfRows(in tableView: NSTableView) -> Int {
        quotes.count
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let identifier = NSUserInterfaceItemIdentifier("QuoteCell")

        let textField: NSTextField
        if let reused = tableView.makeView(withIdentifier: identifier, owner: self) as? NSTextField {
            textField = reused
        } else {
            textField = NSTextField(labelWithString: "")
            textField.identifier = identifier
            textField.lineBreakMode = .byTruncatingTail
            textField.translatesAutoresizingMaskIntoConstraints = false
        }

        textField.stringValue = quotes[row]
        return textField
    }

    func tableViewSelectionDidChange(_ notification: Notification) {
        let row = tableView.selectedRow
        if row >= 0, row < quotes.count {
            quoteInputField.stringValue = quotes[row]
        }
        updateSelectionButtons()
    }

    private func updateSelectionButtons() {
        let hasSelection = tableView.selectedRow >= 0
        removeButton.isEnabled = hasSelection
        editButton.isEnabled = hasSelection
        exportButton.isEnabled = !quotes.isEmpty
    }
}
