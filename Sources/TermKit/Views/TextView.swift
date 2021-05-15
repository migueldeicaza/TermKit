//
//  TextView.swift - multi-line text editing
//  TermKit
//
//  Created by Miguel de Icaza on 5/11/19.
//  Copyright © 2019 Miguel de Icaza. All rights reserved.
//
// TODO:
//   I need to either track the columns in UTF-8 byte offsets (sounds bad), or
//   make the row+line to offset routine compute the offset to the first element
//   of the row, and then manually add the column based on cellCount()
//
// Horizontal scrolling, when pasting among others
// Additional mouse support (selection)
// Does not seem to use cellSize very much yet.

import Foundation
import TextBufferKit

typealias TextBuffer = TextField.TextBuffer

/**
 * Multi-line text editing view
 *
 * The text view provides a multi-line text view.   Users interact
 * with it with the standard Emacs commands for movement or the arrow
 * keys.
 *
 * Navigation:
 * - Move left: left cursor, or Control-B
 * - Move right: right cursor key, or Control-F
 * - Move one page down: Page Down or Control-V
 * - Move one page up: Page Up or Alt-V
 * - Move to the beginning of the line: Home key or Control-A
 * - Move to the end of the line: End key or Control-E
 *
 * Editing:
 * - Backspace key: removes the previous character
 * - Delete character: Delete Key or Control-D
 * - Delete to the end-of-line: Control-K, appends contents to the clipboard
 * - Delete line at the end of the line: Control-K, appends content to the clipboard
 * - Paste contents of copy buffer: Control-Y
 *
 * Selection:
 * - Start selectrion: Control-Space
 * - Copy selection to clipboard: Alt-W
 * - Cut selection to clipboard: Control-W
 */

open class TextView: View {
    var storage: PieceTreeTextBuffer
    var selectionStartColumn: Int = 0
    var selectionStartRow: Int = 0
    var selecting: Bool = false

    /// The leftmost column being displayed
    public private(set) var leftColumn: Int = 0

    /// The first row shown on the textview, at the top
    public private(set) var topRow: Int = 0
    /// The current row in the buffer
    public private(set) var currentRow: Int = 0
    /// The current column in the buffer
    public private(set) var currentColumn: Int = 0
    
    /// Indicates readonly attribute of TextView, defaults to false
    public var isReadOnly = false
    
    /// Tracks changed made by the user, but also can be set externally by the application
    public var isDirty = false
    
    public override init (frame: Rect)
    {
        storage = TextView.createEmptyPieceTree ()
        super.init(frame: frame)
        canFocus = true
    }
    
    public override init ()
    {
        storage = TextView.createEmptyPieceTree ()
        super.init ()
        canFocus = true
    }
    
    static func createEmptyPieceTree (initialBlocks: [String]? = nil) -> PieceTreeTextBuffer {
        let builder = PieceTreeTextBufferBuilder()
        if let chunks = initialBlocks {
            for chunk in chunks {
                builder.acceptChunk(chunk)
            }
        }
        let factory = builder.finish(normalizeEol: true)
        return factory.create(DefaultEndOfLine.LF)
    }

    static func createEmptyPieceTree (buffer: [UInt8]) -> PieceTreeTextBuffer {
        let builder = PieceTreeTextBufferBuilder()
        builder.acceptChunk(buffer)
        let factory = builder.finish(normalizeEol: true)
        return factory.create(DefaultEndOfLine.LF)
    }

    func resetPosition ()
    {
        topRow = 0
        leftColumn = 0
        currentColumn = 0
        currentRow = 0
    }
    
    /// Sets or gets the text in the view, this returns `nil` if there are any invalid UTF8 sequences in the buffer, use
    /// `byteBuffer` property if you do not need the string
    public var text: String? {
        get {
            return String (bytes: storage.getLinesRawContent (), encoding: .utf8)
        }
        set {
            resetPosition()
            storage = TextView.createEmptyPieceTree(initialBlocks: newValue == nil ? [] : [newValue!])
            setNeedsDisplay()
        }
    }
    
