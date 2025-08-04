//
//  TextField.swift
//  TermKit
//
//  Created by Miguel de Icaza on 4/22/19.
//  Copyright © 2019 Miguel de Icaza. All rights reserved.
//

import Foundation

/**
 * Single-line text entry `View`
 *
 * This view provides line-editing and mouse support
 */
open class TextField: View {
    // Tracks the current position of the cursor
    var point: Int
    // Tracks the location of the mark (set with control space)
    var mark: Int?
    // The index of the first character displayed on the first cell
    var first: Int
    var layoutPending: Bool
    
    /// Indicates whether the user has used this control since it was created
    public var used: Bool = false
    
    /// If set to true its not allow any changes in the text.
    public var readOnly: Bool = false
    /// The contents of the text field
    
    /// Changed event that is triggered when the text changes, and provides the old text,
    /// for a Combine version of this event, use `textChangedSubject`
    public var textChanged: ((_ source: TextField, _ oldText: String) -> ())? = nil
    typealias TextBuffer = [(ch:Character,size:Int8)]
    
    // Store the string as an array of characters and the size in cells of each character
    var textBuffer: TextBuffer = []
    
    /// Sets or gets the text held by the view.
    public var text: String {
        get {
            return TextField.fromTextBuffer (textBuffer)
        }
        set(value) {
            let oldText = TextField.fromTextBuffer (textBuffer)
            textBuffer = TextField.toTextBuffer (value);
            raiseTextChanged(old: oldText)
            
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
    public var secret: Bool = false {
        didSet {
            setNeedsDisplay()
        }
    }
    
    /// Sets or gets the current cursor position.
    public var cursorPosition: Int = 0 {
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
        if let m = mark, m > textBuffer.count {
            mark = nil
        }
        setNeedsDisplay()
    }
    
    /// Initializes the TextField, with the optional initial text
    public init (_ initial: String = "")
    {
        layoutPending = true
        point = 0
        first = 0
        
        super.init ()
        text = initial
        canFocus = true
        height = Dim.sized(1)
        cursorPosition = textBuffer.count
        wantMousePositionReports = true
    }
    
    open override func resignFirstResponder() -> Bool {
        if Application.mouseGrabView == self {
            Application.ungrabMouse()
        }
        return super.resignFirstResponder ()
    }
    
    open override var frame: Rect {
        didSet {
            adjust()
        }
    }
    
    open override func redraw(region: Rect, painter p: Painter) {
        p.attribute = colorScheme.focus
        p.goto(col:0, row: 0)
        
        var col = 0
        let width = frame.width
        let tcount = textBuffer.count
        for idx in first..<tcount {
            let (ch, size) = secret ? ("*", 1) : textBuffer [idx]
            if col + Int(size) < width {
                p.add(str: String (ch))
            } else {
                break
            }
            col += Int(size)
        }
        for _ in col..<width {
            p.add(str: " ")
        }
    }
    
    func raiseTextChanged (old: String)
    {
        if let cb = textChanged {
            cb (self, old)
        }
    }
    
    func setClipboard (_ text: String)
    {
        Clipboard.contents = text
    }
    
    open override func processKey(event: KeyEvent) -> Bool {
        switch event.key {
        case .deleteChar, .controlD:
            if readOnly || textBuffer.count == 0 || textBuffer.count == point {
                return true
            }
            let old = text
            textBuffer.remove (at: point)
            raiseTextChanged(old: old)
            adjust()
            
        case .delete, .controlH:
            if point == 0 || readOnly {
                return true
            }
            point = point - 1
            let old = text
            textBuffer.remove (at: point)
            raiseTextChanged(old: old)
            adjust ()
            
        case .controlA, .home:
            point = 0
            adjust ()

        case .shiftCursorLeft:
            mark = point
            fallthrough
        case .cursorLeft, .controlB:
            if point > 0 {
                point -= 1
                adjust ()
            }
            
        case .end, .controlE:
            point = textBuffer.count
            adjust ()
            
        case .shiftCursorRight:
            mark = point
            fallthrough
        case .cursorRight, .controlF:
            if point == textBuffer.count {
                break
            }
            point += 1
            adjust ()
            
        case .controlK: // kill to end
            if readOnly || point > textBuffer.count {
                return true
            }
            let old = text
            setClipboard (TextField.fromTextBuffer(textBuffer, from: point))
            textBuffer.removeLast(textBuffer.count-point)
            raiseTextChanged(old: old)
            mark = point
            adjust ()
            
        // Windows/Linux: control-v (paste)
        // Emacs: Control-y (yank)
        case .controlV, .controlY: // yank
            if readOnly || Clipboard.contents == "" {
                return true
            }
            let clip = TextField.toTextBuffer(Clipboard.contents)
            let old = text
            if point == textBuffer.count {
                textBuffer = textBuffer + clip
            } else {
                textBuffer = textBuffer [0..<point] + clip + textBuffer [point...]
            }
            point += clip.count
            raiseTextChanged(old: old)
            adjust ()
            
        case .letter("b") where event.isAlt:
            if let wb = wordBackward (fromPoint: point) {
                point = wb
            }
            adjust ()
            
        case .letter("f") where event.isAlt:
            if let fw = wordForward(fromPoint: point) {
                point = fw
            }
            adjust()
            
        case .controlSpace:
            mark = point
            
        // Windows/Linux: Control-C
        // Emacs: Alt-W
        case .letter("w") where event.isAlt,
             .controlC:
            if let m = mark {
                let start = min (m, point)
                let end = max (m, point)
                setClipboard(TextField.fromTextBuffer(Array (textBuffer [start..<end])))
            }

            
        // Windows/Linux: Control-X
        // Emacs: Control-X
        case .controlX, .controlW:
            if readOnly {
                return true
            }
            if let m = mark {
                let start = min (m, point)
                let end = max (m, point)
                let old = text
                setClipboard(TextField.fromTextBuffer(Array (textBuffer [start..<end])))
                textBuffer = Array (textBuffer [0..<start] + textBuffer [end...])
                mark = start
                point = start
                raiseTextChanged(old: old)
                adjust()
            }
            
        case let .letter(x) where event.isAlt == false:
            if readOnly {
                return true
            }
            let kbstr = TextField.toTextBuffer(String (x))
            let old = text
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
            raiseTextChanged(old: old)
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
    
    open override func positionCursor() {
        var col = 0
        for idx in first..<textBuffer.count {
            if idx == point {
                break
            }
            col += Int (textBuffer[idx].size)
        }
        moveTo (col: col, row: 0)
    }
    
    open override func mouseEvent(event: MouseEvent) -> Bool {
        if !event.flags.contains(MouseFlags.button1Clicked) {
            return false
        }
        if !hasFocus {
            superview?.setFocus(self)
        }
        
        // we could also set the cursor position
        point = first + event.pos.x
        if point > text.count {
            point = text.count
        }
        if point < first {
            point = 0
        }
        setNeedsDisplay()
        return true
    }
    
    open override var debugDescription: String {
        return "TextField (\(super.debugDescription))"
    }
}
