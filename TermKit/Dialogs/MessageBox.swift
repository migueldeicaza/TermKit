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
 * The difference between the Query and ErrorQuery method is the default set of colors used for the message box.
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
     *
     */
    public static func query (_ title: String, message: String, buttons: [String], width: Int? = nil, height: Int? = nil, useErrorColors: Bool = false) -> Int
    {
        var l = Label(message)
        return 0
    }
}
