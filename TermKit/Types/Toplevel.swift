//
//  Toplevel.swift
//  TermKit
//
//  Created by Miguel de Icaza on 4/12/19.
//  Copyright © 2019 Miguel de Icaza. All rights reserved.
//

import Foundation

/**
 * Toplevel views can be modally executed.
 *
 * Toplevels can be modally executing views, and they return control
 * to the caller when the `running` property is set to false, or
 * by calling `Application.requestStop`
 *
 * There will be a toplevel created for you on the first time use
 * and can be accessed from the property `Application.top`
 * but new toplevels can be created and ran on top of it.   To run, create the
 * toplevel and then invoke `Application.run with the
 * new toplevel.
 */
open class Toplevel : View {
    var _running : Bool
    /// This flag is checked on each iteration of the mainloop and it continues running until this flag is set to false.
    public var Running : Bool {
        get {
            return _running
        }
    }
    
    /// Initializes a new instance of the Toplevel, class with Computed layout, defaulting to full screen dimensions.
    public override init()
    {
        _running = false
        super.init ()
    
        colorScheme = Colors.base
        width = Dim.fill()
        height = Dim.fill ()
    }
    
    /// Convenience factory method that creates a new toplevel with the current terminal dimensions.
    public static func create () -> Toplevel
    {
        let t = Toplevel()
        t.x = Pos.at(0)
        t.y = Pos.at(0)
        t.width = Dim.fill ()
        t.height = Dim.fill ()
        return t
    }
    
    public override var canFocus: Bool {
        get {
            return true
        }
        set (value){
            super.canFocus = value
        }
    }
    
    public override func processKey(event: KeyEvent) -> Bool {
        if super.processKey(event: event) {
            return true
        }
        switch (event.key){
        case .ControlC:
            // TODO: stop current execution of container
            break
        case .ControlZ:
            driver.suspend ()
            return true
        default:
            break
        }
        return false
    }
}
