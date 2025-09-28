//
//  CommandPalette.swift
//  TermKit
//
//  Created by Claude Code on 9/27/25.
//  Copyright © 2025 Miguel de Icaza. All rights reserved.
//

import Foundation
#if os(macOS)
import os
#endif

#if os(macOS)
@available(OSX 11.0, *)
private var commandPaletteLogger: Logger = Logger(subsystem: "termkit", category: "CommandPalette")
#endif

@MainActor func logCommandPalette(_ message: String) {
#if os(macOS)
    if #available(macOS 11.0, *) {
        commandPaletteLogger.log("CommandPalette: \(message, privacy: .public)")
    }
#endif
    // Write to file so we can see the output even with terminal UI running
    if let data = "CommandPalette: \(message)\n".data(using: .utf8) {
        let url = URL(fileURLWithPath: "/tmp/claude/commandpalette.log")
        try? FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        if FileManager.default.fileExists(atPath: url.path) {
            let handle = try? FileHandle(forWritingTo: url)
            handle?.seekToEndOfFile()
            handle?.write(data)
            handle?.closeFile()
        } else {
            try? data.write(to: url)
        }
    }
}

// MARK: - Command Hit Types

/// Represents a command search result with scoring and execution capability
public struct CommandHit {
    /// The relevance score (0.0 to 1.0, higher is better)
    public let score: Float

    /// The display text for the command
    public let display: String

    /// Optional help text describing the command
    public let help: String?

    /// The action to execute when this command is selected
    public let action: () -> Void

    /// Plain text version of the command for searching
    public let text: String

    /// Positions of matched characters for highlighting
    public let matchPositions: [Int]

    public init(score: Float, display: String, help: String? = nil, text: String? = nil, matchPositions: [Int] = [], action: @escaping () -> Void) {
        self.score = score
        self.display = display
        self.help = help
        self.text = text ?? display
        self.matchPositions = matchPositions
        self.action = action
    }
}

/// Represents a discoverable command shown when no search query is entered
public struct DiscoveryHit {
    /// The display text for the command
    public let display: String

    /// Optional help text describing the command
    public let help: String?

    /// The action to execute when this command is selected
    public let action: () -> Void

    /// Plain text version of the command for searching
    public let text: String

    /// Discovery hits always have a score of 0.0
    public var score: Float { return 0.0 }

    public init(display: String, help: String? = nil, text: String? = nil, action: @escaping () -> Void) {
        self.display = display
        self.help = help
        self.text = text ?? display
        self.action = action
    }
}

// MARK: - Command Provider Protocol

/// Protocol for providing commands to the command palette
public protocol CommandProvider: AnyObject {
    /// The view context this provider operates in
    var view: View? { get set }

    /// Initialize the provider
    func startup() async

    /// Search for commands matching the given query
    /// - Parameter query: The search string entered by the user
    /// - Returns: An array of command hits matching the query
    func search(query: String) async -> [CommandHit]

    /// Provide discoverable commands when no query is entered
    /// - Returns: An array of discovery hits to show by default
    func discover() async -> [DiscoveryHit]

    /// Cleanup when the provider is shutdown
    func shutdown() async
}

// MARK: - Simple Command Provider

/// A simple command provider that takes a predefined list of commands
public class SimpleCommandProvider: CommandProvider {
    public weak var view: View?

    private let commands: [(name: String, help: String?, action: () -> Void)]

    public init(commands: [(String, String?, () -> Void)]) {
        self.commands = commands
    }

    public func startup() async {
        // No initialization needed for simple provider
    }

    public func search(query: String) async -> [CommandHit] {
        var hits: [CommandHit] = []

        for command in commands {
            let matchResult = calculateFuzzyMatch(query: query, text: command.name)

            if matchResult.score > 0 {
                hits.append(CommandHit(
                    score: matchResult.score,
                    display: command.name,
                    help: command.help,
                    text: command.name,
                    matchPositions: matchResult.positions,
                    action: command.action
                ))
            }
        }

        return hits.sorted { $0.score > $1.score }
    }

    public func discover() async -> [DiscoveryHit] {
        return commands.map { command in
            DiscoveryHit(
                display: command.name,
                help: command.help,
                text: command.name,
                action: command.action
            )
        }
    }

    public func shutdown() async {
        // No cleanup needed for simple provider
    }

