//
//  Application.swift
//  MiniGui
//
//  Created by Miguel de Icaza on 3/6/19.
//  Copyright © 2019 Miguel de Icaza. All rights reserved.
//

import Foundation
import Darwin.ncurses

public protocol Driver {
    func Init ();
    var cols : Int { get }
    var rows : Int { get }
}

class CursesDriver : Driver {
    var cols : Int = 0
    var rows : Int = 0
    
    func Init ()
    {
        initscr ()
        start_color()
        noecho()
        curs_set (0)
        init_pair (0, Int16(COLOR_BLACK), Int16(COLOR_GREEN))
        keypad (stdscr, true)
        
        cols = Int (getmaxx (stdscr))
        rows = Int (getmaxy (stdscr))
        
        clear ();
    }
}

class SizeError : Error {

}



open class Toplevel : View {
    var _running : Bool
    public var Running : Bool {
        get {
            return _running
        }
    }
    
    override init()
    {
        _running = false
    }
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

    var driver : Driver
    
    init ()
    {
        driver = CursesDriver ()
        _top = Toplevel()
        _current = _top
    }
    
    
}

