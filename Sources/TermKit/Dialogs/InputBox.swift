//
//  InputBox.swift
//
//  Created by Miguel de Icaza on 5/5/21.
//

import Foundation

/// Class with a simple method to request data entry
///
/// You call InputBox.request, with at least a title, and the initial text as well as a callback that will be invoked when the data is
/// accepted.  If the user accepts the input, the callback will be invoked with a string value, if the user cancels in any way
/// the callback receives a nil value.
/// 
/// ```
//    InputBox.request ("Printer Device", message: "Please enter the printer device name", text: "/dev/lp") { newValue in
//        if let printerName = newValue {
//            printer.setDevice (printerName)
//        }
/// ```
///
public class InputBox {
    
    /// Requests some data to be entered
    /// - Parameters:
    ///   - title: Title to diusplay
    ///   - message: Optional message to display
    ///   - width: optional desired width, if not specified, this is auto-computed
    ///   - height: optional desired heigh, if not specified, this is auot-computed
    ///   - completion: function to invoke when the user selects a result, it is not nil if there is a value, nil on cancelation.
    ///   - text: Initial text to show
    public static func request (_ title: String, message: String? = nil, width: Int? = nil, height: Int? = nil, text: String, completion: @escaping (_ result: String?) -> ()) {
        let textWidth = Label3.maxWidth(text: message ?? "", width: width ?? INTPTR_MAX)
        var realWidth, realHeight: Int
        
        let border = 4
        
        if width == nil {
            realWidth = min (Application.top.bounds.width-1, max (60, max (Label3.maxWidth(text: title) + 2 + border, Label3.maxWidth (text: message ?? "") + border + 2)))
        } else {
            realWidth = width!
        }
        var lines = 1
        if height == nil {
            for c in message ?? "" {
                if c == "\n" {
                    lines += 1
                }
            }
            realHeight = border + lines + 3
        } else {
            realHeight = height!
        }
        realHeight += 1
        let input = TextField (text)
        
        let ok = Button ("Ok")
        ok.isDefault = true
        ok.clicked = { arg in
            let txt = input.text
            Application.requestStop()
            completion (txt)
        }
        ok.width = Dim.sized(6)
        let cancel = Button ("Cancel")
        cancel.clicked = { arg in
            Application.requestStop()
            completion (nil)
        }
        cancel.width = Dim.sized(10)
        let d = Dialog(title: title, width: realWidth, height: realHeight, buttons: [])
        d.closedCallback = {
            completion (nil)
        }
        input.x = Pos.at (1)
        input.y = Pos.at (lines + 1)
        input.width = Dim.fill(1)

        d.addSubview(input)
        d.addButton(ok)
        d.addButton(cancel)

        if message != nil {
            let l = Label (message!)
            l.x = Pos.center () - Pos.at (textWidth/2)
            l.y = Pos.at (0)
            
            d.addSubview(l)
        }
        
        Application.present (top: d)
    }
}