    /// Enhanced fuzzy scoring algorithm that returns both score and match positions
    private func calculateFuzzyMatch(query: String, text: String) -> (score: Float, positions: [Int]) {
        if query.isEmpty { return (1.0, []) }
        if text.isEmpty { return (0.0, []) }

        let queryLower = query.lowercased()
        let textLower = text.lowercased()

        // Exact match gets highest score
        if textLower == queryLower {
            let positions = Array(0..<text.count)
            return (1.0, positions)
        }

        // Prefix match gets high score
        if textLower.hasPrefix(queryLower) {
            let positions = Array(0..<queryLower.count)
            return (0.9, positions)
        }

        // Contains match gets medium score
        if let range = textLower.range(of: queryLower) {
            let startIndex = textLower.distance(from: textLower.startIndex, to: range.lowerBound)
            let positions = Array(startIndex..<(startIndex + queryLower.count))
            return (0.7, positions)
        }

        // Fuzzy matching - check if all query characters appear in order
        var queryIndex = queryLower.startIndex
        var matchPositions: [Int] = []
        var textIndex = 0

        for char in textLower {
            if queryIndex < queryLower.endIndex && char == queryLower[queryIndex] {
                matchPositions.append(textIndex)
                queryIndex = queryLower.index(after: queryIndex)
            }
            textIndex += 1
        }

        if matchPositions.count == queryLower.count {
            let score = Float(matchPositions.count) / Float(text.count) * 0.5
            return (score, matchPositions)
        }

        return (0.0, [])
    }
}

// MARK: - Command Palette View

/// A command palette interface that provides search and command execution
public class CommandPalette: View {
    private var captionLabel: Label
    private var searchField: TextField
    private var resultsList: CommandListView
    private var providers: [CommandProvider] = []
    fileprivate var currentHits: [Any] = [] // CommandHit or DiscoveryHit
    private var selectedCommand: (() -> Void)?

    /// Caption text displayed before the search field
    public var caption: String = "Command:" {
        didSet {
            captionLabel.text = caption
            updateLayout()
        }
    }

    /// Placeholder text for the search field
    public var placeholder: String = "Search for commands..." {
        didSet {
            // TextField doesn't have built-in placeholder support, so we'll show it as help text
            updatePlaceholder()
        }
    }

    /// Whether to run commands immediately when selected (true) or fill the search field (false)
    public var runOnSelect: Bool = true

    /// Callback invoked when the palette is dismissed
    public var onDismiss: ((_ executed: Bool) -> Void)?

    public override init() {
        captionLabel = Label("Command:")
        searchField = TextField()
        resultsList = CommandListView()

        super.init()
        setupUI()
    }

    public override init(frame: Rect) {
        captionLabel = Label("Command:")
        searchField = TextField()
        resultsList = CommandListView()

        super.init(frame: frame)
        setupUI()
    }

    private func setupUI() {
        // Set up event handlers for search field
        searchField.textChanged = { [weak self] field, oldText in
            Task { @MainActor in
                await self?.performSearch(query: field.text)
            }
        }

        searchField.onSubmit = { [weak self] field in
            self?.executeSelectedCommand()
        }

        // Set up command list view
        resultsList.palette = self

        // Add subviews
        addSubview(captionLabel)
        addSubview(searchField)
        addSubview(resultsList)

        // Set border style
        border = .solid

        // Initial layout
        updateLayout()

        // Initial discovery search
        Task { @MainActor in
            await performSearch(query: "")
        }
    }

    private func updateLayout() {
        // Configure caption label - inline with search field
        captionLabel.x = Pos.at(1)
        captionLabel.y = Pos.at(1)
        captionLabel.width = Dim.sized(caption.count + 1)  // Width based on caption text plus space
        captionLabel.height = Dim.sized(1)

        // Configure search field - positioned after caption
        searchField.x = Pos.at(1 + caption.count + 1)  // Start after caption and a space
        searchField.y = Pos.at(1)  // Same row as caption
        searchField.width = Dim.fill(2 + caption.count + 1)  // Adjust for caption width
        searchField.height = Dim.sized(1)

        // Configure results list - back to original position since caption is now inline
        resultsList.x = Pos.at(1)
        resultsList.y = Pos.at(2)  // Back to original position
        resultsList.width = Dim.fill(2)
        resultsList.height = Dim.fill(2)
    }

    private func updatePlaceholder() {
        // Since TextField doesn't have placeholder support, we could extend it or show help text
        // For now, we'll leave the search field empty and document the placeholder behavior
    }

