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
        lines [atLine].removeSubrange (fromCol..<(lastCol-fromCol))
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
    
    override init (frame: Rect)
    {
        super.init(frame: frame)
        canFocus = true
    }
    
    override init ()
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
    
    /// Clears a region of the view with spaces
    func clearRegion (left:Int, top: Int, right: Int, bottom: Int)
    {
        for row in top..<bottom {
            moveTo(col: left, row: row)
            for _ in left..<right {
                addRune(driver.space)
            }
        }
    }
    
    func colorNormal ()
    {
        driver.setAttribute(colorScheme!.normal)
    }
    
    func colorSelection ()
    {
        driver.setAttribute(hasFocus ? colorScheme!.focus : colorScheme!.normal)
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
        var line2 = model [Int(endRow)]
        
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
    
    public override func redraw(region: Rect) {
        colorNormal()
        let bottom = region.bottom
        let right = region.right
        
        for row in region.top ..< bottom {
            let textLine = Int(topRow) + row
            if textLine > model.count {
                colorNormal()
                clearRegion(left: region.left, top: row, right: region.right, bottom: row+1)
                continue
            }
            var line = model [textLine]
            let lineRuneCount = line.count
            
            // Works-ish, this needs to be replaced with actual rune counts at the specific position
            if line.count < region.left {
                clearRegion(left: region.left, top: row, right: region.right, bottom: row+1)
                continue
            }
            moveTo (col: region.left, row: row)
            for col in region.left..<right {
                let lineCol = leftColumn + col
                let char = lineCol >= lineRuneCount ? " " : line [lineCol].ch
                if selecting && pointInSelection(col: col, row: row){
                    colorSelection()
                } else {
                    colorNormal()
                }
                addChar(char)
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
        var lines = TextModel.stringToTextBufferArray(text: text)
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
        var column = 0
        for i in 0..<lastp {
            column += Int (last [i].size)
        }
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
        case .ControlN, .CursorDown, .ControlP, .CursorUp:
            lastWasKill = false
        case .ControlK:
            break
        default:
            lastWasKill = false
            columnTrack = -1
        }
        
        // Dispatch the command
        switch event.key {
        case .PageDown, .ControlV:
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
        case .PageUp, .Letter ("v") where event.isAlt:
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
        case .ControlN, .CursorDown:
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
        case .ControlP, .CursorUp:
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
            
        // Next up: ControlF
        default:
            break
        }
        return true
    }
}
