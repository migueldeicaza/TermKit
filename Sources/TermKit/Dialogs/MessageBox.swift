//
//  MessageBox.swift
//  TermKit
//
//  Created by Miguel de Icaza on 4/28/19.
//  Copyright © 2019 Miguel de Icaza. All rights reserved.
//

import Foundation
import OpenCombine

/**
 * Message box displays a modal message to the user, with a title, a message and a series of options that the user can choose from.
 *
 * There are a couple of options:
 * - `query` is used to show a message with buttons
 * - `error` is similar to query, but uses the error color scheme for the dialogs
 * - `info` merely takes a title and message, it is informational only, so the button "ok" is added
 *
 * The following example pops up a Message Box with 50 columns, and 7 lines, with the specified title and text, plus two buttons.
 * The value -1 is returned when the user cancels the dialog by pressing the ESC key.
 *
 * ```
 *
 *
 * ```
 */
public class MessageBox {
    
    /**
     * Displays a message modally with the specified list of buttons.
     *
     * This displays a message box with the provided title, message as well as a list of strings for
     * the buttons.   It optionally can take a width and height, if those are not provided, they will
     * be computed.
     *
     * - Parameter title: the title for the dialog box
     * - Parameter message: the message to display inside the dialog box, it can contain multiple lines
     * - Parameter buttons: an array of strings that will be used for the buttons.   The first uppercase letter in each button becomes the hotkey
     * - Parameter width: optional desired width, if not specified, this is auto-computed
     * - Parameter height: optional desired heigh, if not specified, this is auot-computed
     *
     * - Returns: the index of the button selected, or -1 if the user pressed the ESC key.
     */
    public static func query (_ title: String, message: String, buttons: [String], width: Int? = nil, height: Int? = nil) -> Int
    {
        return query(title, message: message, buttons: buttons, useErrorColors: false)
    }

    /**
     * Displays an error message modally with the specified list of buttons.
     *
     * This displays a message box with the provided title, message as well as a list of strings for
     * the buttons.   It optionally can take a width and height, if those are not provided, they will
     * be computed.
     *
     * - Parameter title: the title for the dialog box
     * - Parameter message: the message to display inside the dialog box, it can contain multiple lines
     * - Parameter buttons: an array of strings that will be used for the buttons.   The first uppercase letter in each button becomes the hotkey
     * - Parameter width: optional desired width, if not specified, this is auto-computed
     * - Parameter height: optional desired heigh, if not specified, this is auot-computed
     *
     * - Returns: the index of the button selected, or -1 if the user pressed the ESC key.
     */
    public static func error (_ title: String, message: String, buttons: [String], width: Int? = nil, height: Int? = nil) -> Int
    {
        return query(title, message: message, buttons: buttons, useErrorColors: true)
    }
    
    /**
     * Displays an informational message with the specified title
     * It optionally can take a width and height, if those are not provided, they will
     * be computed.
     * - Parameter title: the title for the dialog box
     * - Parameter message: the message to display inside the dialog box, it can contain multiple lines
     * - Parameter width: optional desired width, if not specified, this is auto-computed
     * - Parameter height: optional desired heigh, if not specified, this is auot-computed
     */
    public static func info (_ title: String, message: String, width: Int? = nil, height: Int? = nil)
    {
        let _ = query(title, message: message, buttons: ["Ok"], useErrorColors: false)
    }

    static func query (_ title: String, message: String?, buttons: [String], width: Int? = nil, height: Int? = nil, useErrorColors: Bool) -> Int
    {
        let textWidth = Label.maxWidth(text: message ?? "", width: width ?? INTPTR_MAX)
        var clicked = -1
        var count = 0
        var realWidth, realHeight : Int
        
        let border = 4
        
        if width == nil {
            realWidth = max (Label.maxWidth(text: title) + 2 + border, Label.maxWidth (text: message ?? "") + border + 2)
        } else {
            realWidth = width!
        }
        if height == nil {
            var lines = 1
            for c in message ?? "" {
                if c == "\n" {
                    lines += 1
                }
            }
            realHeight = border + lines + 3
        } else {
            realHeight = height!
        }
        let d = Dialog(title: title, width: realWidth, height: realHeight, buttons: [])
        
        var cancellables: [AnyCancellable] = []
        
        for s in buttons {
            let b = Button (s)
            let c = b.clicked.sink { arg in
                clicked = count
                d.running = false
            }
            
            d.addButton(b)
            cancellables.append (c)
            count += 1
        }
        
        if useErrorColors {
            d.colorScheme = Colors.error
        }
        if message != nil {
            let l = Label (message!)
            l.x = Pos.center () - Pos.at (textWidth/2)
            l.y = Pos.at (0)
            
            d.addSubview(l)
        }
        
        Application.run (top: d)
        return clicked
    }
}
