//
//  TextView.swift - multi-line text editing
//  TermKit
//
//  Created by Miguel de Icaza on 5/11/19.
//  Copyright © 2019 Miguel de Icaza. All rights reserved.
//

import Foundation

typealias TextBuffer = TextField.TextBuffer
typealias Position = Int64

class TextModel {
    var lines: [TextBuffer]
    
    init ()
    {
        lines = [[]]
    }
    
    /// Converts a string into an array of TextBuffer arrays
    static func stringToTextBufferArray (text: String) -> [TextBuffer]
    {
        var ret: [TextBuffer] = []
        
        let allLines = text.components(separatedBy: "\n")
        for line in allLines {
            let sizedLine = TextField.toTextBuffer(line)
            ret.append(sizedLine)
        }
        return ret
    }
    
    /// Converts an array of TextField.TextBuffers into a string
    static func textBufferArrayToString (textArray: [TextBuffer]) -> String
    {
        var res: String = ""
        for line in textArray {
            let ps = TextField.fromTextBuffer(line)
            res.append(ps)
        }
        return res
    }
    
    /// Loads the file pointed out by path into this TextModel
    func loadFile (path: String) throws
    {
        let all = try String (contentsOfFile: path)
        lines = TextModel.stringToTextBufferArray(text: all)
    }
    
    /// Sets the contents of this TextModel to the contents specified in the text
    func loadString (text: String)
    {
            lines = TextModel.stringToTextBufferArray(text: text)
    }
    
    /// Returns a string representation of this TextModel
    func toString () -> String
    {
        return TextModel.textBufferArrayToString (textArray: lines)
    }
    
    
    /// Number of lines in the model
    var count : Int {
        get {
            return lines.count
        }
    }
    
    /// Returns the specified line from the model
    subscript (line: Int) -> TextBuffer {
        get {
            return lines [line]
        }
    }
    
    /// Adds a line to the model
    func insert (line: TextBuffer, at: Int)
    {
        lines.insert(line, at: at)
    }
    
    func insert (text: TextBuffer, atLine: Int, andCol: Int)
    {
        lines [atLine].insert(contentsOf: text, at: andCol)
    }
    
    /// Inserts the specified character at the given line and column
    func insert (char: Character, atLine: Int, andCol: Int)
    {
        lines [atLine].insert((ch: char, size: Int8(char.cellSize())), at: andCol)
    }
    
    func removeLine (at: Int)
    {
        lines.remove (at: at)
    }
    
    /// Encodes a column and row into a 64-bit position value, useful to compare ranges
    static func toPosition (col: Int, row: Int) -> Position
    {
        return Int64 ((UInt32(row) << 32) | UInt32(col));
    }
    
    static func fromPosition (_ position: Position) -> (col: Int, row: Int)
    {
        return (col: Int ((UInt32 (position) & 0xffffffff)), row: Int (position >> 32))
    }
    
    func removeLineRange (atLine: Int, fromCol: Int, toCol: Int)
    {
        let lastCol = toCol == -1 ? lines [atLine].count : toCol
        lines [atLine].removeSubrange (fromCol..<(lastCol))
    }
    
    func appendText (atLine: Int, txt: TextBuffer)
    {
        lines [atLine] += txt
    }

}

/**
 * Multi-line text editing view
 *
 * The text view provides a multi-line text view.   Users interact
 * with it with the standard Emacs commands for movement or the arrow
 * keys.
 */

public class TextView : View {
    var model: TextModel = TextModel()
    var topRow : Int = 0
    var leftColumn : Int = 0
    var currentRow : Int = 0
    var currentColumn : Int = 0
    var selectionStartColumn : Int = 0
    var selectionStartRow : Int = 0
    var selecting : Bool = false
    
    /// Indicates readonly attribute of TextView, defaults to false
    public var isReadOnly = false
    
    public override init (frame: Rect)
    {
        super.init(frame: frame)
        canFocus = true
    }
    
    public override init ()
    {
        super.init ()
        canFocus = true
    }
    
    func resetPosition ()
    {
        topRow = 0
        leftColumn = 0
        currentColumn = 0
        currentRow = 0
    }
    
