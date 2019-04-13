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
    public static var Shared : Application = Application()
    var _top : Toplevel
    var _current : Toplevel
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
    
    init ()
    {
        driver = CursesDriver ()
        _top = Toplevel()
        _current = _top
    }
    
    
}

