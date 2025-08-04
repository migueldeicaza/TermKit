//
//  Application.swift - Application initialization and main loop.,
//  MiniGui
//
//  Created by Miguel de Icaza on 3/6/19.
//  Copyright © 2019 Miguel de Icaza. All rights reserved.
//

import Foundation
import Darwin.ncurses
import os

var fd: Int32 = -1
@available(OSX 11.0, *)
var logger: Logger = Logger(subsystem: "termkit", category: "TermKit")

func log (_ s: String)
{
    if true {
        if #available(macOS 11.0, *) {
            logger.log("log: \(s, privacy: .public)")
            return
        }
        if fd == -1 {
            fd = open ("/tmp/log", O_CREAT | O_RDWR, S_IRWXU)
        }
        if let data = (s + "\n").data(using: String.Encoding.utf8) {
            let _ = data.withUnsafeBytes { (dataBytes: UnsafeRawBufferPointer) -> Int in
                return write(fd, dataBytes.baseAddress, data.count)
            }
        }
    }
}

class SizeError: Error {
}

enum ApplicationError: Error {
    case internalState(msg:String)
}

/**
 * The `Application` class is responsible for running your application.
 *
 * The `Application` class has at least one `TopLevel` view that is displayed (and
 * is the one pointed to by `top`) and will send events to this instance.   You
 * should add your views to this top instance.   A minimal initialization sequence
 * looks like this:
 *
 * ```
 * Application.prepare ()
 * let win = Window()
 * win.fill ()
 * Application.top.addSubview (win)
 * Application.run()
 * ```
 *
 * The call to the `prepare` method initializes the default console driver, which will
 * be set depending on your platform and heuristics (currently it is limited to the
 * curses version).
 *
 * Then you need to add one or more views to your application, in the example above,
 * a new `Window` is created, we flag it to take over all the available space by calling
 * the `fill` method, and then we add this to the `top` element.   Once this happens,
 * we call `Application.run` which is a method that will never return.
 *
 * # TopLevels
 * At any given point there is only a single `Toplevel` instance active, this means that
 * all mouse and keyboard events are routed here.   There might be multiple visible `Toplevel`
 * at any given point, for example the main application is a `Toplevel`, and a popup dialog
 * box is another form of a toplevel.   When the popup is executing, all keyboard and mouse
 * input are routed to the dialog box, but the main Toplevel will still be updated visually
 * and might also be updated continously.
 *
 * To execute a new nested toplevel, one that either obscures a portion of the screen, or the
 * whole screen, you call the `present` method with the new instance.   To pop the toplevel from
 * the stack, you call the `Application.requestStop` method which will queue the toplevel for
 * termination and will make the previous toplevel the active one.
 *
 * # Main Loop Execution
 * Calling the `present` method in `Application` will start the mainloop, which is implemented using
 * the Dispatch framework.   This means that this method will never return, but also that all
 * the operations that you have come to expect from using the Dispatch API (from Grand Central Dispatch)
 * will work as expected.
 *
 * The TermKit framework is not multi-thread safe, so any operations that you execute on the background
 * should queue operations that access properties, or call methods in any of the TermKit methods
 * using the global queue, so that the operation is executed in the context of the TermKit queue.
 *
 */
public class Application {
    /// Points to the global application
    static var _top: Toplevel? = nil
    static var _current: Toplevel? = nil
    static var toplevels: [Toplevel] = []
    static var debugDrawBounds: Bool = false
    static var initialized: Bool = false
    
    /// The Toplevel object used for the application on startup.
    public static var top: Toplevel {
        get {
            guard let x = _top else {
                print ("You must call Application.prepare()")
                abort()
            }
            return x
        }
    }
    
    /// The current toplevel object.   This is updated when Application.Run enters and leaves and points to the current toplevel.
    public static var current: Toplevel? {
        get {
            return _current
        }
    }

    /// The current Console Driver in use.
    static var driver: ConsoleDriver = CursesDriver()
    
    /**
     * Prepares the application, must be called before anything else.
     */
    public static func prepare ()
    {
        if initialized {
            return
        }
        let _ = driver
        toplevels = []
        _current = nil
        _top = Toplevel()
        wantContinuousButtonPressedView = nil
        lastMouseOwnerView = nil
        initialized = true
        rootMouseHandlers = [:]
        lastMouseToken = 0
        let _ = driver
        setupPostProcessPipes ()
        log ("Driver.size: \(driver.size)")
    }
    
