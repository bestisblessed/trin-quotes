import AppKit

final class ManageQuotesWindowController: NSWindowController, NSTableViewDataSource, NSTableViewDelegate, NSTextFieldDelegate {
    var onAddQuote: ((String) -> Void)?
    var onRemoveQuoteAtIndex: ((Int) -> Void)?
    var onRotationHoursChanged: ((Int) -> Void)?

    private var quotes: [String] = []
    private var rotationHours: Int = AppState.defaultRotationHours

    private let quoteInputField = NSTextField(string: "")
    private let addButton = NSButton(title: "Add", target: nil, action: nil)
    private let removeButton = NSButton(title: "Remove Selected", target: nil, action: nil)
    private let rotationField = NSTextField(string: "\(AppState.defaultRotationHours)")

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

        tableView.reloadData()
        removeButton.isEnabled = tableView.selectedRow >= 0
        rotationField.stringValue = "\(rotationHours)"
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
        removeButton.isEnabled = false

        let spacer = NSView()
        spacer.translatesAutoresizingMaskIntoConstraints = false

        let rotationLabel = NSTextField(labelWithString: "Rotation (hours)")

        rotationField.delegate = self
        rotationField.target = self
        rotationField.action = #selector(rotationFieldAction)
        rotationField.alignment = .right

        let formatter = NumberFormatter()
        formatter.numberStyle = .none
        formatter.minimum = NSNumber(value: AppState.minRotationHours)
        formatter.maximum = NSNumber(value: AppState.maxRotationHours)
        rotationField.formatter = formatter

        bottomRow.addArrangedSubview(removeButton)
        bottomRow.addArrangedSubview(spacer)
        bottomRow.addArrangedSubview(rotationLabel)
        bottomRow.addArrangedSubview(rotationField)

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
            rotationField.widthAnchor.constraint(equalToConstant: 60),
            spacer.widthAnchor.constraint(greaterThanOrEqualToConstant: 20)
        ])
    }

    @objc private func addQuote() {
        let quote = quoteInputField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !quote.isEmpty else { return }

        onAddQuote?(quote)
        quoteInputField.stringValue = ""
    }

    @objc private func removeSelectedQuote() {
        let row = tableView.selectedRow
        guard row >= 0, row < quotes.count else { return }
        onRemoveQuoteAtIndex?(row)
    }

    @objc private func rotationFieldAction() {
        commitRotationHours()
    }

    func controlTextDidEndEditing(_ obj: Notification) {
        guard let editedField = obj.object as? NSTextField, editedField == rotationField else {
            return
        }
        commitRotationHours()
    }

    private func commitRotationHours() {
        let enteredHours = Int(rotationField.stringValue) ?? rotationHours
        let normalizedHours = AppState.clampedRotationHours(enteredHours)
        rotationField.stringValue = "\(normalizedHours)"

        guard normalizedHours != rotationHours else { return }
        rotationHours = normalizedHours
        onRotationHoursChanged?(normalizedHours)
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
        removeButton.isEnabled = tableView.selectedRow >= 0
    }
}
