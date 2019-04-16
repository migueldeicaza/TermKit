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

enum ApplicationError : Error {
    case internalState(msg:String)
}

public class Application {
    /// Points to the global application
    public static var shared : Application = Application()
    static var _top : Toplevel = Toplevel()
    static var _current : Toplevel? = nil
    static var toplevels : [Toplevel] = []
    static var debugDrawBounds : Bool = false
    
    /// The Toplevel object used for the application on startup.
    public static var top : Toplevel {
        get {
            return _top
        }
    }
    
    /// The current toplevel object.   This is updated when Application.Run enters and leaves and points to the current toplevel.
    public static var current : Toplevel? {
        get {
            return _current
        }
    }

    /// The current Console Driver in use.
    static var driver : ConsoleDriver = CursesDriver()
    
    /**
     * Triggers a refresh of the whole display
     */
    static public func refresh ()
    {
        driver.updateScreen ()
        var last : View? = nil
        for v in toplevels.reversed() {
            v.setNeedsDisplay()
            v.redraw(region: v.bounds)
            last = v
        }
        last?.positionCursor()
        driver.refresh()
    }
    
    static func processKeyEvent (event : KeyEvent)
    {
        if let c = _current {
            if (c.processHotKey(event: event)) {
                return
            }
            if (c.processKey(event: event)){
                return
            }
            if (c.processColdKey(event: event)) {
                return
            }
        }
    }
    
    static func findDeepestView (start : View, x: Int, y: Int) -> (view: View, resx: Int, resy: Int)?
    {
        let startFrame = start.frame
        
        if startFrame.contains(Point (x: x, y: y)){
            return nil
        }

        let count = start.subViews.count
        if count > 0 {
            let location = Point(x: x - startFrame.minX, y: y - startFrame.minY)
            for i in (0..<(count)).reversed() {
                let v = start.subViews[i]
                if v.frame.contains(location) {
                    let deep = findDeepestView(start: v, x: location.x, y: location.y)
                    if deep == nil {
                        return (view: v, resx: 0, resy: 0)
                    }
                    return deep
                }
            }
        }

        return (view: start, resx: x-startFrame.minX, resy: y-startFrame.minY)
    }
    
    static var rootMouseHandlers : [Int:(MouseEvent)->()] = [:]
    static var lastMouseToken = 0
    
    /**
     * A token representing a registered root mouse handler
     */
    public struct MouseHandlerToken {
        var token : Int
    }
    
    /**
     * Registers a global mouse event handler to be invoked for every mouse event, this
     * is called before any event processing takes place for the currently focused view.
     */
    public static func addRootMouseHandler (_ handler : @escaping (MouseEvent)->()) -> MouseHandlerToken
    {
        let ret = lastMouseToken
        rootMouseHandlers [lastMouseToken] = handler
        lastMouseToken += 1
        return MouseHandlerToken (token: ret)
    }
    
    /**
     * Removes a previously registered mouse event handler
     */
    public static func removeRootMouseHandler (_ token: MouseHandlerToken)
    {
        rootMouseHandlers.removeValue(forKey: token.token)
    }
    
    static func processMouseEvent (mouseEvent : MouseEvent)
    {
        for h in rootMouseHandlers.values {
            h (mouseEvent)
        }
        // TODO: MouseGrabView
        
        let res = findDeepestView(start: _current!, x: mouseEvent.x, y: mouseEvent.y)
        if let r = res {
            if !r.view.wantMousePositionReports && (mouseEvent.flags == MouseFlags.mousePosition) {
                return
            }
            let nme = MouseEvent (x: res!.resx, y: res!.resy, flags: mouseEvent.flags)
            
            // Should we bubble up the event if it not handled?
            r.view.mouseEvent (event: nme)
        }
    }
    
    /**
     * Captures the execution state for the provided toplevel view, in charge of shutting down on last use.
     * Instances of RunState are returned by the `begin` method in application, and used as a token
     * to terminate the execution of an Application by calling `end` on them.
     */
    public class RunState {
        var top : Toplevel?
        init (_ top : Toplevel)
        {
            self.top = top
        }
    
        deinit
        {
            if top != nil {
                do {
                    try Application.end (top!)
                } catch {}
                top = nil
            }
        }
    }
    
