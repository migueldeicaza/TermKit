//
//  MarkdownView.swift - renders markdown content using swift-markdown
//  TermKit
//
//  Created by Claude on 8/11/25.
//

import Foundation
import Markdown

/// A view that renders markdown content using the swift-markdown library
open class MarkdownView: View {
    /// The markdown document to render
    public var document: Document? {
        didSet {
            needsReprocessing = true
            setNeedsDisplay()
        }
    }
    
    /// Flag to indicate that markdown needs to be reprocessed
    private var needsReprocessing: Bool = false
    
    /// The first row shown in the view (for scrolling)
    public private(set) var topRow: Int = 0 {
        didSet {
            setNeedsDisplay()
        }
    }
    
    /// Internal storage for rendered content lines
    private var renderedLines: [AttributedString] = []
    
    /// Additional colors for markdown rendering
    public var headingColor: Attribute?
    public var emphasisColor: Attribute?
    public var linkColor: Attribute?
    public var codeColor: Attribute?
    
    /// If true, text will be wrapped to fit the view width
    public var wrapAround: Bool = true {
        didSet {
            if wrapAround != oldValue {
                needsReprocessing = true
                setNeedsDisplay()
            }
        }
    }
    
    public override init() {
        super.init()
        canFocus = true
    }
    
    public override init(frame: Rect) {
        super.init(frame: frame)
        canFocus = true
    }
    
    /// Sets the markdown content from a string
    public func setMarkdown(content: String) {
        document = Document(parsing: content)
    }
    
    /// Process the markdown document and convert to renderable lines
    private func processMarkdown() {
        guard let document = document else {
            renderedLines = []
            return
        }
        
        var renderer = MarkdownRenderer(view: self)
        renderedLines = renderer.render(document: document)
    }
    
    /// Scrolls the view to display the specified row at the top
    /// - Parameter row: Row that should be displayed at the top
    public func scrollTo(row: Int) {
        let newTopRow = max(0, min(row, max(0, renderedLines.count - frame.height)))
        if newTopRow != topRow {
            topRow = newTopRow
        }
    }
    
    /// Scrolls up by one line
    public func scrollUp() {
        scrollTo(row: topRow - 1)
    }
    
    /// Scrolls down by one line  
    public func scrollDown() {
        scrollTo(row: topRow + 1)
    }
    
    /// Scrolls up by one page
    public func pageUp() {
        scrollTo(row: topRow - frame.height + 1)
    }
    
    /// Scrolls down by one page
    public func pageDown() {
        scrollTo(row: topRow + frame.height - 1)
    }
    
    open override func layoutSubviews() {
        try? super.layoutSubviews()
        // Process markdown after layout when we have proper frame dimensions
        if needsReprocessing {
            processMarkdown()
            needsReprocessing = false
        }
    }
    
    open override func redraw(region: Rect, painter: Painter) {
        // In case layoutSubviews wasn't called, ensure markdown is processed
        if needsReprocessing && frame.width > 0 {
            processMarkdown()
            needsReprocessing = false
        }
        
        painter.clear()
        painter.attribute = colorScheme.normal
        let visibleLines = min(region.height, renderedLines.count - topRow)
        
        for row in 0..<visibleLines {
            let lineIndex = topRow + row
            if lineIndex >= renderedLines.count {
                break
            }
            
            let line = renderedLines[lineIndex]
            painter.goto(col: 0, row: row)
            line.draw(on: painter)
        }
    }
    
    open override func processKey(event: KeyEvent) -> Bool {
        switch event.key {
        case .cursorUp, .controlP:
            scrollUp()
            return true
            
        case .cursorDown, .controlN:
            scrollDown()
            return true
            
        case .pageUp:
            pageUp()
            return true
            
        case .letter("v") where event.isAlt:
            pageUp()
            return true
            
        case .pageDown, .controlV:
            pageDown()
            return true
            
        case .home:
            scrollTo(row: 0)
            return true
            
        case .letter("<") where event.isAlt:
            scrollTo(row: 0)
            return true
            
        case .end:
            scrollTo(row: renderedLines.count)
            return true
            
        case .letter(">") where event.isAlt:
            scrollTo(row: renderedLines.count)
            return true
            
        default:
            return false
        }
    }
    
    open override func positionCursor() {
        moveTo(col: 0, row: 0)
    }
}

/// Internal renderer that converts markdown elements to AttributedStrings
private struct MarkdownRenderer: MarkupWalker {
    private var view: MarkdownView
    private var lines: [AttributedString] = []
    private var currentLineText: String = ""
    private var headingLevel: Int = 0
    private var currentHeadingText: String = ""
    private var inListItem: Bool = false
    private var listItemPrefix: String = ""
    private var listNestingLevel: Int = 0
    private var inBlockQuote: Bool = false
    
