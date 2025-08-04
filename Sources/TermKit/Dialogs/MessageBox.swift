//
//  MessageBox.swift
//  TermKit
//
//  Created by Miguel de Icaza on 4/28/19.
//  Copyright © 2019 Miguel de Icaza. All rights reserved.
//

import Foundation

/**
 * Message box displays a modal message to the user, with a title, a message and a series of options that the user can choose from.
 *
 * There are a couple of options:
 * - `query` is used to show a message with buttons and the user chooses one option from many.
 * - `error` is similar to query, but uses the error color scheme for the dialogs
 * - `info` merely takes a title and message, it is informational only, so the button "ok" is added
 *
 * The following example pops up a Message Box with 50 columns, and 7 lines, with the specified title and text, plus two buttons.
 * The value -1 is returned when the user cancels the dialog by pressing the ESC key.
 *
 * ```
 * MessageBox.query (
 *     "Title",
 *     message: "Explanatory text",
 *     buttons: ["Yes", "No", "Maybe"],
 *     completion: { button in
 *         rememberCount.text = button == -1 ? "User canceled" : "User chose \(button)"
 *     }
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
     * - Parameter buttons: an array of strings that will be used for the buttons.
     *   The first uppercase letter in each button becomes the hotkey
     * - Parameter width: optional desired width, if not specified, this is auto-computed
     * - Parameter height: optional desired heigh, if not specified, this is auot-computed
     * - Parameter completion: function to invoke when the user selects a result, the parameter is
     *   the index of the button selected, or -1 if the user pressed the ESC key
     */
    public static func query (_ title: String, message: String, buttons: [String], width: Int? = nil, height: Int? = nil, completion: @escaping (_ result: Int) -> ())
    {
        query(title, message: message, buttons: buttons, useErrorColors: false, completion: completion)
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
     * - Parameter completion: optional function to invoke when the user selects a result, the parameter is
     *   the index of the button selected, or -1 if the user pressed the ESC key
     */
    public static func error (_ title: String, message: String, buttons: [String], width: Int? = nil, height: Int? = nil, completion: @escaping (_ result: Int) -> () = { v in })
    {
        query(title, message: message, buttons: buttons, useErrorColors: true, completion: completion)
    }
    
    /**
     * Displays an informational message with the specified title
     * It optionally can take a width and height, if those are not provided, they will
     * be computed.
     * - Parameter title: the title for the dialog box
     * - Parameter message: the message to display inside the dialog box, it can contain multiple lines
     * - Parameter width: optional desired width, if not specified, this is auto-computed
     * - Parameter height: optional desired heigh, if not specified, this is auot-computed
     * - Parameter completion: optional function to invoke when the user selects a result, the parameter is
     *   the index of the button selected (0 for OK), or -1 if the user pressed the ESC key
     */
    public static func info (_ title: String, message: String, width: Int? = nil, height: Int? = nil, completion: @escaping (_ result: Int) -> () = { v in })
    {
        query(title, message: message, buttons: ["Ok"], useErrorColors: false, completion: completion)
    }

    static func query (_ title: String, message: String?, buttons: [String], width: Int? = nil, height: Int? = nil, useErrorColors: Bool, completion: @escaping (_ result: Int) -> ())
    {
        let textWidth = Label3.maxWidth(text: message ?? "", width: width ?? INTPTR_MAX)
        var clicked = -1
        var count = 0
        var realWidth, realHeight: Int
        
        let border = 4
        
        if let width {
            realWidth = width
        } else {
            realWidth = max (Label3.maxWidth(text: title) + 2 + border, Label3.maxWidth (text: message ?? "") + border + 2)
        }
        if let height {
            realHeight = height
        } else {
            var lines = 1
            for c in message ?? "" {
                if c == "\n" {
                    lines += 1
                }
            }
            realHeight = border + lines + 3
        }
        let d = Dialog(title: title, width: realWidth, height: realHeight, buttons: [])
        d.closedCallback = {
            completion (-1)
        }
        for s in buttons {
            let b = Button (s)
            b.width = Dim.sized (s.count + 4)
            let idx = count
            b.clicked = { arg in
                clicked = idx
                Application.requestStop()
                completion (clicked)
            }
            
            d.addButton(b)
            count += 1
        }
        
        if useErrorColors {
            d.colorScheme = Colors.error
        }
        if let message {
            let l = Label (message)
            l.x = Pos.center () - Pos.at (textWidth/2)
            l.y = Pos.at (0)
            
            d.addSubview(l)
        }
        
        Application.present (top: d)
    }
}