    /**
     * Building block API: Prepares the provided toplevel for execution.
     *
     * This method prepares the provided toplevel for running with the focus,
     * it adds this to the list of toplevels, sets up the mainloop to process the
     * event, lays out the subviews, focuses the first element, and draws the
     * toplevel in the screen.   This is usually followed by executing
     * the `RunLoop` method, and then the `End(RunState` method upon termination which
     * will undo these changes
     *
     * - Parameter toplevel: Toplevel to prepare execution for.
     * - Returns: The runstate handle that needs to be passed to the `end` method upon completion
     */
    public static func begin (toplevel : Toplevel) -> RunState
    {
        let rs = RunState(toplevel)
        toplevels.append(toplevel)
        _current = toplevel
        if toplevel.layoutStyle == .computed {
            toplevel.relativeLayout(hostFrame: Rect(x: 0, y: 0, width: driver.cols, height: driver.rows))
        }
        do {
            try toplevel.layoutSubviews()
        } catch {}
        toplevel.willPresent()
        redrawView (toplevel)
        toplevel.positionCursor()
        driver.refresh()
        
        return rs
    }
    
    static func redrawView (_ view: View)
    {
        view.redraw(region: view.bounds)
        driver.refresh()
    }
    
    // Called by RunState when it disposes
    static func end (_ view: View) throws
    {
        if toplevels.last == nil {
            throw ApplicationError.internalState(msg: "The current toplevel is null, and the end callback is being called")
        }
        if toplevels.last! != view {
            throw ApplicationError.internalState(msg: "The current toplevel is not the one that this is being called on")
        }
        toplevels = toplevels.dropLast ()
        if toplevels.count == 0 {
            Application.shutdown ()
        } else {
            _current = toplevels.last as Toplevel?
            refresh ()
        }
    }
    
    static var _mainLoop : MainLoop? = nil
    static public var mainLoop : MainLoop? {
        get {
            return _mainLoop
        }
    }
    /**
     * Building block API: Runs the main loop for the created dialog
     * Use the wait parameter to control whether this is a blocking or non-blocking call.
     * - Parameter rs: The state returned by the Begin method.
     * - Parameter wait: By default this is true which will execute the runloop waiting for events,
     * if you pass false, you can use this method to run a single iteration of the events.
     * - Throws: if the passed RunState has been disposed already
     */
    public static func runLoop (rs: RunState, wait : Bool = true) throws
    {
        if let top = rs.top, let main = _mainLoop {
            top._running = true
            while top._running {
                if main.eventsPending (wait){
                    main.mainIteration ()
                    
                } else if wait == false {
                    return
                }
                
                if !top.needDisplay.isEmpty || top._childNeedsDisplay {
                    top.redraw (region: top.bounds)
                    if debugDrawBounds {
                        drawBounds (top)
                    }
                    top.positionCursor()
                    driver.refresh()
                } else {
                    driver.updateCursor()
                }
            }
        } else {
            throw ApplicationError.internalState(msg: "The passed run state is already used")
        }
    }
    
    static func drawBounds (_ view: View)
    {
        view.drawFrame(view.frame, padding: 0, fill: false)
        for childView in view.subViews {
            drawBounds(childView)
        }
    }
    
    /// Runs the application with the built-in toplevel view
    public static func run ()
    {
        run (top: top)
    }
    
    /**
     * Runs the main loop on the given container.
     *
     * This method is used to start processing events for the main application, but it is also used to
     * run modal dialog boxes.
     *
     * To make a toplevel stop execution, set the `running` property to false.
     *
     * This is equivalent to calling `begin` on the toplevel view, followed by `runLoop` with the
     * returned value, and then calling end on the return value.
     *
     * Alternatively, if your program needs to control the main loop and needs to
     * process events manually, you can invoke Begin to set things up manually and then
     * repeatedly call RunLoop with the wait parameter set to false.   By doing this
     * the RunLoop method will only process any pending events, timers, idle handlers and
     * then return control immediately.
     */
    public static func run (top: Toplevel)
    {
        do {
            let rs = begin (toplevel: top)
            try runLoop (rs: rs, wait: true)
        } catch {}
    }
    
    /// Stops running the most recent toplevel
    public static func requestStop ()
    {
        if let c = current {
            c._running = false
        }
    }
    
    static func terminalResized ()
    {
        let full = Rect(x: 0, y: 0, width: driver.cols, height: driver.rows)
        driver.clip = full
        for top in toplevels {
            top.relativeLayout(hostFrame: full)
            do {
                try top.layoutSubviews()
            } catch {}
        }
        refresh ()
    }
    
    static func shutdown()
    {
        driver.end ();
    }
}

