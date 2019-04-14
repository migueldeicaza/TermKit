//
//  Application.swift
//  MiniGui
//
//  Created by Miguel de Icaza on 3/6/19.
//  Copyright © 2019 Miguel de Icaza. All rights reserved.
//

import Foundation
import Darwin.ncurses

class SizeError : Error {

}


public class Application {
    public static var shared : Application = Application()
    var _top : Toplevel
    var _current : Toplevel
    var toplevels : [View] = []
    static var debugDrawBounds : Bool = false
    public var top : Toplevel {
        get {
            return _top
        }
    }
    public var current : Toplevel {
        get {
            return _current
        }
    }

    var driver : ConsoleDriver
    
    /**
     * Triggers a refresh of the whole display
     */
    public func refresh ()
    {
        driver.updateScreen ()
        var last : View? = nil
        for var v in toplevels.reversed() {
            v.setNeedsDisplay()
            v.redraw(region: v.bounds)
            last = v
        }
        last?.positionCursor()
        driver.refresh()
    }
    
    init ()
    {
        driver = CursesDriver ()
        _top = Toplevel()
        _current = _top
    }
    
    
}