    /// Add a command provider to the palette
    public func addProvider(_ provider: CommandProvider) {
        provider.view = self
        providers.append(provider)

        Task { @MainActor in
            await provider.startup()
            await performSearch(query: searchField.text)
        }
    }

    /// Remove all providers
    public func clearProviders() {
        Task { @MainActor in
            for provider in providers {
                await provider.shutdown()
            }
        }
        providers.removeAll()
    }

    /// Perform a search across all providers
    private func performSearch(query: String) async {
        var allHits: [Any] = []

        for provider in providers {
            if query.isEmpty {
                let discoveryHits = await provider.discover()
                allHits.append(contentsOf: discoveryHits)
            } else {
                let searchHits = await provider.search(query: query)
                allHits.append(contentsOf: searchHits)
            }
        }

        // Sort hits by score (highest first)
        if !query.isEmpty {
            allHits.sort { hit1, hit2 in
                let score1 = (hit1 as? CommandHit)?.score ?? 0
                let score2 = (hit2 as? CommandHit)?.score ?? 0
                return score1 > score2
            }
        }

        currentHits = allHits

        // Reset selection and scroll position when items change
        resultsList.resetSelection()

        // Auto-select first item if available
        if !currentHits.isEmpty {
            resultsList.selected = 0
        }
    }

    /// Execute the currently selected command
    public func executeSelectedCommand() {
        guard resultsList.selected < currentHits.count else { return }

        let hit = currentHits[resultsList.selected]

        if let commandHit = hit as? CommandHit {
            selectedCommand = commandHit.action
        } else if let discoveryHit = hit as? DiscoveryHit {
            selectedCommand = discoveryHit.action
        }

        if runOnSelect, let action = selectedCommand {
            dismiss(executed: true)
            action()
        } else if let commandHit = hit as? CommandHit {
            // Fill search field with command text
            searchField.text = commandHit.text
        } else if let discoveryHit = hit as? DiscoveryHit {
            // Fill search field with command text
            searchField.text = discoveryHit.text
        }
    }

    /// Dismiss the command palette
    public func dismiss(executed: Bool = false) {
        onDismiss?(executed)
        // Return focus to the superview before removing
        if let parent = superview {
            _ = parent.becomeFirstResponder()
            parent.removeSubview(self)
        }
    }

    /// Focus the search field
    public func focusSearchField() {
        _ = searchField.becomeFirstResponder()
    }

    /// Handle key events
    public override func processKey(event: KeyEvent) -> Bool {
        switch event.key {
        case .esc, .controlC:
            dismiss(executed: false)
            return true
        case .cursorUp:
            if resultsList.hasFocus {
                return resultsList.processKey(event: event)
            } else if !currentHits.isEmpty {
                _ = resultsList.becomeFirstResponder()
                return true
            }
        case .cursorDown:
            if !resultsList.hasFocus && !currentHits.isEmpty {
                _ = resultsList.becomeFirstResponder()
                return true
            }
            return resultsList.processKey(event: event)
        case .returnKey:
            executeSelectedCommand()
            return true
        default:
            return searchField.processKey(event: event)
        }
        return false
    }
}

// MARK: - Custom Command List View

private class CommandListView: View {
    weak var palette: CommandPalette?
    var selected: Int = 0 {
        didSet {
            updateScroll()
            setNeedsDisplay()
        }
    }

    var topItem: Int = 0 // First visible item

    var itemCount: Int {
        return palette?.currentHits.count ?? 0
    }

    var maxVisibleItems: Int {
        let itemHeight = 2 // Each item takes 2 rows

        // Calculate available height dynamically based on the actual palette size
        // Layout: border(1) + search(1) + commands + border(1) = palette.height
        // So: commands = palette.height - 4 (accounting for borders and search area)
        let correctHeight: Int
        if let paletteFrame = palette?.frame {
            correctHeight = max(2, paletteFrame.height - 4) // Minimum 2 rows for 1 item
        } else {
            correctHeight = 14 // Fallback to previous default
        }

        let completeItems = correctHeight / itemHeight

        Task { @MainActor in
            logCommandPalette("CommandListView frame: \(frame.width)x\(frame.height) at (\(frame.origin.x),\(frame.origin.y))")
            if let paletteFrame = palette?.frame {
                logCommandPalette("Palette frame: \(paletteFrame.width)x\(paletteFrame.height)")
            }
            logCommandPalette("Dynamic available height: \(correctHeight), complete items: \(completeItems)")
        }

        return max(1, completeItems) // Ensure at least 1 complete item is visible
    }