    /// We use this pipe to trigger a call to postProcessEvent
    static var pipePostProcessEvent: [Int32] = [0, 0]
    static var pipeReader: DispatchSourceRead?
    static let bufferSize = 128
    static var buffer = UnsafeMutableRawPointer.allocate(byteCount: bufferSize, alignment: 8)
    
    static func setupPostProcessPipes () {
        pipe(&pipePostProcessEvent)
        _ = fcntl(pipePostProcessEvent[0], F_SETFL, O_NONBLOCK)
        let reader = DispatchSource.makeReadSource(fileDescriptor: pipePostProcessEvent[0], queue: .main)
        pipeReader = reader
        reader.setEventHandler {
            // Read all pending requests in one go
            var count = 0
            repeat {
                count = read(pipePostProcessEvent[0], buffer, bufferSize)
                //let status = (count == -1 && errno == EWOULDBLOCK)
            } while count > 0
            postProcessEvent()
        }
        reader.activate()
    }
    
    static func requestPostProcess () {
        write(pipePostProcessEvent [1], &pipePostProcessEvent, 1)
    }
    
    /**
     * Triggers a refresh of the whole display
     */
    static public func refresh ()
    {
        screen = Layer.empty
        for t in toplevels {
            t.setNeedsDisplay()
            let painter = Painter.createTopPainter (from: t)
            t.redraw(region: t.bounds, painter: painter)
        }
        updateDisplay(compose ())
        
        // updatescreen, unlike refresh, calls the curses call that repaints the whole region
        driver.updateScreen()
    }
    
    static func processKeyEvent (event: KeyEvent)
    {
        defer {
            if Application.initialized {
                postProcessEvent()
            }
        }
        log ("processKeyEvent: \(event)")
        let toplevelCopy = toplevels.reversed()
        for top in toplevelCopy {
            if top.processHotKey(event: event) {
                return
            }
            if top.modal {
                break
            }
        }
        
        for top in toplevelCopy {
            if top.processKey(event: event) {
                return
            }
            if top.modal {
                break
            }
        }
        
        for top in toplevelCopy {
            if top.processColdKey(event: event) {
                return
            }
            if top.modal {
                break
            }
        }
    }
    
    static func findDeepestView (start: View, pos: Point) -> (view: View, localPoint: Point)?
    {
        let startFrame = start.frame
        
        if !startFrame.contains(pos){
            return nil
        }

        let count = start.subviews.count
        if count > 0 {
            let location = pos - startFrame.origin

            for i in (0..<(count)).reversed() {
                let v = start.subviews[i]
                if v.frame.contains(location) {
                    let deep = findDeepestView(start: v, pos: location)
                    if deep == nil {
                        return (view: v, Point.zero)
                    }
                    return deep
                }
            }
        }

        return (view: start, localPoint: pos-startFrame.origin)
    }
    
    // Tracks the view that has grabbed the mouse
    static var mouseGrabView: View? = nil
    
    /// Grabs the mouse, forcing all mouse events to be routed to the specified view until `ungrabMouse` is called.
    /// - Parameter from: View that will receive all mouse events until UngrabMouse is invoked.
    public static func grabMouse (from view: View)
    {
        mouseGrabView = view
        driver.uncookMouse ()
    }

    /// Ungrabs the mouse, allowing mouse events that were previously captured by one view to flow to other views
    public static func ungrabMouse ()
    {
        mouseGrabView = nil
        driver.cookMouse ()
    }
    
    static var wantContinuousButtonPressedView: View? = nil
    static var lastMouseOwnerView: View? = nil

    static var rootMouseHandlers: [Int:(MouseEvent)->()] = [:]
    static var lastMouseToken = 0
    
    /**
     * A token representing a registered root mouse handler
     */
    public struct MouseHandlerToken {
        var token: Int
    }
    
    /**
     * Registers a global mouse event handler to be invoked for every mouse event, this
     * is called before any event processing takes place for the currently focused view.
     */
    public static func addRootMouseHandler (_ handler: @escaping (MouseEvent)->()) -> MouseHandlerToken
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
    
    static func outsideFrame (_ p: Point, _ r: Rect) -> Bool {
        return p.x < 0 || p.x > r.width-1 || p.y < 0 || p.y > r.height - 1
    }
    