    init(view: MarkdownView) {
        self.view = view
    }
    
    mutating func render(document: Document) -> [AttributedString] {
        lines = []
        currentLineText = ""
        visit(document)
        
        // Add final line if it has content
        finishCurrentLine()
        
        return lines
    }
    
    mutating func visitDocument(_ document: Document) -> () {
        descendInto(document)
    }
    
    mutating func visitHeading(_ heading: Heading) -> () {
        finishCurrentLine()
        
        // Add blank line before heading for better spacing
        if !lines.isEmpty {
            lines.append(AttributedString(text: ""))
        }
        
        headingLevel = heading.level
        currentHeadingText = ""
        
        descendInto(heading)
        
        // Render heading with appropriate boxing
        renderHeading(text: currentHeadingText, level: heading.level)
        
        // Add blank line after heading
        lines.append(AttributedString(text: ""))
        headingLevel = 0
        currentHeadingText = ""
    }
    
    private mutating func renderHeading(text: String, level: Int) {
        switch level {
        case 1: // H1: Double line box
            let padding = 2
            let width = text.count + (padding * 2)
            let topLine = "╔" + String(repeating: "═", count: width) + "╗"
            let midLine = "║" + String(repeating: " ", count: padding) + "[bold]" + text + "[/]" + String(repeating: " ", count: padding) + "║"
            let botLine = "╚" + String(repeating: "═", count: width) + "╝"
            
            lines.append(AttributedString(markup: topLine))
            lines.append(AttributedString(markup: midLine))
            lines.append(AttributedString(markup: botLine))
            
        case 2: // H2: Single line box
            let padding = 1
            let width = text.count + (padding * 2)
            let topLine = "┌" + String(repeating: "─", count: width) + "┐"
            let midLine = "│" + String(repeating: " ", count: padding) + "[bold]" + text + "[/]" + String(repeating: " ", count: padding) + "│"
            let botLine = "└" + String(repeating: "─", count: width) + "┘"
            
            lines.append(AttributedString(markup: topLine))
            lines.append(AttributedString(markup: midLine))
            lines.append(AttributedString(markup: botLine))
            
        case 3: // H3: Underline
            lines.append(AttributedString(markup: "[bold]" + text + "[/]"))
            lines.append(AttributedString(markup: String(repeating: "─", count: text.count)))
            
        default: // H4+: Just bold
            lines.append(AttributedString(markup: "[bold]" + text + "[/]"))
        }
    }
    
    mutating func visitParagraph(_ paragraph: Paragraph) -> () {
        if inListItem {
            // In list items, don't add line breaks for paragraphs
            descendInto(paragraph)
        } else {
            finishCurrentLine()
            descendInto(paragraph)
            finishCurrentLine()
            
            // Add blank line after paragraph, but not within block quotes
            if !inBlockQuote {
                lines.append(AttributedString(text: ""))
            }
        }
    }
    
    mutating func visitText(_ text: Text) -> () {
        if headingLevel > 0 {
            currentHeadingText += text.string
        } else {
            currentLineText += text.string
        }
    }
    
    mutating func visitEmphasis(_ emphasis: Emphasis) -> () {
        if headingLevel > 0 {
            descendInto(emphasis) // For headings, just collect the text
        } else {
            currentLineText += "[dim]"
            descendInto(emphasis)
            currentLineText += "[/]"
        }
    }
    
    mutating func visitStrong(_ strong: Strong) -> () {
        if headingLevel > 0 {
            descendInto(strong) // For headings, just collect the text
        } else {
            currentLineText += "[bold]"
            descendInto(strong)
            currentLineText += "[/]"
        }
    }
    
    mutating func visitInlineCode(_ inlineCode: InlineCode) -> () {
        if headingLevel > 0 {
            currentHeadingText += inlineCode.code
        } else {
            currentLineText += "[standout]" + inlineCode.code + "[/]"
        }
    }
    
    mutating func visitCodeBlock(_ codeBlock: CodeBlock) -> () {
        finishCurrentLine()
        
        let language = codeBlock.language ?? ""
        let codeLines = codeBlock.code.split(separator: "\n", omittingEmptySubsequences: false).map { String($0) }
        
        // Calculate box width based on content and available space
        let availableWidth = max(40, view.frame.width - 4) // Leave some margin
        let contentWidth = calculateCodeBlockWidth(codeLines: codeLines, language: language, maxWidth: availableWidth)
        
        // Render the boxed code block
        renderCodeBlockBox(codeLines: codeLines, language: language, boxWidth: contentWidth)
        
        // Add blank line after code block
        lines.append(AttributedString(text: ""))
    }
    