    /// Provides access to the TextView content as a byte array
    public var byteBuffer: [UInt8] {
        get {
            return storage.getLinesRawContent ()
        }
        set {
            resetPosition()
            storage = TextView.createEmptyPieceTree(buffer: newValue)
        }
    }
    
    /**
     * Loads the contents of the file into the TextView.
     *
     * This can throw an IO error if there is a problem accessing the file
     *
     * - Parameter path: the path for the file to load
     *
     */
    public func loadFile (path: String) throws
    {
        resetPosition()
        setNeedsDisplay()
        
        let url = URL (fileURLWithPath: path)
        let data = try Data(contentsOf: url)
        
        let builder = PieceTreeTextBufferBuilder()
        builder.acceptChunk([UInt8] (data))
        let factory = builder.finish(normalizeEol: true)
        storage = factory.create(DefaultEndOfLine.LF)
        isDirty = false
    }
    
    /// Returns the current cursor position inside the buffer
    public var cursorPosition: Point {
        get {
            return Point (x: currentColumn, y: currentRow)
        }
    }
    
    open override func positionCursor() {
        if selecting {
            let minRow = min (max (min (selectionStartRow, currentRow)-topRow, 0), frame.height)
            let maxRow = min (max (max (selectionStartRow, currentRow)-topRow, 0), frame.height)
            
            //setNeedsDisplay(Rect(x: 0, y: Int(minRow), width: frame.width, height: Int(maxRow)))
        }
        moveTo (col: Int(currentColumn-leftColumn), row: Int(currentRow-topRow))
    }
    
    /// Returns an encoded region start..end (top 32 bits are the row, low32 the column) for the current selection
    func getRegionBoundIndexes () -> (start: Int, end: Int) {
        let selection = makeTextBufferOffset (col: selectionStartColumn, row: selectionStartRow)
        let point = makeTextBufferOffset(col: currentColumn, row: currentRow)
        
        if (selection > point) {
            return (point, selection)
        } else {
            return (selection, point)
        }
    }
    
    /// Returns true if the specified column and row are inside the selection
    func pointInSelection (col: Int, row: Int) -> Bool {
        let (start, end) = getRegionBoundIndexes()
        let q = makeTextBufferOffset(col: col, row: row)
        let r =  q >= start && q <= end
        
        if r {
            log ("probing for \(col) and \(row) -> \(r)")
        }
        return r
    }
    
    /// gets the selection as a string
    func getRegion () -> String
    {
        let (start, end) = getRegionBoundIndexes()
        let data = storage.getValueInRange(range: Range.from(start: start, end: end, on: storage))
        return String (bytes: data, encoding: .utf8) ?? ""
    }
    
    /// clears the contents of the selected region
    func clearRegion ()
    {
        let (start, end) = getRegionBoundIndexes()
        storage.delete(offset: start, count: end-start)
        
        setNeedsDisplay()
    }
    
    func getTextBuffer (forLine: Int) -> TextBuffer {
        // Coordinates in the TextBufferKit are 1-based
        let lineBytes = storage.getLineContent(forLine+1)
        if let x = String (bytes: lineBytes, encoding: .utf8) {
            return TextField.toTextBuffer(x)
        }
        return []
    }
    
    /// Controls how tabs are rendered
    public var tabSize: Int = 8 {
        didSet {
            if tabSize < 1 {
                tabSize = 8
            }
        }
    }
    open override func redraw(region: Rect, painter p: Painter) {
        p.colorNormal()
        let bottom = region.bottom
        let right = region.right
        let lineCount = storage.lineCount
        
        for row in region.top ..< bottom {
            let textLine = Int(topRow) + row
            if textLine > lineCount {
                p.colorNormal()
                p.clearRegion(left: region.left, top: row, right: region.right, bottom: row+1)
                continue
            }
            let line = getTextBuffer(forLine: textLine)
            let lineRuneCount = line.count
            
            // Works-ish, this needs to be replaced with actual rune counts at the specific position
            if line.count < region.left {
                p.clearRegion(left: region.left, top: row, right: region.right, bottom: row+1)
                continue
            }
            p.goto(col: region.left, row: row)
            var currentColorNormal: Bool = true
            
            p.colorNormal()
            var col = region.left
            while col < right {
                let lineCol = leftColumn + col
                var char: Character
                var useNormal = true
                if lineCol >= lineRuneCount {
                    char = " "
                } else {
                    char = line [lineCol].ch
                    if selecting && pointInSelection(col: col, row: row) {
                        useNormal = false
                    } else {
                        useNormal = true
                    }
                }
                if currentColorNormal != useNormal {
                    if useNormal {
                        p.colorNormal()
                    } else {
                        p.colorSelection()
                    }
                    currentColorNormal = useNormal
                }
//                if char == "\t" {
//                    let n = tabSize-(lineCol % tabSize)
//                    p.add (str: String (repeating: " ", count: n))
//                    col += n
//                    continue
//                } else {
                    p.add (str: String (char))
                    col += 1
//                }
            }
        }
        super.redraw(region: region, painter: p)
    }

