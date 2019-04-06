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


open class View {
    var superView : View? = nil
    var focused : View? = nil
    var subViews : [View] = []
    var _frame : Rect = Rect.zero
    var id : String = ""
    var needDisplay : Rect = Rect.zero
    var _childNeedsDisplay : Bool = false
    var canFocus : Bool = false
    var layoutNeeded : Bool = true
    
    var driver : Driver {
        get {
            return Application.Shared.driver
        }
    }
    
    init ()
    {
        frame = Rect(x:0, y: 0, width: 0, height: 0)
    }
    
    var WantMousePositionReports : Bool = false
    
    var frame : Rect {
        get {
            return _frame
        }
        
        set (value){
            if let parent = superView {
                parent.setNeedsDisplay (_frame)
                parent.setNeedsDisplay (value)
            }
            _frame = value
            setNeedsLayout ()
            setNeedsDisplay (frame)
        }
    }
    
    var bounds : Rect {
        get {
            return Rect (origin: Point.Zero, size: frame.size)
        }
    }
    
    public func setNeedsDisplay ()
    {
        setNeedsDisplay(bounds)
    }
    
    public func setNeedsDisplay (_ region : Rect)
    {
        if needDisplay.isEmpty {
            needDisplay = region
        } else {
            let x = min (needDisplay.minX, region.minX)
            let y = min (needDisplay.minY, region.minY)
            let w = max (needDisplay.maxX, region.maxX)
            let h = max (needDisplay.maxY, region.maxY)
            needDisplay = Rect (x: x, y: y, width: w, height: h)
        }
        
        if let container = superView {
            container.childNeedsDisplay ()
        }
        if subViews.count == 0 {
            return
        }
        
        for view in subViews {
            if view.frame.interescts(region){
                var childRegion = view.frame.intersection(region)
                childRegion.origin.x -= view.frame.minX
                childRegion.origin.y -= view.frame.minY
                view.setNeedsDisplay (childRegion)
            }
        }
    }
    
    func setNeedsLayout ()
    {
        if layoutNeeded {
            return
        }
        layoutNeeded = true
        if let container = superView {
            container.layoutNeeded = true
        }
    }
    
    public func childNeedsDisplay ()
    {
        _childNeedsDisplay = true
        if let container = superView {
            container.childNeedsDisplay()
        }
    }
    
    public func addSubview (_ view : View)
    {
        subViews.append (view)
        view.superView = self
        if view.canFocus {
            canFocus = true
        }
        setNeedsLayout()
    }
    
    public func addSubviews (_ views : [View])
    {
        for view in views {
            addSubview(view)
        }
    }
    
    public func remove (view : View)
    {
    
    }
    
    public func removeAllSubviews ()
    {
        
    }
    
    public func Clear ()
    {
        // TODO
    }
    
    func viewToScreen (col: Int, row : Int, clipped : Bool = true) -> (rcol : Int, rrow : Int)
    {
        // Computes the real row, col relative to the screen.
        var rrow = row + frame.minY
        var rcol = col + frame.minX
        var ccontainer = superView
        while ccontainer != nil {
            rrow += ccontainer!.frame.minY
            rcol += ccontainer!.frame.minX
            ccontainer = ccontainer?.superView
        }
        
        // The following ensures that the cursor is always in the screen boundaries
        if clipped {
            rrow = max (0, min (rrow, driver.rows-1))
            rcol = max (0, min (rcol, driver.cols-1))
        }
        return (rcol, rrow)
    }
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

