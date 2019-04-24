//
//  TextField.swift
//  TermKit
//
//  Created by Miguel de Icaza on 4/22/19.
//  Copyright © 2019 Miguel de Icaza. All rights reserved.
//

import Foundation

public class TextField : View {
    var point : Int
    var first : Int
    var layoutPending : Bool
    var used : Bool = false
    /// The contents of the text field
    
    // Store the string as an array of characters and the size in cells of each character
    var textBuffer : [(ch:Character,size:Int8)] = []
    public var text : String {
        get {
            return fromTextBuffer ()
        }
        set(value) {
            toTextBuffer (value);
            if point > textBuffer.count {
                point = textBuffer.count
            }
            adjust ()
        }
    }
    
    // Converts the string to the internal representation
    func toTextBuffer (_ str: String)
    {
        textBuffer = []
        var i = 0
        for x in str {
            textBuffer [i] = (x, Int8(x.cellSize()))
            i += 1
        }
    }
    
    // Convert from the internal buffer to a string
    func fromTextBuffer (from: Int = 0, to: Int = -1) -> String
    {
        let end = to == -1 ? textBuffer.count : to
        
        var res = ""
        for x in from..<end {
            let pair = textBuffer [x]
            res.append (pair.ch)
        }
        return res
    }
    
    /// If set, the contents of the entry are masked, used for passwords for example.
    public var secret : Bool = false {
        didSet {
            setNeedsDisplay()
        }
    }
    
    /// Sets or gets the current cursor position.
    public var cursorPosition : Int = 0 {
        didSet {
            point = cursorPosition
            adjust ()
        }
    }
    
    func countCols (_ from: Int, to: Int) -> Int
    {
        var cols = 0
        for x in from..<to {
            cols += Int (textBuffer [x].size)
        }
        return cols
    }
    
    //
    // Adjusts point, and first based on the contents of the buffer
    // Any time point or first are set, call this method to ensure the
    // state is correct, and the display is triggered
    //
    func adjust ()
    {
        layoutPending = false
        if point > textBuffer.count {
            point = textBuffer.count
        }
        if point < 0 {
            point = 0
        }
        if point < first {
            first = point
        }
        let columns = frame.width
        if countCols (first, to: point) > columns {
            var total = 0
            var idx = point
            first = point
            while idx > 0 && (total+1 < columns) {
                total += Int (textBuffer[idx-1].size)
                idx -= 1
            }
            first = idx
        }
        setNeedsDisplay()
    }
    
    public init (initial : String = "")
    {
        layoutPending = true
        point = 0
        first = 0
        
        super.init ()
        text = initial
        canFocus = true
        
        cursorPosition = textBuffer.count
    }
    
    public override var frame : Rect {
        didSet {
            // TODO
            print ("Need to adjust position")
        }
    }
    
    public override func redraw(region: Rect) {
        driver.setAttribute(colorScheme!.focus)
        moveTo(col:0, row: 0)
        
        var col = 0
        let width = frame.width
        let tcount = textBuffer.count
        for idx in first..<tcount {
            let (ch, size) = secret ? ("*", 1) : textBuffer [idx]
            if col + Int(size) < width {
                driver.addStr(String (ch))
            } else {
                break
            }
            col += Int(size)
        }
        for _ in col..<width {
            driver.addStr(" ")
        }
    }
    
    func textChanged ()
    {
        // TODO Raise event
    }
    
    func setClipboard (_ text: String)
    {
        // TODOs
    }
    
    public override func processKey(event: KeyEvent) -> Bool {
        switch event.key {
        case .DeleteChar, .ControlD:
            if textBuffer.count == 0 || textBuffer.count == point {
                return true
            }
            textBuffer.remove (at: point)
            textChanged ()
            
        case .Delete, .ControlH:
            if point == 0 {
                return true
            }
            point = point - 1
            textBuffer.remove (at: point)
            adjust ()
            
        case .ControlA, .Home:
            point = 0
            adjust ()
            
        case .CursorLeft, .ControlB:
            if point > 0 {
                point -= 1
                adjust ()
            }
            
        case .End, .ControlE:
            point = textBuffer.count
            adjust ()
            
        case .CursorRight, .ControlF:
            if point == textBuffer.count {
                break
            }
            point += 1
            adjust ()
            
        case .ControlK: // kill to end
            if point > textBuffer.count {
                return true
            }
            setClipboard (fromTextBuffer(from: point))
            textBuffer.removeLast(textBuffer.count-point)
            adjust ()
            
        case .ControlY: // yank
            // TODO
            break
        default:
            return true
        }
        used = true
        return true
    }
}
