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
    
    typealias TextBuffer = [(ch:Character,size:Int8)]
    
    // Store the string as an array of characters and the size in cells of each character
    var textBuffer : TextBuffer = []
    
    public var text : String {
        get {
            return TextField.fromTextBuffer (textBuffer)
        }
        set(value) {
            textBuffer = TextField.toTextBuffer (value);
            if point > textBuffer.count {
                point = textBuffer.count
            }
            adjust ()
        }
    }
    
    // Converts the string to the internal representation
    static func toTextBuffer (_ str: String) -> TextBuffer
    {
        var textBuffer : TextBuffer = []
        for x in str {
            textBuffer.append((ch: x, size: Int8(x.cellSize())))
        }
        return textBuffer
    }
    
    // Convert from the internal buffer to a string
    static func fromTextBuffer (_ data: TextBuffer, from: Int = 0, to: Int = -1) -> String
    {
        let end = to == -1 ? data.count : to
        
        var res = ""
        for x in from..<end {
            let pair = data [x]
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
    
    /// Initializes the TextField, with the optional initial text
    public init (_ initial : String = "")
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
        Clipboard.contents = text
    }
    
    public override func processKey(event: KeyEvent) -> Bool {
        switch event.key {
        case .DeleteChar, .ControlD:
            if textBuffer.count == 0 || textBuffer.count == point {
                return true
            }
            textBuffer.remove (at: point)
            textChanged ()
            adjust()
            
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
            setClipboard (TextField.fromTextBuffer(textBuffer, from: point))
            textBuffer.removeLast(textBuffer.count-point)
            adjust ()
            
        case .ControlY: // yank
            if Clipboard.contents == "" {
                return true
            }
            let clip = TextField.toTextBuffer(Clipboard.contents)
            if point == textBuffer.count {
                textBuffer = textBuffer + clip
            } else {
                textBuffer = textBuffer [0..<point] + clip + textBuffer [point...]
                point += clip.count
            }
            adjust ()
            
        case .Letter("b") where event.isAlt:
            if let wb = wordBackward (fromPoint: point) {
                point = wb
            }
            adjust ()
            
        case .Letter("f") where event.isAlt:
            if let fw = wordForward(fromPoint: point) {
                point = fw
            }
            adjust()
            
        case let .Letter(x) where event.isAlt == false:
            let kbstr = TextField.toTextBuffer(String (x))
            if used {
                if point == textBuffer.count {
                    textBuffer = textBuffer + kbstr
                } else {
                    textBuffer = textBuffer [0..<point] + kbstr + textBuffer [point...]
                }
                point += 1
            } else {
                textBuffer = kbstr
                first = 0
                point = 1
            }
            adjust ()
            break
            
        // MISSING:
        // Alt-D, Alt-backspace
        // Alt-Y
        // Delete adding to kill-buffer
        
        default:
            return false
        }
        used = true
        return true
    }
    
    subscript (index: Int) -> Character {
        get {
            return textBuffer [index].ch
        }
    }
    
    func isLetterOrDigit (_ c: Character) -> Bool
    {
        return c.isLetter || c.isNumber
    }
    
    func wordForward (fromPoint p : Int) -> Int?
    {
        if p > textBuffer.count {
            return nil
        }
        var i = p
        let pch = self [p]
        if pch.isPunctuation || pch.isWhitespace {
            while i < text.count {
                if isLetterOrDigit (self [i]) {
                    break
                }
                i += 1
            }
            while i < text.count {
                if !isLetterOrDigit(self [i]) {
                    break
                }
                i += 1
            }
        } else {
            while i < text.count {
                if !isLetterOrDigit(self [i]) {
                    break
                }
                i += 1
            }
        }
        if i != p {
            return i
        }
        return nil
    }
    
    func wordBackward (fromPoint p : Int) -> Int?
    {
        var i = p - 1
        if p == 0 || i == 0{
            return nil
        }
        
        let ti = self [i]
        if ti.isPunctuation || ti.isSymbol || ti.isWhitespace {
            while i >= 0 {
                if isLetterOrDigit(self [i]){
                    break
                }
                i -= 1
            }
            while i >= 0 {
                if !isLetterOrDigit(self [i]) {
                    break
                }
                i -= 1
            }
        } else {
            while i >= 0 {
                if !isLetterOrDigit(self [i]){
                    break
                }
                i -= 1
            }
        }
        i += 1
        if i != p {
            return i
        }
        return nil
    }
    
    public override func positionCursor() {
        var col = 0
        for idx in first..<textBuffer.count {
            if idx == point {
                break
            }
            col += Int (textBuffer[idx].size)
        }
        moveTo (col: col, row: 0)
    }
    
    public override func mouseEvent(event: MouseEvent) -> Bool {
        if !event.flags.contains(MouseFlags.button1Clicked) {
            return false
        }
        if !hasFocus {
            superview?.setFocus(self)
        }
        
        // we could also set the cursor position
        point = first + event.x
        if point > text.count {
            point = text.count
        }
        if point < first {
            point = 0
        }
        setNeedsDisplay()
        return true
    }
    
    public override var debugDescription: String {
        return "TextField (\(super.debugDescription))"
    }
}