    func setClipboard(text: String)
    {
        Clipboard.contents = text
    }
    
    func appendClipboard (text: String)
    {
        Clipboard.contents += text
    }
    
    func setClipboard(buffer: TextBuffer)
    {
        Clipboard.contents = TextField.fromTextBuffer (buffer)
    }
    
    func appendClipboard (buffer: TextBuffer)
    {
        Clipboard.contents += TextField.fromTextBuffer(buffer)
    }

    func getCurrentLine () -> TextBuffer
    {
        return getTextBuffer(forLine: currentRow)
    }
    
    func makeTextBufferOffset (col: Int, row: Int) -> Int {
        // Coordinates in the TextBufferKit are 1-based
        return storage.getOffsetAt(lineNumber: row+1, column: col+1)
    }
    
    func cursorOffset () -> Int {
        return makeTextBufferOffset(col: currentColumn, row: currentRow)
    }
    
    func toPairs (_ p: TextBufferKit.Position) -> (col: Int, row: Int)
    {
        // Coordinates in the TextBufferKit are 1-based
        return (p.column-1, p.line-1)
    }
    
    func insert (utf8: [UInt8]) {
        let cursor = cursorOffset()
        storage.insert (offset: cursor, value: utf8)
        
        // TODO: fetch the line again, and use cellCount() to figure out the right column
        // TODO adjust visibility based on new column/row

        adjustCursor(offset: cursor + utf8.count)
    }
    
    /// Offset is a TextBufferKit offset
    func adjustCursor (offset: Int) {
        (currentColumn, currentRow) = toPairs (storage.getPositionAt(offset: offset))

        if currentRow < topRow {
            topRow = currentRow
            setNeedsDisplay()
        }
    }
    
    /// A range in a text document expressed as (zero-based) start and end positions.
    public struct TextRange {
        /// Start position
        public var start: TextBufferKit.Position
        /// End position
        public var end: TextBufferKit.Position
    }
    
    /// This callback is invoked when a change is made to the text buffer, and it inclues the range being changed and the text that is changed, an empty text is used to delete text
    public var textEdit: (_ range: TextRange, _ text: String) -> () = { range, text in }
    
    /// Inserts the provided character at the current cursor location
    func insertChar (_ char: Character)
    {
    }
    
    /// Inserts the provided string at the current cursor location
    public func insert(text: String)
    {
        if isReadOnly {
            return
        }
        let row = currentRow
        let start = storage.getPositionAt(offset: cursorOffset ())
        
        insert (utf8: [UInt8](text.utf8))
        let end = storage.getPositionAt(offset: cursorOffset ())
        textEdit (TextRange (start: start, end: end), String (text))
        if row != currentRow {
            needDisplayToEnd(row: currentRow)
        } else {
            needDisplay (row: row)
        }
        isDirty = true
        selecting = false
    }
    
    // The column we are tracking, or -1 if we are not tracking any column
    var columnTrack: Int = -1
    
    /// Tries to snap the cursor to the tracking column
    func trackColumn ()
    {
        // Now track the column
        let line = getCurrentLine()
        if line.count < columnTrack {
            currentColumn = line.count
        } else if columnTrack != -1 {
            currentColumn = columnTrack
        } else if currentColumn > line.count {
            currentColumn = line.count
        }
        adjust ()
    }
    