    /// Sets or gets the text in the view
    public var text : String {
        get {
            return model.toString()
        }
        set(value) {
            resetPosition()
            model.loadString(text: value)
            setNeedsDisplay()
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
        
        try model.loadFile(path: path)
    }
    
    /// Returns the current cursor position inside the buffer
    public var cursorPosition : (col: Int, row: Int) {
        get {
            return (Int(currentColumn), Int(currentRow))
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
    func getEncodedRegionBounds () -> (start: Int64, end: Int64) {
        let selection = TextModel.toPosition (col: selectionStartColumn, row: selectionStartRow);
        let point =  TextModel.toPosition (col: currentColumn, row: currentRow)
        
        if (selection > point) {
            return (point, selection)
        } else {
            return (selection, point)
        }
    }
    
    func getEncodedRegionCoords () -> (startCol: Int, startRow: Int, endCol: Int, endRow: Int)
    {
        let (start, end) = getEncodedRegionBounds()
        
        let (sc, sr) = TextModel.fromPosition (start)
        let (ec, er) = TextModel.fromPosition (end)
        return (sc, sr, ec, er)
    }
    
    /// Returns true if the specified column and row are inside the selection
    func pointInSelection (col: Int, row: Int) -> Bool {
        let (start, end) = getEncodedRegionBounds()
        let q = TextModel.toPosition(col: col, row: row)
        return q >= start && q <= end
    }
    
    /// gets the selection as a string
    func getRegion () -> String
    {
        let (startCol, startRow, endCol, endRow) = getEncodedRegionCoords()
        let line = model [Int (startRow)]
        if startRow == endRow {
            return TextField.fromTextBuffer(Array (line [Int(startCol)..<Int(endCol)]))
        }
        var res = Array (line [Int(startCol)...])
        let newline = (ch: Character ("\n"), size: Int8(0))
        for row in (startRow+1)..<endRow {
            res.append (newline)
            res = res + model [Int(row)]
        }
        let lastLine = model [Int(endRow)]
        res.append (newline)
        res = res + Array (lastLine [0..<Int(endCol)])
        return TextField.fromTextBuffer(res)
    }
    
    /// clears the contents of the selected region
    func clearRegion ()
    {
        let (startCol, startRow, endCol, endRow) = getEncodedRegionCoords()

        if startRow == endRow {
            model.removeLineRange (atLine: startRow, fromCol: startCol, toCol: Int(endCol))
            
            currentColumn = startCol
            setNeedsDisplay(Rect (x: 0, y: Int(startRow)-Int(topRow), width: frame.width, height: Int(startRow)-Int(topRow)+1))
            return
        }
        model.removeLineRange(atLine: startRow, fromCol: startCol, toCol: -1)
        let line2 = model [Int(endRow)]
        
        model.appendText (atLine: Int(endRow), txt: Array (line2 [Int(endCol)...]))
        
        for row in (startRow+1)...endRow {
            model.removeLine (at: Int (row))
        }
        if currentColumn == endRow && currentRow == endRow {
            currentRow -= endRow - startRow
        }
        currentColumn = startCol
        setNeedsDisplay()
    }
    
    public override func redraw(region: Rect, painter p: Painter) {
        p.colorNormal()
        let bottom = region.bottom
        let right = region.right
        
        for row in region.top ..< bottom {
            let textLine = Int(topRow) + row
            if textLine > model.count {
                p.colorNormal()
                p.clearRegion(left: region.left, top: row, right: region.right, bottom: row+1)
                continue
            }
            let line = model [textLine]
            let lineRuneCount = line.count
            
            // Works-ish, this needs to be replaced with actual rune counts at the specific position
            if line.count < region.left {
                p.clearRegion(left: region.left, top: row, right: region.right, bottom: row+1)
                continue
            }
            moveTo (col: region.left, row: row)
            for col in region.left..<right {
                let lineCol = leftColumn + col
                let char = lineCol >= lineRuneCount ? " " : line [lineCol].ch
                if selecting && pointInSelection(col: col, row: row){
                    p.colorSelection()
                } else {
                    p.colorNormal()
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
        return model [currentRow]
    }
    
    /// Inserts the provided character at the current cursor location
    func insert (char: Character)
    {
        model.insert(char: char, atLine: currentRow, andCol: currentColumn)
        currentColumn += char.cellSize()
        let prow = currentRow - topRow
        setNeedsDisplay (Rect(x: 0, y: prow, width: frame.width, height: prow+1))
    }
    
    /// Inserts the provided string at the current cursor location
    func insertText(text: String)
    {
        let lines = TextModel.stringToTextBufferArray(text: text)
        if lines.count == 0 {
            return
        }
        
        // Optimize single line
        if lines.count == 1 {
            model.insert(text: lines [0], atLine: currentRow, andCol: currentColumn)
            currentColumn += text.cellCount()
            if currentColumn - leftColumn > frame.width {
                leftColumn = currentColumn - frame.width - 1
            }
            setNeedsDisplay(Rect (x: 0, y: currentRow-topRow, width: frame.width, height: currentRow-topRow+1))
            return
        }
        // Keep a copy of the rest of the line
        let line = getCurrentLine()
        let rest = Array (line [currentColumn...])
        model.removeLineRange(atLine: currentRow, fromCol: currentColumn, toCol: line.count)
        
        // first line is inserted at the cursor location, the rest is appended
        model.insert(text: lines [0], atLine: currentRow, andCol: currentColumn)
        for i in 1..<lines.count {
            model.insert(line: lines [i], at: currentRow+i)
        }
        
        let last = model [currentRow+lines.count-1]
        let lastp = last.count
        model.insert (text: rest, atLine: currentRow+lines.count-1, andCol: lastp)
        
        // Now adjust column and line positions
        currentRow += lines.count + 1
        let column = textBufferSize(Array (last [0..<lastp]))
        currentColumn = column
        if currentColumn < leftColumn {
            leftColumn = currentColumn
        }
        if currentColumn - leftColumn >= frame.width {
            leftColumn = currentColumn - frame.width + 1
        }
        setNeedsDisplay()
    }
    
    // The column we are tracking, or -1 if we are not tracking any column
    var columnTrack : Int = -1
    
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
        topRow = rrow > model.count ? model.count-1 : rrow
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
        
        switch event.key {
        case .pageDown, .controlV:
            let nPageDnShift = frame.height - 1
            if currentRow < model.count {
                if columnTrack == -1 {
                    columnTrack = currentColumn
                }
                currentRow = (currentRow + nPageDnShift) > model.count ? model.count : currentRow + nPageDnShift
                if topRow < currentRow - nPageDnShift {
                    topRow = currentRow >= model.count ? currentRow - nPageDnShift : topRow + nPageDnShift
                    setNeedsDisplay()
                }
                trackColumn()
                // positionCursor()
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
                // PositionCursor ();
            }
        case .controlN, .cursorDown:
            if currentRow + 1 < model.count {
                if columnTrack == -1 {
                    columnTrack = currentColumn
                }
                currentRow += 1
                if currentRow >= topRow + frame.height {
                    topRow += 1
                    setNeedsDisplay ()
                }
                trackColumn ();
                // positionCursor ();
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
                // positionCursor ();
            }
            
        case .controlF, .cursorRight:
            let currentLine = getCurrentLine()
            if currentColumn < textBufferSize(currentLine) {
                currentColumn += 1
                if currentColumn >= leftColumn + frame.width {
                    leftColumn += 1
                    setNeedsDisplay()
                }
                // positionCursor()
            } else {
                if currentRow + 1 < model.count {
                    currentRow += 1
                    currentColumn = 0
                    leftColumn = 0
                    if currentRow >= topRow + frame.height {
                        topRow += 1
                    }
                    setNeedsDisplay()
                    //positionCursor()
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
            if currentColumn > 0 {
                // Delete backwards
                model.removeLineRange(atLine: currentRow, fromCol: currentColumn-1, toCol: currentColumn)
                currentColumn -= 1
                if currentColumn < leftColumn {
                    leftColumn -= 1
                    setNeedsDisplay ()
                } else {
                    setNeedsDisplay (Rect (x: 0, y: currentRow - topRow, width: 1, height: frame.width));
                }
            } else {
                // Merges the current line with the previous one.
                if currentRow == 0 {
                    return true;
                }
                let prowIdx = currentRow - 1
                let prevRow = model [prowIdx]
                let prevCount = prevRow.count
                model.appendText(atLine: prowIdx, txt: getCurrentLine())
                model.removeLine(at: currentRow)
                currentRow -= 1
                currentColumn = prevCount
                leftColumn = currentColumn - frame.width + 1
                if (leftColumn < 0) {
                    leftColumn = 0;
                }
                setNeedsDisplay ();
            }
            
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
            let currentLine = getCurrentLine ()
            if currentColumn == currentLine.count {
                if currentRow + 1 == model.count {
                    break;
                }
                model.appendText(atLine: currentRow, txt: model [currentRow + 1])
                model.removeLine(at: currentRow + 1)
                let sr = currentRow - topRow;
                setNeedsDisplay (Rect (x: 0, y: sr, width: frame.width, height: sr + 1));
            } else {
                model.removeLineRange(atLine: currentRow, fromCol: currentColumn, toCol: currentColumn+1)
                let r = currentRow - topRow;
                setNeedsDisplay (Rect (x: currentColumn - leftColumn, y: r, width: frame.width, height: r + 1));
            }

        case .end, .controlE:
            currentColumn = textBufferSize(getCurrentLine())
            let pcol = leftColumn
            leftColumn = currentColumn - frame.width + 1
            if leftColumn < 0 {
                leftColumn = 0
            }
            if pcol != leftColumn {
                setNeedsDisplay()
            }
            
            // kill to end
        case .controlK:
            if isReadOnly {
                break
            }
            let currentLine = getCurrentLine ();
            if currentLine.count == 0 {
                model.removeLine(at: currentRow)
                
                if (lastWasKill) {
                    appendClipboard(text: "\n")
                } else {
                    setClipboard(text: "\n")
                }
            } else {
                let rest = Array (currentLine [currentColumn...])
                
                if (lastWasKill) {
                    appendClipboard (buffer: rest)
                } else {
                    setClipboard (buffer: rest)
                }
                model.removeLineRange(atLine: currentRow, fromCol: currentColumn, toCol: -1)
            }
            setNeedsDisplay (Rect (x: 0, y: currentRow - topRow, width: frame.width, height: frame.height))
            lastWasKill = true
            
            // yank
        case .controlY:
            if isReadOnly {
                break
            }
            insertText(text: Clipboard.contents)
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
        
            let currentLine = getCurrentLine ();
            let rest = Array (currentLine [currentColumn...])
            model.removeLineRange(atLine: currentRow, fromCol: currentColumn, toCol: -1)
            model.insert (line: rest, at: currentRow + 1)
            currentRow += 1
            var fullNeedsDisplay = false
            if currentRow >= topRow + frame.height {
                topRow += 1
                fullNeedsDisplay = true
            }
            currentColumn = 0
            if currentColumn < leftColumn {
                fullNeedsDisplay = true
                leftColumn = 0
            }
            
            if fullNeedsDisplay {
                setNeedsDisplay ()
            } else {
                setNeedsDisplay (Rect (x: 0, y: currentRow - topRow, width: 2, height: frame.height));
            }
            
        case let .letter(x):
            if isReadOnly {
                break
            }
            insert(char: x)
            if currentColumn >= leftColumn + frame.width {
                leftColumn += 1
                setNeedsDisplay()
            }
            return true
            
        default:
            return false
        }
        return true
    }
    
    func moveNext (_ col: inout Int, _ row: inout Int, _ ch: inout Character) -> Bool {
        var line = model [row]
        if col + 1 < line.count {
            col += 1
            ch = line [col].ch
            return true
        }
        while row + 1 < model.count {
            col = 0;
            row += 1
            line = model [row]
            if line.count > 0 {
                ch = line [0].ch
                return true
            }
        }
        ch = " "
        return false;
    }
    
    func movePrev (_ col: inout Int, _ row: inout Int, _ ch: inout Character) -> Bool {
        var line = model [row]
        if col > 0 {
            col -= 1
            ch = line [col].ch
            return true
        }
        if row == 0 {
            ch = " "
            return false
        }
        while row > 0 {
            row -= 1
            line = model [row]
            col = line.count - 1
            if col >= 0 {
                ch = line [col].ch
                return true
            }
        }
        ch = " "
        return false
    }
    
    func wordBackward (fromCol: Int, andRow: Int) -> (col: Int, row: Int)?
    {
        if andRow == 0 || fromCol == 0 {
            return nil
        }
        var col = fromCol
        var row = andRow
        var ch = model [row][col].ch
        
        if ch.isPunctuation || ch.isSymbol || ch.isWhitespace {
            while movePrev (&col, &row, &ch){
                if ch.isLetter || ch.isNumber {
                    break
                }
            }
            while movePrev (&col, &row, &ch) {
                if !(ch.isLetter || ch.isNumber) {
                    break
                }
            }
        } else {
            while movePrev (&col, &row, &ch) {
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
    
    func wordForward (fromCol: Int, andRow: Int) -> (col: Int, row: Int)?
    {
        var col = fromCol;
        var row = andRow
        var ch = model [row][col].ch
        
        if ch.isPunctuation || ch.isWhitespace  {
            while moveNext (&col, &row, &ch) {
                if ch.isLetter || ch.isNumber {
                    break
                }
            }
            while moveNext (&col, &row, &ch) {
                if !(ch.isLetter || ch.isNumber){
                    break
                }
            }
        } else {
            while moveNext (&col, &row, &ch) {
                if !(ch.isLetter || ch.isNumber) {
                    break;
                }
            }
        }
        if (fromCol != col || andRow != row){
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
        let maxCursorPositionableLine = (model.count - 1) - topRow;
        if event.y > maxCursorPositionableLine {
            currentRow = maxCursorPositionableLine;
        } else {
            currentRow = event.y + topRow;
        }
        let r = getCurrentLine ();
        if event.x - leftColumn >= r.count {
            currentColumn = r.count - leftColumn
        } else {
            currentColumn = event.y - leftColumn
        }
        
        positionCursor ()
        return true
    }
}