    override init() {
        super.init()
        canFocus = true
    }

    /// Update scroll position to keep selected item fully visible (both rows)
    private func updateScroll() {
        let itemHeight = 2 // Each item takes 2 rows

        // Use the same dynamic height calculation as maxVisibleItems
        let viewHeight: Int
        if let paletteFrame = palette?.frame {
            viewHeight = max(2, paletteFrame.height - 4) // Minimum 2 rows for 1 item
        } else {
            viewHeight = 14 // Fallback to previous default
        }

        Task { @MainActor in
            logCommandPalette("updateScroll called: selected=\(selected), topItem=\(topItem), viewHeight=\(viewHeight), itemCount=\(itemCount)")
        }

        // Ensure we have valid dimensions
        if viewHeight <= 0 || itemCount == 0 {
            Task { @MainActor in
                logCommandPalette("Invalid dimensions: viewHeight=\(viewHeight), itemCount=\(itemCount)")
            }
            return
        }

        // Calculate the row positions of the selected item
        let selectedStartRow = (selected - topItem) * itemHeight
        let selectedEndRow = selectedStartRow + itemHeight - 1

        // Check if the selected item is fully visible
        let isSelectedVisible = selectedStartRow >= 0 && selectedEndRow < viewHeight

        Task { @MainActor in
            logCommandPalette("Selected item rows: \(selectedStartRow) to \(selectedEndRow), visible: \(isSelectedVisible)")
        }

        if !isSelectedVisible {
            let oldTopItem = topItem

            // If selected item is above the visible area (scrolled too far down)
            if selected < topItem {
                topItem = selected
                Task { @MainActor in
                    logCommandPalette("Scrolling up: topItem \(oldTopItem) -> \(topItem)")
                }
            }
            // If selected item is below the visible area or partially cut off at bottom
            else {
                // Calculate how many complete items can fit in the view
                let maxCompleteItems = viewHeight / itemHeight
                // Scroll so the selected item is at the bottom of the visible area
                topItem = selected - maxCompleteItems + 1
                Task { @MainActor in
                    logCommandPalette("Scrolling down: maxCompleteItems=\(maxCompleteItems), topItem \(oldTopItem) -> \(topItem)")
                }
            }
        }

        // Ensure topItem stays within valid bounds
        topItem = max(0, topItem)

        // Don't scroll past the end if we have fewer items than can fit
        if itemCount > 0 {
            let maxCompleteItems = viewHeight / itemHeight
            let maxPossibleTopItem = max(0, itemCount - maxCompleteItems)
            topItem = min(topItem, maxPossibleTopItem)

            Task { @MainActor in
                logCommandPalette("Final scroll state: topItem=\(topItem), maxPossibleTopItem=\(maxPossibleTopItem)")
            }
        }
    }

    /// Render text with highlighting at specified positions
    private func renderHighlightedText(painter: Painter, text: String, col: Int, row: Int, maxWidth: Int,
                                     normalColors: Attribute, highlightColors: Attribute, matchPositions: [Int]) {
        let maxLength = min(text.count, maxWidth)
        let matchSet = Set(matchPositions)

        var currentCol = col
        for (index, char) in text.enumerated() {
            if index >= maxLength { break }

            // Choose color based on whether this character is a match
            painter.attribute = matchSet.contains(index) ? highlightColors : normalColors
            painter.goto(col: currentCol, row: row)
            painter.add(str: String(char))
            currentCol += 1
        }
    }