    func adjust ()
    {
        var need = false
        if currentColumn < leftColumn {
            currentColumn = leftColumn
            need = true
        }
        if currentColumn - leftColumn > frame.width {
            leftColumn = currentColumn - frame.width + 1
            need = true
        }
        if currentRow < topRow {
            topRow = currentRow
            need = true
        }
        if currentRow - topRow > frame.height {
            topRow = currentRow - frame.height + 1
            need = true
        }
        if need {
            setNeedsDisplay()
        } else {
            positionCursor()
        }
    }
    
    func textBufferSize (_ inp: TextBuffer) -> Int
    {
        var size = 0
        
        for item in inp {
            size += Int (item.size)
        }
        return size
    }
    
    /**
     * Will scroll the view to display the specified row at the top
     * - Parameter row: Row that should be displayed at the top, if the value is negative it will be reset to zero
     */
    public func scrollTo (row: Int)
    {
        let rrow = row < 0 ? 0 : row
        let lineCount = storage.lineCount
        topRow = rrow > lineCount ? lineCount-1 : rrow
        setNeedsDisplay()
    }
    
    var lastWasKill = false
    
    // Flags one line for needing to be updated
    // row is in buffer coordinates
    func needDisplay (row: Int) {
        let r = row-topRow
        setNeedsDisplay (Rect (x: 0, y: r, width: frame.width, height: r+1))
    }
    
    // Flags from the specified line all the way to the bottom of the buffer to be redisplayed
    // row is in buffer coordinates
    func needDisplayToEnd (row: Int) {
        let r = row-topRow
        setNeedsDisplay (Rect (x: 0, y: r, width: frame.width, height: frame.height-r))
    }
    
    /// Scrolls one page down
    public func pageDown () {
        let nPageDnShift = frame.height - 1
        
        if currentRow < storage.lineCount {
            if columnTrack == -1 {
                columnTrack = currentColumn
            }
            let lineCount = storage.lineCount
            currentRow = (currentRow + nPageDnShift) > lineCount ? lineCount : currentRow + nPageDnShift
            if topRow < currentRow - nPageDnShift {
                topRow = currentRow >= lineCount ? currentRow - nPageDnShift : topRow + nPageDnShift
                setNeedsDisplay()
            }
            trackColumn()
        }
    }
    
    /// Scrolls one page up
    public func pageUp () {
        let nPageUpShift = frame.height - 1;
        if currentRow > 0 {
            if columnTrack == -1 {
                columnTrack = currentColumn;
            }
            currentRow = currentRow - nPageUpShift < 0 ? 0 : currentRow - nPageUpShift;
            if currentRow < topRow {
                topRow = topRow - nPageUpShift < 0 ? 0 : topRow - nPageUpShift;
                setNeedsDisplay ();
            }
            trackColumn ();
        }
    }
    
    /// moves the cursor to the next line
    public func nextLine () {
        let lineCount = storage.lineCount

        if currentRow + 1 < lineCount {
            if columnTrack == -1 {
                columnTrack = currentColumn
            }
            currentRow += 1
            if currentRow >= topRow + frame.height {
                topRow += 1
                setNeedsDisplay ()
            }
            trackColumn ();
        }
    }
    
    /// moves the cursor to the previous line
    public func previousLine () {
        if currentRow > 0 {
            if columnTrack == -1 {
                columnTrack = currentColumn
            }
            currentRow -= 1
            if currentRow < topRow {
                topRow -= 1
                setNeedsDisplay ()
            }
            trackColumn ();
        }
    }
    
    /// moves the cursor one character forward
    public func forwardCharacter () {
        let currentLine = getCurrentLine()
        if currentColumn < textBufferSize(currentLine) {
            currentColumn += 1
            if currentColumn >= leftColumn + frame.width {
                leftColumn += 1
                setNeedsDisplay()
            }
        } else {
            let lineCount = storage.lineCount

            if currentRow + 1 < lineCount {
                currentRow += 1
                currentColumn = 0
                leftColumn = 0
                if currentRow >= topRow + frame.height {
                    topRow += 1
                }
                setNeedsDisplay()
            }
        }
    }
    