    private mutating func calculateCodeBlockWidth(codeLines: [String], language: String, maxWidth: Int) -> Int {
        // Find the longest line
        let maxLineLength = codeLines.map { $0.cellCount() }.max() ?? 0
        
        // Account for padding (2 spaces on each side) and box characters (1 on each side)
        let contentPadding = 4 // "│ " + content + " │"
        let minContentWidth = maxLineLength + contentPadding
        
        // Account for language label in top border: "─ language ┐"
        let languageLabelWidth = language.isEmpty ? 0 : language.cellCount() + 1 // space before language
        let minTopBorderWidth = languageLabelWidth + 2 // "┌" + content + "┐"
        
        // Use the larger of content width or top border width, but cap at maxWidth
        let idealWidth = max(minContentWidth, minTopBorderWidth)
        return min(idealWidth, maxWidth)
    }
    
    private mutating func renderCodeBlockBox(codeLines: [String], language: String, boxWidth: Int) {
        let innerWidth = boxWidth
        
        // Top border with language label
        let topBorder = createTopBorder(language: language, width: boxWidth)
        lines.append(AttributedString(markup: "[standout]" + topBorder + "[/]"))
        
        // Content lines
        for line in codeLines {
            let paddedLine = createCodeLine(content: line, width: innerWidth)
            lines.append(AttributedString(markup: "[standout]" + paddedLine + "[/]"))
        }
        
        // Bottom border
        let safeInnerWidth = max(0, innerWidth-2)
        let bottomBorder = "└" + String(repeating: "─", count: safeInnerWidth) + "┘"
        lines.append(AttributedString(markup: "[standout]" + bottomBorder + "[/]"))
    }
    
    private func createTopBorder(language: String, width: Int) -> String {
        let innerWidth = max(0, width - 2)
        
        if innerWidth <= 0 {
            return "┌┐"
        }
        
        if language.isEmpty {
            // Simple top border without language
            return "┌" + String(repeating: "─", count: innerWidth) + "┐"
        } else {
            // Top border with language label on the right
            let languageLabel = " " + language + " "
            let languageLabelWidth = languageLabel.cellCount()
            
            if languageLabelWidth >= innerWidth {
                // Language label too long, just show simple border
                return "┌" + String(repeating: "─", count: innerWidth) + "┐"
            } else {
                // Create border with language label on the right
                let leftDashes = max(0, innerWidth - languageLabelWidth)
                return "┌" + String(repeating: "─", count: leftDashes) + languageLabel + "┐"
            }
        }
    }
    
    private func createCodeLine(content: String, width: Int) -> String {
        let contentLength = content.cellCount()
        
        // Ensure minimum width for the box
        if width < 4 {
            return "│ │"
        }
        
        if contentLength >= width - 4 {
            // Content too long, truncate it
            let maxContentLength = max(0, width - 4) // Account for "│ " and " │"
            if maxContentLength <= 0 {
                return "│ │"
            }
            let truncated = String(content.prefix(maxContentLength))
            return "│ " + truncated + " │"
        } else {
            // Pad content to fit the box width
            let totalPadding = width - contentLength - 4 // Account for "│ " and " │"
            let safePadding = max(0, totalPadding)
            return "│ " + content + String(repeating: " ", count: safePadding) + " │"
        }
    }
    
    mutating func visitBlockQuote(_ blockQuote: BlockQuote) -> () {
        finishCurrentLine()
        
        // Process children and prefix each line with "> "
        let oldLines = lines
        lines = []
        let wasInBlockQuote = inBlockQuote
        inBlockQuote = true
        descendInto(blockQuote)
        inBlockQuote = wasInBlockQuote
        
        // Prefix all generated lines with "> " and apply dim styling
        let quoteLines = lines
        lines = oldLines
        
        for quoteLine in quoteLines {
            let lineText = quoteLine.toString()
            if lineText.isEmpty {
                // Even empty lines in block quotes should show the ">" indicator for continuity
                lines.append(AttributedString(markup: "[dim]>[/]"))
            } else {
                let prefixedText = "[dim]> " + lineText + "[/]"
                lines.append(AttributedString(markup: prefixedText))
            }
        }
        
        lines.append(AttributedString(text: ""))
    }
    