    override func redraw(region: Rect, painter p: Painter) {
        let painter = Painter(from: self, parent: p)

        guard let palette = palette else { return }

        // Clear the background
        painter.attribute = colorScheme.normal
        for row in 0..<frame.height {
            painter.goto(col: 0, row: row)
            let spaces = String(repeating: " ", count: frame.width)
            painter.add(str: spaces)
        }

        let itemHeight = 2 // Each command takes 2 rows
        let visibleItems = min(maxVisibleItems, itemCount - topItem)

        for i in 0..<visibleItems {
            let itemIndex = topItem + i
            if itemIndex >= itemCount { break }

            let hit = palette.currentHits[itemIndex]
            var displayText = ""
            var helpText = ""
            var matchPositions: [Int] = []

            if let commandHit = hit as? CommandHit {
                displayText = commandHit.display
                helpText = commandHit.help ?? ""
                matchPositions = commandHit.matchPositions
            } else if let discoveryHit = hit as? DiscoveryHit {
                displayText = discoveryHit.display
                helpText = discoveryHit.help ?? ""
                matchPositions = [] // No highlighting for discovery hits
            }

            let isSelected = (itemIndex == selected)
            let baseRow = i * itemHeight

            // Choose colors based on selection and focus
            let mainColors = (isSelected && hasFocus) ? colorScheme.focus : colorScheme.normal
            let dimmedColors = (isSelected && hasFocus) ?
                colorScheme.focus.change(foreground: .gray) :
                colorScheme.normal.change(foreground: .gray)

            // Create highlight colors - use bold/bright for matches
            let highlightColors = mainColors.change(foreground: .brightYellow)

            // If selected, fill both rows with background color first
            if isSelected && hasFocus {
                painter.attribute = mainColors
                // Fill first row
                painter.goto(col: 0, row: baseRow)
                let spaces = String(repeating: " ", count: frame.width)
                painter.add(str: spaces)
                // Fill second row if there's help text
                if !helpText.isEmpty && baseRow + 1 < frame.height {
                    painter.goto(col: 0, row: baseRow + 1)
                    painter.add(str: spaces)
                }
            }

            // Draw the main command name on the first line with highlighting
            if !matchPositions.isEmpty {
                renderHighlightedText(
                    painter: painter,
                    text: displayText,
                    col: 1,
                    row: baseRow,
                    maxWidth: frame.width - 2,
                    normalColors: mainColors,
                    highlightColors: highlightColors,
                    matchPositions: matchPositions
                )
            } else {
                // No highlighting needed
                painter.attribute = mainColors
                painter.goto(col: 1, row: baseRow)
                let commandText = String(displayText.prefix(frame.width - 2))
                painter.add(str: commandText)
            }

            // Draw help text on the second line if available
            if !helpText.isEmpty && baseRow + 1 < frame.height {
                painter.attribute = dimmedColors
                painter.goto(col: 3, row: baseRow + 1)
                let helpTextTrimmed = String(helpText.prefix(frame.width - 4))
                painter.add(str: helpTextTrimmed)
            }
        }
    }

    override func processKey(event: KeyEvent) -> Bool {
        switch event.key {
        case .cursorUp:
            if selected > 0 {
                selected -= 1
                return true
            }
        case .cursorDown:
            if selected < itemCount - 1 {
                selected += 1
                return true
            }
        case .returnKey:
            palette?.executeSelectedCommand()
            return true
        default:
            break
        }
        return false
    }

    /// Reset selection and scroll when items change
    func resetSelection() {
        selected = 0
        topItem = 0
        updateScroll() // Ensure scroll position is valid
        setNeedsDisplay()
    }

    /// Ensure selection is within valid bounds
    func validateSelection() {
        if selected >= itemCount {
            selected = max(0, itemCount - 1)
        }
        if selected < 0 {
            selected = 0
        }
        updateScroll()
    }
}

// MARK: - Data Source and Delegate (kept for compatibility but not used with CommandListView)

private class CommandPaletteDataSource: ListViewDataSource {
    weak var palette: CommandPalette?

    init(palette: CommandPalette) {
        self.palette = palette
    }

    func getCount(listView: ListView) -> Int {
        return palette?.currentHits.count ?? 0
    }

    func isMarked(listView: ListView, item: Int) -> Bool {
        return false // No marking support for command palette
    }

    func setMark(listView: ListView, item: Int, state: Bool) {
        // No marking support for command palette
    }
}

private class CommandPaletteDelegate: ListViewDelegate {
    weak var palette: CommandPalette?

    init(palette: CommandPalette) {
        self.palette = palette
    }

