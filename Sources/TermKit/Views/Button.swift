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
 * Provides a button that can be clicked, or pressed with the enter key or space key.
 * It also responds to hotkeys (the first uppercase letter in the button becomes
 * the hotkey) and triggers the execution of a callback method.
 *
 * If the button is configured as the default `IsDefault` the button
 * will respond to the return key is no other view processes it, and
 * turns this into a clicked event.
 *
 * To connect a clicked handler, set the `clicked` property here to your callback
 *
 * ```
 * var d = Dialog("Hello")
 * var ok = Button ("Ok")
 * ok.clicked = { d.running = false }
 * d.addButton (ok)
 * Application.run (d)
 * ```
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
    
    /**
     * The text displayed by the button.  The first uppercase letter in the button becomes the hotkey
     */
    public var text : String = "" {
        didSet {
            update ()
        }
    }
    
    /**
     * Assigning to this variable a method will invoke it when the button is caviated
     */
    public var clicked : () -> Void = {}

    public override init ()
    {
        super.init ()
        canFocus = true
    }
    
    /**
     * Initializes a button with the text contained in the first parameter, the first uppercase letter by convention is the hotkey
     *
     * - Parameter text: Contains the text for the button.   The first uppercase letter in the button becomes the hotkey
     */
    public convenience init (_ text : String)
    {
        self.init ()
        self.text = text
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
    
    func raiseClicked ()
    {
        clicked ()
    }
    
    func checkKey (_ event: KeyEvent) -> Bool {
        if let hk = hotKey {
            switch event.key {
            case let .Letter(ch) where ch == hk:
                superview?.setFocus(self)
                raiseClicked ()
                return true
            default:
                break
            }
        }
        return false
    }
    
    //
    // This makes is so that Alt-hotletter behaves as activating the button
    //
    public override func processHotKey(event: KeyEvent) -> Bool {
        if event.isAlt {
            return checkKey (event)
        }
        return false
    }
    
    //
    // This is processed last, handles the return key after all other views
    // have processed their events, so we only handle return if this is the
    // default button.
    //
    public override func processColdKey(event: KeyEvent) -> Bool {
        if isDefault {
            switch event.key {
            case .ControlJ:
                raiseClicked()
                return true
            default:
                break
            }
        }
        return super.processColdKey(event: event)
    }
    
    //
    // Space or return while the button is focused activates the button
    //
    public override func processKey(event: KeyEvent) -> Bool {
        switch event.key {
        case .ControlJ, .Letter(" "):
            raiseClicked()
            return true;
        default:
            break
        }
        return super.processKey (event: event)
    }
    
    public override func mouseEvent(event: MouseEvent) -> Bool {
        if (event.flags == .button1Clicked){
            super.setFocus(self)
            setNeedsDisplay()
            raiseClicked()
            return true
        }
        return false
    }
    
    public override var debugDescription: String {
        return "Button (\(super.debugDescription), text=\(text)))"
    }
}
