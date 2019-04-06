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
}

class CursesDriver : Driver {
    var cols : Int32 = 0
    var rows : Int32 = 0
    
    func Init ()
    {
        initscr ()
        start_color()
        noecho()
        curs_set (0)
        init_pair (0, Int16(COLOR_BLACK), Int16(COLOR_GREEN))
        keypad (stdscr, true)
        
        cols = getmaxx (stdscr)
        rows = getmaxy (stdscr)
        
        clear ();
    }
}

class SizeError : Error {

}


open class View {
    var container : View? = nil
    var focused : View? = nil
    var subViews : [View] = []
    var frame : Rect
    
    class var driver : Driver {
        get {
            return Application.Shared.driver
        }
    }
    
    init ()
    {
        frame = Rect(x:0, y: 0, width: 0, height: 0)
    }
}

open class Toplevel : View {
    var running : Bool
    public var Running : Bool {
        get {
            return running
        }
    }
    
    override init()
    {
        running = false
    }
}

public class Application {
    public static var Shared : Application = Application()
    var top : Toplevel
    var current : Toplevel
    public var Top : Toplevel {
        get {
            return top
        }
    }
    public var Current : Toplevel {
        get {
            return current
        }
    }

    var driver : Driver
    
    init ()
    {
        driver = CursesDriver ()
        top = Toplevel()
        current = top
    }
    
    
}

