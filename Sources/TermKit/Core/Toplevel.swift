//
//  Toplevel.swift - toplevel contains for the application
//  TermKit
//
//  Created by Miguel de Icaza on 4/12/19.
//  Copyright © 2019 Miguel de Icaza. All rights reserved.
//

import Foundation

/**
 * Toplevel views provide both the basic keyboard navigation between views
 * using cursor keys and tab keys and they also contain the drawing backing
 * store for views that are added to it.
 *
 * Toplevels are the views that are expected to be passed to Application.present
 * to be rendered.   It introduces an independent rendering chain, in addition
 * to the View rendering chain.
 *
 * Calling `Application.requestStop` will remove the last Toplevel from
 * the execution stack, redrawing the screen contents if necessary.
 *
 * There will be a toplevel created for you on the first time use
 * and can be accessed from the property `Application.top`
 * but new toplevels can be created and ran on top of it.   To run, create the
 * toplevel and then invoke `Application.run with the
 * new toplevel.
 *
 * To make a toplevel modal, set the `modal` property to true,
 * this will prevent keyboard and mouse events to go to a previous
 * toplevel.
 */
open class Toplevel : View {
    /// Initializes a new instance of the Toplevel, class with Computed layout, defaulting to full screen dimensions.
    public override init()
    {
        modal = false
        super.init ()
    
        colorScheme = Colors.base
        width = Dim.fill()
        height = Dim.fill ()
    }
    
    /// Factory method that creates a new toplevel with the current terminal dimensions.
    public static func create () -> Toplevel
    {
        let t = Toplevel()
        t.x = Pos.at(0)
        t.y = Pos.at(0)
        t.width = Dim.fill ()
        t.height = Dim.fill ()
        return t
    }
    
    /// Gets or sets a value indicating whether this <see cref="Toplevel"/> can focus.
    public override var canFocus: Bool {
        get {
            return true
        }
        set (value){
            super.canFocus = value
        }
    }
    
    // Uses View.layer backing store

    /**
     * Determines whether the `TopLevel` is modal or not.
     * Causes  `Application.processKey to propagate keys upwards
     * by default unless set to `true`
     */
    public var modal: Bool
    
    open override func processKey(event: KeyEvent) -> Bool {
        if super.processKey(event: event) {
            return true
        }
        switch (event.key){
        case .controlC:
            // TODO: stop current execution of container
            break
        case .controlZ:
            driver.suspend ()
            return true

        case .f5:
            Application.debugDrawBounds.toggle ()
            setNeedsDisplay()
            return true
            
        case .controlI, .cursorRight, .cursorDown:
            let old = getDeepestFocusedSubview (focused)
            if !focusNext() {
                focusNext ()
            }
            if old == focused {
                focusNearestView (getToplevelSubviews (forward: true))
            }
            return true
            
        case .cursorLeft, .cursorUp, .backtab:
            let old = getDeepestFocusedSubview(focused)
            if !focusPrev(){
                focusPrev()
            }
            if old == focused {
                focusNearestView(getToplevelSubviews(forward: false))
            }
            return true
            
        case .controlL:
            Application.refresh ()
            return true
        default:
            return false
        }
        return false
    }
    
    func getDeepestFocusedSubview (_ view: View?) -> View?
    {
        guard let target = view else {
            return nil
        }
        for v in target.subviews {
            if v.hasFocus {
                return getDeepestFocusedSubview(v)
            }
        }
        return view
    }
    
    open override func processColdKey(event: KeyEvent) -> Bool {
        if super.processColdKey(event: event) {
            return true
        }
        // TODO, from gui.cs: should we add View-bound shortcuts to invoke?
        // it feels like those should be handled by each subclass of view
        // or we could introduce a protocol that describes that the control
        // can have a shortcut, and then use that one, and hook it up here.
        return false
    }
    
    func getToplevelSubviews (forward: Bool) -> [View]
    {
        guard let sup = superview else {
            return []
        }
        var views: [View] = []
        var seen = Set<View> ()
        for v in sup.subviews {
            if !seen.contains (v) {
                seen.insert(v)
                if forward {
                    views.append(v)
                } else {
                    views.insert(v, at: 0)
                }
            }
        }
        return views
    }
    
    func focusNearestView (_ views: [View])
    {
        var found = false
        for v in views {
            if v == self {
                found = true
            }
            if found && v != self {
                v.ensureFocus()
                if superview?.focused != nil && superview?.focused != self {
                    return
                }
            }
        }
    }
    
    /**
     *  This method is invoked by Application.Begin as part of the Application.Run after
     * the views have been laid out, and before the views are drawn for the first time.
     */
    public func willPresent ()
    {
        focusFirst()
    }
    
    open override var debugDescription: String {
        return "Toplevel (\(super.debugDescription))"
    }
    
    // Composition and rendering handled by Application
}
