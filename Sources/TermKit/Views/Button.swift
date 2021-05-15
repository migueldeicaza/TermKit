//
//  Button.swift - Implements a clickable button
//  TermKit
//
//  Created by Miguel de Icaza on 4/21/19.
//  Copyright © 2019 Miguel de Icaza. All rights reserved.
//

import Foundation
import OpenCombine

/**
 * Button is a view that provides an item that invokes a callback when activated.
 *
 * Provides a button that can be clicked, or pressed with the enter key or space key.
 * It also responds to hotkeys (the first letter after an underscore) and triggers
 * the execution of a callback method.
 *
 * If the button is configured as the default `IsDefault` the button
 * will respond to the return key is no other view processes it, and
 * turns this into a clicked event.
 *
 * To connect a clicked handler, set the `clicked` property here to your callback
 *
 * ```
 * var d = Dialog("_Hello")
 * var ok = Button ("Ok")
 * ok.clicked = { d.requestStop () }
 * d.addButton (ok)
 * Application.run (d)
 * ```
 */
open class Button: View {
    
    var shownText: String = ""
    var hotKey: Character? = nil
    var hotPos: Int = 0
    
    /// When a button is the default, pressing return in the dialog will trigger this button if no other control consumes it
    public var isDefault: Bool = false {
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
     * Assigning to this variable a method will invoke it when the button is clicked,
     * alternatively, you can use clickedSubject for use with Combine
     */
    public var clicked: ((_ source: Button) -> ())? = nil
    
    /// Subject that is raised when the button has been activated, a more comprehensive
    /// version of the "clicked' callback
    public var clickedSubject = PassthroughSubject<View,Never> ()

    public override init ()
    {
        super.init ()
        self.height = Dim.sized(1)
        canFocus = true
    }
    
    /// Initializes a button with the text contained in the first parameter, the first uppercase letter by convention is the hotkey
    /// - Parameters:
    ///   - text: Contains the text for the button.   The first uppercase letter in the button becomes the hotkey
    ///   - clicked: Optional method to invoke when the button is clicked
    public convenience init (_ text: String, clicked: (()->())? = nil)
    {
        self.init ()
        self.text = text
        self.clicked = { x in
            if let c = clicked { c () }
        }
        update()
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
        for x in 0..<shownText.count {
            let c = shownText [shownText.index(shownText.startIndex, offsetBy: x)]
            
            if c == "_" {
                hotPos = column
                hotKey = shownText [shownText.index(shownText.startIndex, offsetBy: x+1)]
            } else {
                column += c.cellSize()
            }
        }
        if hotPos == -1 {
            hotPos = 2
            hotKey = text.first
        }
        width = Dim.sized(column)
        setNeedsDisplay()
    }
    
    open override func redraw(region: Rect, painter: Painter) {
        painter.attribute = hasFocus ? colorScheme!.focus : colorScheme!.normal
        painter.goto(col: 0, row: 0)
        painter.drawHotString(text: shownText, focused: hasFocus, scheme: colorScheme!)
    }
    
    open override func positionCursor() {
        moveTo (col: hotPos, row: 0)
    }
    
    func raiseClicked ()
    {
        if let c = clicked {
            c (self)
        }
        clickedSubject.send (self)
    }

    //
    // This makes is so that Alt-hotletter behaves as activating the button
    //
    open override func processHotKey(event: KeyEvent) -> Bool {
        if View.eventTriggersHotKey(event: event, hotKey: hotKey) {
            superview?.setFocus(self)
            raiseClicked ()
            return true
        }
        return false
    }
    
    //
    // This is processed last, handles the return key after all other views
    // have processed their events, so we only handle return if this is the
    // default button.
    //
    open override func processColdKey(event: KeyEvent) -> Bool {
        if isDefault {
            switch event.key {
            case .controlJ:
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
    open override func processKey(event: KeyEvent) -> Bool {
        switch event.key {
        case .controlJ, .letter(" "):
            raiseClicked()
            return true;
        default:
            break
        }
        return super.processKey (event: event)
    }
    
    open override func mouseEvent(event: MouseEvent) -> Bool {
        if event.flags == .button1Clicked {
            if canFocus {
                if !hasFocus {
                    superview!.setFocus (self)
                    setNeedsDisplay()
                }
            }
            raiseClicked()
            return true
        }
        return false
    }
    
    open override var debugDescription: String {
        return "Button (\(super.debugDescription), text=\(text)))"
    }
}
