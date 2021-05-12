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
    var topRow: Int = 0
    var leftColumn: Int = 0
    var currentRow: Int = 0
    var currentColumn: Int = 0
    var selectionStartColumn: Int = 0
    var selectionStartRow: Int = 0
    var selecting: Bool = false
    
    /// Indicates readonly attribute of TextView, defaults to false
    public var isReadOnly = false
    
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
    }
    
    /// Returns the current cursor position inside the buffer
    public var cursorPosition: Point {
        get {
            return Point (x: currentColumn, y: currentRow)
        }
    }
    
    public override func positionCursor() {
        if selecting {
            let minRow = min (max (min (selectionStartRow, currentRow)-topRow, 0), frame.height)
            let maxRow = min (max (max (selectionStartRow, currentRow)-topRow, 0), frame.height)
            
            setNeedsDisplay(Rect(x: 0, y: Int(minRow), width: frame.width, height: Int(maxRow)))
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
    
    public override func redraw(region: Rect, painter p: Painter) {
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
            for col in region.left..<right {
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
                p.add (str: String (char))
            }
        }
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
    /// Inserts the provided character at the current cursor location
    func insert (char: Character)
    {
        insert(utf8: [UInt8](char.utf8))
    }
    
    /// Inserts the provided string at the current cursor location
    func insertText(text: String)
    {
        insert (utf8: [UInt8](text.utf8))
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
    
    public override func processKey(event: KeyEvent) -> Bool {
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
        let lineCount = storage.lineCount
        switch event.key {
        case .pageDown, .controlV:
            let nPageDnShift = frame.height - 1
            if currentRow < lineCount {
                if columnTrack == -1 {
                    columnTrack = currentColumn
                }
                currentRow = (currentRow + nPageDnShift) > lineCount ? lineCount : currentRow + nPageDnShift
                if topRow < currentRow - nPageDnShift {
                    topRow = currentRow >= lineCount ? currentRow - nPageDnShift : topRow + nPageDnShift
                    setNeedsDisplay()
                }
                trackColumn()
            }
        case .pageUp,
             .letter ("v") where event.isAlt:
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
        case .controlN, .cursorDown:
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
            
        case .controlP, .cursorUp:
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
            
        case .controlF, .cursorRight:
            let currentLine = getCurrentLine()
            if currentColumn < textBufferSize(currentLine) {
                currentColumn += 1
                if currentColumn >= leftColumn + frame.width {
                    leftColumn += 1
                    setNeedsDisplay()
                }
            } else {
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
            
        case .controlB, .cursorLeft:
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
            
        case .delete:
            if isReadOnly {
                break
            }
            let p = cursorOffset()
            if p < 1 {
                return true
            }
            storage.delete (offset: p-1, count: 1)
            adjustCursor(offset: p-1)
            setNeedsDisplay()
            // TODO: attempt to reduce region to display

        case .controlA, .home:
            currentColumn = 0
            if currentColumn < leftColumn {
                leftColumn = 0
                setNeedsDisplay()
            }
            
        case .deleteChar, .controlD:
            if isReadOnly {
                break
            }
            let p = cursorOffset()
            storage.delete (offset: p, count: 1)
            
            // TODO optimize, depending on how much needs to be redrawn
            setNeedsDisplay()

        case .end, .controlE:
            gotoEndOfLine ()
            
            // kill to end
        case .controlK:
            if isReadOnly {
                break
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
            setNeedsDisplay (Rect (x: 0, y: currentRow - topRow, width: frame.width, height: frame.height))
            lastWasKill = true
            
            // yank
        case .controlY:
            if isReadOnly {
                break
            }
            insertText(text: Clipboard.contents)
            // TODO: add smarts
            setNeedsDisplay()
            selecting = false
            
        case .controlSpace:
            selecting = true
            selectionStartColumn = currentColumn
            selectionStartRow = currentRow
            
        case .letter("w") where event.isAlt:
            setClipboard(text: getRegion())
            selecting = false
            
        case .controlW:
            setClipboard(text: getRegion ())
            if !isReadOnly {
                clearRegion ()
            }
            selecting = false
            
        case .letter("b") where event.isAlt:
            if let newPos = wordBackward (fromCol: currentColumn, andRow: currentRow) {
                currentColumn = newPos.col;
                currentRow = newPos.row;
            }
            adjust ();
            
        case .letter("f") where event.isAlt:
            if let newPos = wordForward (fromCol: currentColumn, andRow: currentRow) {
                currentColumn = newPos.col
                currentRow = newPos.row
            }
            adjust ()

            // Return key
        case Key.controlJ:
            if isReadOnly {
                break
            }
            insert(utf8: [10])
            setNeedsDisplay()
            
        case .letter (">") where event.isAlt:
            currentRow = storage.getLineCount()-1
            adjust()
            gotoEndOfLine()
            setNeedsDisplay()
            
        case .letter("<") where event.isAlt:
            currentRow = 0
            adjust()

        case let .letter(x):
            if isReadOnly {
                break
            }
            insert(char: x)
            if currentColumn >= leftColumn + frame.width {
                leftColumn += 1
                setNeedsDisplay()
            }
            // TODO: bring back smarts
            setNeedsDisplay()
            return true
            
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
    
    public override func mouseEvent(event: MouseEvent) -> Bool {
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