    static func processMouseEvent (mouseEvent: MouseEvent)
    {
        log ("Application Event: \(mouseEvent)")
        for h in rootMouseHandlers.values {
            h (mouseEvent)
        }
        guard let c = _current else {
            return
        }

        defer { postProcessEvent() }
        
        if let grab = mouseGrabView {
            let newxy = grab.screenToView(loc: mouseEvent.pos)
            let nme = MouseEvent(pos: newxy, absPos: mouseEvent.absPos, flags: mouseEvent.flags, view: grab)
            if outsideFrame(nme.pos, grab.frame) {
                let _ = lastMouseOwnerView?.mouseLeave(event: mouseEvent)
            }
            let _ = grab.mouseEvent(event: nme)
            return
        }
        
        if let deepest = findDeepestView(start: c, pos: mouseEvent.pos) {
            if deepest.view.wantContinuousButtonPressed {
                wantContinuousButtonPressedView = deepest.view
            } else {
                wantContinuousButtonPressedView = nil
            }
            let nme = MouseEvent(pos: deepest.localPoint, absPos: mouseEvent.absPos, flags: mouseEvent.flags, view: deepest.view)
            if lastMouseOwnerView == nil {
                lastMouseOwnerView = deepest.view
                let _ = deepest.view.mouseEnter(event: nme)
            } else if lastMouseOwnerView != deepest.view {
                let _ = lastMouseOwnerView?.mouseLeave(event: nme)
                let _ = deepest.view.mouseEnter(event: nme)
                lastMouseOwnerView = deepest.view
            }
            if !deepest.view.wantMousePositionReports && (mouseEvent.flags == MouseFlags.mousePosition) {
                return
            }
            wantContinuousButtonPressedView = deepest.view.wantContinuousButtonPressed ? deepest.view : nil
            
            // Should we bubble up the event if it not handled?
            let _ = deepest.view.mouseEvent (event: nme)
        } else {
            wantContinuousButtonPressedView = nil
        }
        
    }
    
    static var screen: Layer = Layer.empty
    
    static func compose () -> Layer
    {
        let screenSize = Application.driver.size
        var dirtyLines: [Bool]
        
        if screen.size != screenSize {
            screen = Layer (size: screenSize)
            dirtyLines = Array.init(repeating: true, count: screenSize.height)
        } else {
            dirtyLines = Array.init(repeating: false, count: screenSize.height)
        }
        
        #if debug
        for x in 0..<screen.store.count {
            screen.store [x].ch = "x"
        }
        #endif
        var linesCopied = 0
        let screenFrame = Rect (origin: Point (x: 0, y: 0), size: screenSize)
        
        // Start at the last toplevel that fully obscures the screen
        let start = toplevels.lastIndex(where: {top in top.frame == screenFrame}) ?? 0
        
        for view in toplevels[start...] {
            let vframe = view.frame
            
            let intersection = screenFrame.intersection (vframe)
            if intersection == Rect.zero {
                continue
            }
            
            
            // the source location to copy from (clamped)
            let sourceStart = Point (x: vframe.minX < 0 ? -vframe.minX : 0, y: vframe.minY < 0 ? -vframe.minY : 0)
            for row in 0..<intersection.height {
                let y = intersection.minY + row
                let sourceRow = sourceStart.y + row
                
                let viewLineIsDirty = view.layer.dirtyRows [sourceRow]
                dirtyLines [y] = dirtyLines [y] || viewLineIsDirty
                
                guard dirtyLines [y] else {
                    continue
                }
                linesCopied += 1
                // the offset into the array
                let targetOffset = y * screenSize.width + intersection.minX
                let sourceOffset = sourceRow * vframe.width + sourceStart.x
                screen.store.replaceSubrange(targetOffset..<(targetOffset + intersection.width), with: view.layer.store [sourceOffset..<sourceOffset+intersection.width])
            }
            view.layer.clearDirty ()
            //updateDisplay(screen, Application.driver.cols, Application.driver.rows)
        }
        log ("Lines copied \(linesCopied)")
        return screen
    }
    
    static func updateDisplay (_ layer: Layer) {
        var attr: Int32 = -1
        var idx = 0
        let cols = layer.size.width
        
        driver.moveTo (col: 0, row: 0)
        for cell in layer.store {
            idx += 1
            attr = -1
            if cell.attr.value != attr {
                attr = cell.attr.value
                driver.setAttribute(cell.attr)
            }
            driver.addCharacter(cell.ch)

            if (idx % cols) == 0 {
                driver.moveTo(col: 0, row: idx / cols)
            }
        }
        driver.refresh()
    }
    
    static func switchFocus ()
    {
        if let currentTop = toplevels.first {
            _ = currentTop.resignFirstResponder()
        }
    }

