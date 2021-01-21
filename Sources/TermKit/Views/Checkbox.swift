//
//  Checkbox.swift
//  TermKit
//
//  Created by Miguel de Icaza on 4/22/19.
//  Copyright © 2019 Miguel de Icaza. All rights reserved.
//

import Foundation

/**
 * The Checkbox View shows an on/off toggle that the user can set
 *
 * Example:
 * ```
 * c = Checkbox ("Toggle me")
 * c.x = Pos.at (0)
 * c.y = Pos.at (0)
 * c.width = Dim(30)
 * c.height = Dim (1)
 * ```
 */
public class Checkbox : View {
    var hotPos : Int = -1
    var hotChar : Character? = nil
    
    /// The state of the checkbox.
    public var checked : Bool = false {
        didSet {
            setNeedsDisplay()
        }
    }
    
    public var text : String {
        didSet {
            var i = 0
            hotPos = -1
            hotChar = nil
            for c in text {
                if c.isUppercase {
                    hotPos = i
                    hotChar = c
                    return
                }
                i += c.cellSize()
            }
        }
    }
    
    public init (_ text: String, checked: Bool = false)
    {
        self.text = text
        self.checked = checked
        super.init ()
        self.height = Dim.sized(1)
        canFocus = true
    }
    
    public override func redraw(region: Rect) {
        let painter = getPainter()
        painter.attribute = hasFocus ? colorScheme!.focus : colorScheme!.normal
        painter.goto(col: 0, row: 0)
        painter.add(str: checked ? "[x]" : "[ ]")
        painter.goto (col: 4, row: 0)
        painter.add (str: text)
        if let c = hotChar {
            painter.goto (col: hotPos, row: 0)
            painter.attribute = hasFocus ? colorScheme!.hotFocus : colorScheme!.hotNormal
            painter.add(str: String(c))
        }
    }

    public override func positionCursor() {
        moveTo (col: 1, row: 0)
    }
    
    func toggle ()
    {
        checked.toggle()
        // raise event
        setNeedsDisplay()
    }
    
    public override func processKey(event: KeyEvent) -> Bool {
        switch event.key {
        case .letter(" "):
            toggle ()
            return true
        default:
            return self.processKey(event: event)
        }
    }
    
    public override func mouseEvent(event: MouseEvent) -> Bool {
        if !event.flags.contains(.button1Clicked) {
            return false
        }
        superview?.setFocus(self)
        toggle ()
        return true
    }
    
    public override var debugDescription: String {
        return "Checkbox (\(super.debugDescription))"
    }

}