    func render(listView: ListView, painter: Painter, selected: Bool, item: Int, col: Int, line: Int, width: Int) {
        guard let palette = palette, item < palette.currentHits.count else { return }

        let hit = palette.currentHits[item]
        var displayText = ""
        var helpText = ""

        if let commandHit = hit as? CommandHit {
            displayText = commandHit.display
            helpText = commandHit.help ?? ""
        } else if let discoveryHit = hit as? DiscoveryHit {
            displayText = discoveryHit.display
            helpText = discoveryHit.help ?? ""
        }

        let scheme = listView.colorScheme
        let normalColors = scheme.normal
        let focusColors = scheme.focus

        // Choose colors based on selection and focus
        let mainColors = (selected && listView.hasFocus) ? focusColors : normalColors

        // Create dimmed colors for help text using a darker color
        let dimmedColors = mainColors.change(foreground: .gray)

        // Clear the area first
        painter.attribute = mainColors
        painter.goto(col: col, row: line)
        let spaces = String(repeating: " ", count: width)
        painter.add(str: spaces)

        if !helpText.isEmpty {
            painter.goto(col: col, row: line + 1)
            painter.add(str: spaces)
        }

        // Draw the main command name on the first line
        painter.attribute = mainColors
        painter.goto(col: col + 2, row: line) // Add 2-space indent
        let commandText = String(displayText.prefix(width - 4))
        painter.add(str: commandText)

        // Draw help text on the second line if available
        if !helpText.isEmpty {
            painter.attribute = dimmedColors
            painter.goto(col: col + 4, row: line + 1) // Add 4-space indent for help text
            let helpTextTrimmed = String(helpText.prefix(width - 6))
            painter.add(str: helpTextTrimmed)
        }
    }

    func selectionChanged(listView: ListView) {
        // Selection change handled automatically by ListView
    }

    func activate(listView: ListView, item: Int) -> Bool {
        palette?.executeSelectedCommand()
        return true
    }
}

// MARK: - Application Integration

public extension Application {
    /// Show a command palette with the given providers
    /// - Parameters:
    ///   - providers: Array of command providers to use
    ///   - caption: Caption text displayed above the search field
    ///   - placeholder: Placeholder text for the search field
    ///   - width: Optional width (defaults to calculated size)
    ///   - height: Optional height (defaults to calculated size)
    ///   - x: Optional x position (defaults to centered)
    ///   - y: Optional y position (defaults to centered)
    ///   - onDismiss: Callback when palette is dismissed
    static func showCommandPalette(
        providers: [CommandProvider] = [],
        caption: String = "Command:",
        placeholder: String = "Search for commands...",
        width: Int? = nil,
        height: Int? = nil,
        x: Int? = nil,
        y: Int? = nil,
        onDismiss: ((_ executed: Bool) -> Void)? = nil
    ) {
        let palette = CommandPalette()
        palette.caption = caption
        palette.placeholder = placeholder
        palette.onDismiss = onDismiss

        // Add providers
        for provider in providers {
            palette.addProvider(provider)
        }

        // Calculate size and position based on provided parameters or sensible defaults
        let terminalSize = Application.driver.size

        let finalWidth = width ?? min(70, terminalSize.width - 8)  // Default: smaller width, more margin
        let finalHeight = height ?? min(18, terminalSize.height - 6)  // Default: compact height
        let finalX = x ?? (terminalSize.width - finalWidth) / 2  // Default: centered horizontally
        let finalY = y ?? (terminalSize.height - finalHeight) / 2 - 2  // Default: centered, slightly higher

        Task { @MainActor in
            logCommandPalette("Terminal size: \(terminalSize.width)x\(terminalSize.height)")
            logCommandPalette("Palette size: \(finalWidth)x\(finalHeight) at (\(finalX),\(finalY))")
        }

        palette.frame = Rect(x: finalX, y: finalY, width: finalWidth, height: finalHeight)

        // Add to current toplevel and focus
        Application.current?.addSubview(palette)
        palette.focusSearchField()
    }

    /// Show a compact command palette (smaller size)
    static func showCompactCommandPalette(
        providers: [CommandProvider] = [],
        caption: String = "Command:",
        placeholder: String = "Search commands...",
        onDismiss: ((_ executed: Bool) -> Void)? = nil
    ) {
        showCommandPalette(
            providers: providers,
            caption: caption,
            placeholder: placeholder,
            width: 50,
            height: 12,
            onDismiss: onDismiss
        )
    }

    /// Show a full-size command palette (takes up most of the screen)
    static func showFullCommandPalette(
        providers: [CommandProvider] = [],
        caption: String = "Command:",
        placeholder: String = "Search commands...",
        onDismiss: ((_ executed: Bool) -> Void)? = nil
    ) {
        let terminalSize = Application.driver.size
        let width = terminalSize.width - 4  // Leave small margin
        let height = terminalSize.height - 4  // Leave small margin

        showCommandPalette(
            providers: providers,
            caption: caption,
            placeholder: placeholder,
            width: width,
            height: height,
            x: 2,  // Small margin from edge
            y: 2,  // Small margin from edge
            onDismiss: onDismiss
        )
    }
}