    mutating func visitListItem(_ listItem: ListItem) -> () {
        finishCurrentLine()
        
        // Calculate indentation based on nesting level
        let indentation = String(repeating: "  ", count: listNestingLevel)
        
        // Add bullet point with proper indentation
        currentLineText += indentation + "• "
        
        // Set flag to avoid paragraph line breaks within list items
        let wasInListItem = inListItem
        let wasListItemPrefix = listItemPrefix
        let wasNestingLevel = listNestingLevel
        
        inListItem = true
        // Prefix for wrapped lines should align with the text content (after bullet and space)
        listItemPrefix = indentation + "  "
        listNestingLevel += 1  // Increment for any nested lists within this item
        
        descendInto(listItem)
        
        // Finish the line while still in list item context
        finishCurrentLine()
        
        // Restore previous state
        inListItem = wasInListItem
        listItemPrefix = wasListItemPrefix
        listNestingLevel = wasNestingLevel
    }
    
    mutating func visitLink(_ link: Link) -> () {
        if headingLevel > 0 {
            descendInto(link)
        } else {
            currentLineText += "[underline]"
            descendInto(link)
            currentLineText += "[/]"
        }
    }
    
    mutating func visitSoftBreak(_ softBreak: SoftBreak) -> () {
        if headingLevel > 0 {
            currentHeadingText += " "
        } else {
            currentLineText += " "
        }
    }
    
    mutating func visitLineBreak(_ lineBreak: LineBreak) -> () {
        if headingLevel == 0 {
            finishCurrentLine()
        }
    }
    
    private mutating func finishCurrentLine() {
        if !currentLineText.isEmpty {
            if view.wrapAround && view.frame.width > 0 {
                let prefix = inListItem ? listItemPrefix : ""
                wrapAndAppendText(currentLineText, prefix: prefix)
            } else {
                lines.append(AttributedString(markup: currentLineText))
            }
            currentLineText = ""
        }
    }
    
    private mutating func wrapAndAppendText(_ text: String, prefix: String) {
        // Use frame width minus some margin for safety
        let availableWidth = max(20, view.frame.width - 4)
        if availableWidth <= 0 {
            lines.append(AttributedString(markup: text))
            return
        }
        
        // Parse the markup text to handle BBCode properly
        let wrappedLines = wrapTextWithMarkup(text, width: availableWidth, prefix: prefix)
        for wrappedLine in wrappedLines {
            lines.append(AttributedString(markup: wrappedLine))
        }
    }
    
    private func wrapTextWithMarkup(_ text: String, width: Int, prefix: String) -> [String] {
        var result: [String] = []
        var currentLine = ""
        var currentWidth = 0
        var isFirstLine = true
        
        // Extract leading spaces to preserve indentation
        let leadingSpaces = String(text.prefix { $0 == " " })
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Split by spaces for basic word wrapping, but filter out empty strings  
        let words = trimmedText.split(separator: " ", omittingEmptySubsequences: true).map { String($0) }
        
        for word in words {
            // Skip empty words
            if word.isEmpty { continue }
            
            // Calculate visual width of word (accounting for BBCode markup)
            let wordVisualWidth = calculateVisualWidth(word)
            
            // Calculate available width (accounting for prefix on continuation lines and leading spaces)
            let firstLinePrefix = isFirstLine ? leadingSpaces : prefix
            let prefixWidth = firstLinePrefix.cellCount()
            let availableWidth = width - prefixWidth
            
            // Don't process if available width is too small
            if availableWidth <= 0 {
                result.append(text)
                return result
            }
            
            // Space needed if we're adding to existing line
            let spaceNeeded = currentLine.isEmpty ? 0 : 1
            let totalWidthNeeded = currentWidth + spaceNeeded + wordVisualWidth
            
            // Check if we need to wrap
            if totalWidthNeeded > availableWidth && !currentLine.isEmpty {
                // Finish current line
                let linePrefix = isFirstLine ? leadingSpaces : prefix
                result.append(linePrefix + currentLine)
                
                // Start new line with the word
                currentLine = word
                currentWidth = wordVisualWidth
                isFirstLine = false
            } else {
                // Add word to current line
                if !currentLine.isEmpty {
                    currentLine += " "
                    currentWidth += 1
                }
                currentLine += word
                currentWidth += wordVisualWidth
            }
        }
        
        // Add final line
        if !currentLine.isEmpty {
            let finalPrefix = isFirstLine ? leadingSpaces : prefix
            result.append(finalPrefix + currentLine)
        }
        
        // If we somehow ended up with no result, return the original text
        return result.isEmpty ? [text] : result
    }
    
    private func calculateVisualWidth(_ text: String) -> Int {
        // Simple approximation: count characters but ignore BBCode markup
        var visibleText = text
        
        // Remove common BBCode patterns
        let patterns = ["[bold]", "[/bold]", "[dim]", "[/dim]", "[standout]", "[/standout]", "[underline]", "[/underline]", "[/]"]
        for pattern in patterns {
            visibleText = visibleText.replacingOccurrences(of: pattern, with: "")
        }
        
        return visibleText.cellCount()
    }
}