    /**
     * Building block API: Prepares the provided toplevel for execution.
     *
     * This method prepares the provided toplevel for running with the focus,
     * it adds this to the list of toplevels, sets up the mainloop to process the
     * event, lays out the subviews, focuses the first element, and draws the
     * toplevel in the screen.
     *
     * - Parameter toplevel: Toplevel to prepare execution for.
     */
    
    public static func begin (toplevel: Toplevel)
    {
        if !initialized {
            print ("You should call Application.prepare() to initialize")
            abort ()
        }
        switchFocus ()
        toplevels.append(toplevel)
        _current = toplevel
        if toplevel.layoutStyle == .computed {
            toplevel.relativeLayout(hostFrame: Rect (origin: Point.zero, size: driver.size))
        }
        do {
            try toplevel.layoutSubviews()
        } catch {}
        toplevel.willPresent()

        toplevel.paintToBackingStore ()
        
        let content = compose()
        updateDisplay(content)
        
        
        toplevel.positionCursor()
        driver.refresh()
    }

    /**
     * Makes the provided toplevel the new toplevel, sending all events to it,
     * it returns control immediately.   If the toplevel is modal 
     */
    public static func present (top: Toplevel)
    {
        begin (toplevel: top);
    }
    
    /**
     * Starts the application mainloop - does not return, but can exit to the OS.
     */
    public static func run ()
    {
        begin (toplevel: top)
        dispatchMain()
    }
    
    // This is currently a hack invoked after any input events have been processed
    // and triggers the redisplay of information.   The way that this should work
    // instead is that setNeedsLayout, and setNeedsDisplay should queue an operation
    // if they are invoked, to trigger this processing.
    //
    // This would have a couple of benefits: one, it would allow more than one character
    // to be processed on input, rather than refreshing for each character, and later would
    // help me split the frame processing like UIKit does: input first, layout next,
    // redraw next, driver.refresh last.
    //
    // So this hack is here just temporarily
    static var updateQueued = false
    static func postProcessEvent ()
    {
        flushPendingDisplay()
        //log("Entering at \(Date().timeIntervalSince1970*1000)")
        if updateQueued { return }
        updateQueued = true
        //log("Queuing at \(Date().timeIntervalSince1970*1000)")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1/60.0) {
            flushPendingDisplay()
        }
    }
    
    static func flushPendingDisplay() {
        //log("Flushing at \(Date().timeIntervalSince1970*1000)")
        updateQueued = false
        if let c = current {
            c.layout ()
            if !c.needDisplay.isEmpty {
                c.redraw (region: c.needDisplay, painter: Painter.createTopPainter(from: c))
//                if debugDrawBounds {
//                    drawBounds (c)
//                }
                updateDisplay(compose ())
                c.positionCursor()
                driver.refresh()
            } else {
                c.positionCursor()
                driver.updateCursor()
            }
        }
    }
    
//    static func drawBounds (_ view: View)
//    {
//        view.drawFrame(view.frame, padding: 0, fill: false)
//        for childView in view.subviews {
//            drawBounds(childView)
//        }
//    }
    
    /**
     * Stops running the most recent toplevel, use this to close a dialog, window, or toplevel.
     * The last time this is called, it will return to the OS and will return with the status code 0.
     *
     * If you want to terminate the application with a different status code, call the `Application.shutdown`
     * method directly with the desired exit code.
     */
    public static func requestStop ()
    {
        DispatchQueue.main.async {
            if current != nil {
                toplevels = toplevels.dropLast ()
                if toplevels.count == 0 {
                    Application.shutdown ()
                } else {
                    _current = toplevels.last as Toplevel?
                    if let c = _current {
                        _ = c.becomeFirstResponder()
                    }
                    refresh ()
                }
            } else {
                Application.shutdown()
            }
        }
    }
    
    static func terminalResized ()
    {
        let full = Rect(origin: Point.zero, size: driver.size)
        for top in toplevels {
            top.relativeLayout(hostFrame: full)
            do {
                try top.layoutSubviews()
            } catch {}
        }
        refresh ()
    }
    
    /**
     * Terminates the application execution
     *
     * Because this is using Dispatch to run the application main loop, there is no way of terminating
     * the main loop, other than exiting the process.   This restores the terminal to its previous
     * state and terminates the process.
     *
     * - Paramter statusCode: status code passed to the `exit(2)` system call to terminate the process.
     */
    public static func shutdown(statusCode: Int = 0)
    {
        initialized = false
        
        
        close (pipePostProcessEvent[0])
        close (pipePostProcessEvent[1])
        pipeReader?.cancel()
        pipeReader = nil
        
        driver.end ();
        exit (Int32 (statusCode))
    }
}