    /// moves the cursor one character backwards
    public func backwardCharacter () {
        if currentColumn > 0 {
            currentColumn -= 1
            if currentColumn < leftColumn {
                leftColumn -= 1
                setNeedsDisplay()
            }
        } else {
            if currentRow > 0 {
                currentRow -= 1
                if currentRow < topRow {
                    topRow -= 1
                }
                let currentLine = getCurrentLine()
                currentColumn = textBufferSize(currentLine)
                let prev = leftColumn
                leftColumn = currentColumn - frame.width + 1
                if leftColumn < 0 {
                    leftColumn = 0
                }
                if prev != leftColumn {
                    setNeedsDisplay()
                }
            }
        }
    }
    
    /// moves the cursor to the beginning of the line
    public func moveBeginningOfLine () {
        currentColumn = 0
        if currentColumn < leftColumn {
            leftColumn = 0
            setNeedsDisplay()
        }
    }
    
    /// Deletes the character before the cursor position
    public func deleteBackwardCharacter () {
        if isReadOnly {
            return
        }
        let p = cursorOffset()
        if p < 1 {
            return
        }
        isDirty = true
        storage.delete (offset: p-1, count: 1)
        adjustCursor(offset: p-1)
        setNeedsDisplay()
        // TODO: attempt to reduce region to display
    }
    
    /// Deletes the character on top of the cursor
    public func deleteCharacter () {
        if isReadOnly {
            return
        }
        let p = cursorOffset()
        storage.delete (offset: p, count: 1)
        isDirty = true
        // TODO optimize, depending on how much needs to be redrawn
        setNeedsDisplay()
    }
    
    /// Deletes all characters from the current cursor position until the end of the line, and copies the result into the clipboard
    public func emacsKillToEndOfLine () {
        if isReadOnly {
            return
        }
        let p = cursorOffset()
        
        if storage.getValueAt(index: p) == 10 {
            storage.delete(offset: p, count: 1)
            
            if (lastWasKill) {
                appendClipboard(text: "\n")
            } else {
                setClipboard(text: "\n")
            }
        } else {
            let nextLineOffset = makeTextBufferOffset(col: 0, row: currentRow+1)
            var newLineOffset = nextLineOffset-1
            // See if we are the last line, and there is no newline at the end
            if storage.getPositionAt(offset: nextLineOffset).column != 0 {
                newLineOffset = nextLineOffset
            }
            if p == newLineOffset {
                newLineOffset = nextLineOffset
            }
            if p != nextLineOffset {
                let deletedText = storage.getValueInRange(range: Range.from (start: p, end: newLineOffset, on: storage))
                storage.delete(offset: p, count: newLineOffset-p)
                
                if let rest = String(bytes: deletedText, encoding: .utf8) {
                    if (lastWasKill) {
                        appendClipboard (text: rest)
                    } else {
                        setClipboard (text: rest)
                    }
                }
            }
        }
        isDirty = true
        needDisplayToEnd(row: currentRow)
        lastWasKill = true
    }
    
    /// Pastes the contents of the clipboard
    public func emacsYank () {
        insert (text: Clipboard.contents)
    }
    
    /// Sets the mark
    public func setMark () {
        selecting = true
        selectionStartColumn = currentColumn
        selectionStartRow = currentRow
    }
    
    /// Copies the contents between the mark and the cursor into the clipboard (The copy selection operation)
    public func emacsKillRingSave () {
        setClipboard(text: getRegion())
        selecting = false
    }
    
    /// Copies the contents between the mark and the cursor into the clipboard, and removes that region from the text (the cut selection operation)
    public func emacsKillRegion () {
        setClipboard(text: getRegion ())
        if !isReadOnly {
            isDirty = true
            clearRegion ()
        }
        selecting = false
    }
    
