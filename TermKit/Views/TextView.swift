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
    
    func remove (_ line: TextBuffer, at: Int)
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
    var topRow : Int32 = 0
    var leftColumn : Int32 = 0
    var currentRow : Int32 = 0
    var currentColumn : Int32 = 0
    var selectionStartColumn : Int32 = 0
    var selectionStartRow : Int32 = 0
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
            let minRow = min (max (min (selectionStartRow, currentRow)-topRow, 0), Int32(frame.height))
            let maxRow = min (max (max (selectionStartRow, currentRow)-topRow, 0), Int32(frame.height))
            
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
    func encodeColRow (col: Int32, row: Int32) -> Int64
    {
        return Int64 ((UInt32(row) << 32) | UInt32(col));
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
    
    /// Returns true if the specified column and row are inside the selection
    func pointInSelection (col: Int, row: Int) -> Bool {
        let (start, end) = getEncodedRegionBounds()
        let q = encodeColRow(col: Int32(col), row: Int32(row))
        return q >= start && q <= end
    }
    
    /// gets the selection as a string
    func getRegion () -> String
    {
        return ""
    }
}
