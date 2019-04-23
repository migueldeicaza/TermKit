//
//  Button.swift - Implements a clickable button
//  TermKit
//
//  Created by Miguel de Icaza on 4/21/19.
//  Copyright © 2019 Miguel de Icaza. All rights reserved.
//

import Foundation

/**
 * Button is a view that provides an item that invokes a callback when activated.
 *
 * Provides a button that can be clicked, or pressed with the enter key and
 * processes hotkeys (the first uppercase letter in the button becomes the hotkey).
 *
 * If the button is configured as the default `IsDefault` the button
 * will respond to the return key is no other view processes it, and
 * turns this into a clicked event.
 */
public class Button : View {
    
    var shownText : String = ""
    var hotKey : Character? = nil
    var hotPos : Int = 0
    var isDefault : Bool = false {
        didSet {
            update ()
        }
    }
    var text : String = "" {
        didSet {
            update ()
        }
    }
    
    public override init ()
    {
        super.init ()
        canFocus = true

    }
    
    func update ()
    {
        if isDefault {
            shownText = "[<" + text + ">]"
        } else {
            shownText = "[ " + text + " ]"
        }
        hotPos = -1
        hotKey = nil
        var column = 0
        for c in shownText {
            if c.isUppercase {
                hotKey = c
                hotPos = column
                break;
            }
            column += c.cellSize()
        }
        if hotPos == -1 {
            hotPos = 2
            hotKey = text.first
        }
        setNeedsDisplay()
    }
    
    public override func redraw(region: Rect) {
        driver.setAttribute(hasFocus ? colorScheme!.focus : colorScheme!.normal)
        moveTo (col: 0, row: 0)
        driver.addStr(shownText)
        if let ch = hotKey {
            moveTo (col: hotPos, row: 0)
            driver.addStr(String (ch))
        }
    }
    
    public override func positionCursor() {
        moveTo (col: hotPos, row: 0)
    }
}