    /// Inserts the specified character at the current cursor position
    public func insert (character: Character) {
        if isReadOnly {
            return
        }
        let row = currentRow
        
        isDirty = true

        let start = storage.getPositionAt(offset: cursorOffset ())
        insert(utf8: [UInt8](character.utf8))
        let end = storage.getPositionAt(offset: cursorOffset ())
        textEdit (TextRange (start: start, end: end), String (character))

        if currentColumn >= leftColumn + frame.width {
            leftColumn += 1
            setNeedsDisplay()
        } else {
            if currentRow != row {
                needDisplayToEnd(row: row)
            } else {
                needDisplay(row: currentRow)
            }
        }
    }
    
    /// Moves the cursor one word backwards
    public func backwardWord () {
        if let newPos = wordBackward (fromCol: currentColumn, andRow: currentRow) {
            currentColumn = newPos.col;
            currentRow = newPos.row;
        }
        adjust ();
    }
    
    /// Moves the cursor one word forward
    public func forwardWord () {
        if let newPos = wordForward (fromCol: currentColumn, andRow: currentRow) {
            currentColumn = newPos.col
            currentRow = newPos.row
        }
        adjust ()
    }
    
    /// Moves the cursor to the end of the buffer
    public func endOfBuffer () {
        currentRow = storage.getLineCount()-1
        adjust()
        gotoEndOfLine()
        setNeedsDisplay()
    }
    
    /// Moves the cursor to the beginning of the buffer
    public func beginningOfBuffer () {
        currentRow = 0
        currentColumn = 0
        adjust()
    }
    
    open override func processKey(event: KeyEvent) -> Bool {
        // Handle some state here - whether the last command was a kill
        // operation and the column tracking (up/down)
        switch event.key {
        case .controlN, .cursorDown, .controlP, .cursorUp:
            lastWasKill = false
        case .controlK:
            break
        default:
            lastWasKill = false
            columnTrack = -1
        }
        
        // Dispatch the command
        switch event.key {
        case .pageDown, .controlV:
            pageDown ()

        case .pageUp,
             .letter ("v") where event.isAlt:
            pageUp ()
            
        case .controlN, .cursorDown:
            nextLine ()
            
        case .controlP, .cursorUp:
            previousLine ()
            
        case .controlF, .cursorRight:
            forwardCharacter ()
            
        case .controlB, .cursorLeft:
            backwardCharacter ();
            
        case .controlI:
            insert (character: "\t")
        case .delete:
            deleteBackwardCharacter()

        case .controlA, .home:
            moveBeginningOfLine ()
            
        case .deleteChar, .controlD:
            deleteCharacter ()

        case .end, .controlE:
            gotoEndOfLine ()
            
            // kill to end
        case .controlK:
            emacsKillToEndOfLine()

            // yank
        case .controlY:
            emacsYank ()
            
        case .controlSpace:
            setMark ()
            
        case .letter("w") where event.isAlt:
            emacsKillRingSave ()
            
        case .controlW:
            emacsKillRegion ()
            
        case .letter("b") where event.isAlt:
            backwardWord ()
            
        case .letter("f") where event.isAlt:
            forwardWord ()

            // Return key
        case Key.controlJ:
            insert(character: "\n")
            
        case .letter (">") where event.isAlt:
            endOfBuffer ()
            
        case .letter("<") where event.isAlt:
            beginningOfBuffer ()

        case let .letter(x):
            insert (character: x)
            
        default:
            return false
        }
        return true
    }
    
    func gotoEndOfLine ()
    {
        currentColumn = textBufferSize(getCurrentLine())
        let pcol = leftColumn
        leftColumn = currentColumn - frame.width + 1
        if leftColumn < 0 {
            leftColumn = 0
        }
        if pcol != leftColumn {
            setNeedsDisplay()
        }
    }
    
    // Helper routines to scan the text buffer, it keeps a cache to prevent going
    // every time to the textbuffer to fetch a whole line and convert it to text+size
    class Scanner {
        var host: TextView
        var buffer: TextBuffer = []
        var row: Int
        var oldCol, oldRow: Int
        
        init (host: TextView) {
            self.host = host
            row = -1
            oldCol = -1
            oldRow = -1
        }
        
