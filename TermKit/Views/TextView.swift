//
//  TextView.swift - multi-line text editing
//  TermKit
//
//  Created by Miguel de Icaza on 5/11/19.
//  Copyright © 2019 Miguel de Icaza. All rights reserved.
//

import Foundation

typealias TextBuffer = TextField.TextBuffer
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
    func insert (_ line: TextBuffer, at: Int)
    {
        lines.insert(line, at: at)
    }
    
    func remove (at: Int)
    {
        lines.remove (at: at)
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
    
    /// Encodes a column and row into a 64-bit value, useful to compare ranges
    func encodeColRow (col: Int, row: Int) -> Int64
    {
        return Int64 ((UInt32(row) << 32) | UInt32(col));
    }
    
    func decodeColRow (_ encoded: Int64) -> (col: Int, row: Int)
    {
        return (col: Int ((UInt32 (encoded) & 0xffffffff)), row: Int (encoded >> 32))
    }
    
    /// Returns an encoded region start..end (top 32 bits are the row, low32 the column) for the current selection
    func getEncodedRegionBounds () -> (start: Int64, end: Int64) {
        let selection = encodeColRow (col: selectionStartColumn, row: selectionStartRow);
        let point =  encodeColRow (col: currentColumn, row: currentRow)
        
        if (selection > point) {
            return (point, selection)
        } else {
            return (selection, point)
        }
    }
    
    func getEncodedRegionCoords () -> (startCol: Int, startRow: Int, endCol: Int, endRow: Int)
    {
        let (start, end) = getEncodedRegionBounds()
        
        let (sc, sr) = decodeColRow (start)
        let (ec, er) = decodeColRow (end)
        return (sc, sr, ec, er)
    }
    
    /// Returns true if the specified column and row are inside the selection
    func pointInSelection (col: Int, row: Int) -> Bool {
        let (start, end) = getEncodedRegionBounds()
        let q = encodeColRow(col: col, row: row)
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
        var line = model [Int(startCol)]
        
        if startRow == endRow {
            line.removeSubrange(Int(startCol)..<Int(endCol-startCol))
            currentColumn = startCol
            setNeedsDisplay(Rect (x: 0, y: Int(startRow)-Int(topRow), width: frame.width, height: Int(startRow)-Int(topRow)+1))
            return
        }
        line.removeSubrange(Int(startCol)..<(line.count-Int(startCol)))
        var line2 = model [Int(endRow)]
        line += Array (line2 [Int(endCol)...])
        for row in (startRow+1)...endRow {
            model.remove (at: Int (row))
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
        var line = getCurrentLine ()
        line.insert((ch: char, size: Int8(char.cellSize())), at: currentColumn)
        var prow = currentRow - topRow
        setNeedsDisplay (Rect(x: 0, y: prow, width: frame.width, height: prow+1))
    }
    
    /// Inserts the provided string at the current cursor location
    func insertText(text: String)
    {
    
    }
}