        func fetchRow (row: Int) {
            if self.row != row {
                buffer = host.getTextBuffer(forLine: row)
                self.row = row
            }
        }
        
        func getCell (col: Int, row: Int) -> (ch:Character,size:Int8)? {
            fetchRow (row: row)
            if col < buffer.count {
                return buffer [col]
            } else {
                return nil
            }
        }
        
        func movePrev (_ col: inout Int, _ row: inout Int, _ ch: inout Character) -> Bool {
            oldCol = col
            oldRow = row
            if col > 0 {
                col -= 1
                if let cell = getCell (col: col, row: row) {
                    ch = cell.ch
                    return true
                }
                abort()
            }
            if row == 0 {
                ch = " "
                return false
            }
            while row > 0 {
                row -= 1
                fetchRow (row: row)
                col = buffer.count - 1
                if col >= 0 && buffer.count != 0 {
                    ch = buffer [col].ch
                    return true
                }
            }
            ch = " "
            return false
        }
        
        func moveNext (_ col: inout Int, _ row: inout Int, _ ch: inout Character) -> Bool {
            oldCol = col
            oldRow = row
            fetchRow(row: row)
            
            if col + 1 < buffer.count {
                col += 1
                ch = buffer [col].ch
                return true
            }
            let lineCount = host.storage.lineCount
            while row + 1 < lineCount {
                col = 0;
                row += 1
                fetchRow(row: row)
                if buffer.count > 0 {
                    ch = buffer [0].ch
                    return true
                }
            }
            ch = " "
            return false
        }
    }
    
    func wordBackward (fromCol: Int, andRow: Int) -> (col: Int, row: Int)?
    {
        if andRow == 0 && fromCol == 0 {
            return nil
        }
        var col = fromCol
        var row = andRow
        let scanner = Scanner(host: self)
        var ch: Character = " "
        scanner.movePrev(&col, &row, &ch)
        
        if ch.isPunctuation || ch.isSymbol || ch.isWhitespace {
            while scanner.movePrev (&col, &row, &ch){
                if ch.isLetter || ch.isNumber {
                    break
                }
            }
            while scanner.movePrev (&col, &row, &ch) {
                if !(ch.isLetter || ch.isNumber) {
                    break
                }
            }
        } else {
            while scanner.movePrev (&col, &row, &ch) {
                if !(ch.isLetter || ch.isNumber) {
                    break
                }
            }
        }
        (col, row) = (scanner.oldCol, scanner.oldRow)
        
        if fromCol != col || andRow != row {
            return (col, row)
        }
        return nil
    }
    
    func wordForward (fromCol: Int, andRow: Int) -> (col: Int, row: Int)?
    {
        var col = fromCol
        var row = andRow
        let scanner = Scanner (host: self)
        var ch = scanner.getCell (col: col, row: row)?.ch ?? " "
        
        if ch.isPunctuation || ch.isWhitespace  {
            while scanner.moveNext (&col, &row, &ch) {
                if ch.isLetter || ch.isNumber {
                    break
                }
            }
            while scanner.moveNext (&col, &row, &ch) {
                if !(ch.isLetter || ch.isNumber){
                    break
                }
            }
        } else {
            while scanner.moveNext (&col, &row, &ch) {
                if !(ch.isLetter || ch.isNumber) {
                    break
                }
            }
        }
        if fromCol != col || andRow != row {
            return (col, row)
        }
        return nil
    }
    
    open override func mouseEvent(event: MouseEvent) -> Bool {
        if !event.flags.contains(MouseFlags.button1Clicked) {
            return false
        }
        if !hasFocus {
            superview?.setFocus(self)
        }
        let maxCursorPositionableLine = (storage.lineCount - 1) - topRow
        if event.pos.y > maxCursorPositionableLine {
            currentRow = maxCursorPositionableLine
        } else {
            currentRow = event.pos.y + topRow
        }
        let r = getCurrentLine ()
        if event.pos.x - leftColumn >= r.count {
            currentColumn = r.count - leftColumn
        } else {
            currentColumn = event.pos.y - leftColumn
        }
        
        positionCursor ()
        return true
    }
}
