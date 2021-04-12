//
//  Responder.swift
//  TermKit
//
//  Created by Miguel de Icaza on 4/9/19.
//  Copyright © 2019 Miguel de Icaza. All rights reserved.
//

import Foundation

/**
 * Responder base class implemented by objects that want to participate on keyboard and mouse input.
 */
public protocol Responder {
    /// Gets or sets a value indicating whether this `Responder` can focus.
    var canFocus: Bool { get set }
    /// Gets or sets a value indicating whether this `Responder` has focus.
    var hasFocus: Bool { get }
    
    /**
     * This method can be overwritten by view that want to provide
     * accelerator functionality (Alt-key for example).
     *
     * Before keys are sent to the subview on the current view, all the
     * views are processed and the key is passed to the widgets to allow
     * some of them to process the keystroke as a hot-key. </para>
     *
     * For example, if you implement a button that has a hotkey ok "o",
     * you would catch the combination Alt-o here.  If the event is
     * caught, you must return true to stop the keystroke from being
     * dispatched to other views.
     *
     */
    func processHotKey (event: KeyEvent) -> Bool
    
    /**
     * If the view is focused, gives the view a chance to process the
     * keystroke.
     *
     * Views can override this method if they are interested in
     * processing the given keystroke.  If they consume the keystroke,
     * they must return true to stop the keystroke from being processed
     * by other widgets or consumed by the widget engine.  If they
     * return false, the keystroke will be passed using the
     * ProcessColdKey method to other views to process.
     *
     * The View implementation does nothing but return false, so it is
     * not necessary to call base.ProcessKey if you derive directly from
     * View, but you should if you derive other View subclasses.
     */
    func processKey (event: KeyEvent) -> Bool
    
    /**
     * This method can be overwritten by views that want to provide
     * accelerator functionality (Alt-key for example), but without
     * interefering with normal ProcessKey behavior.
     *
     * After keys are sent to the subviews on the current view, all the
     * view are processed and the key is passed to the views to allow
     * some of them to process the keystroke as a cold-key.
     *
     * This functionality is used, for example, by default buttons to
     * act on the enter key.  Processing this as a hot-key would prevent
     * non-default buttons from consuming the enter keypress when they
     * have the focus.
     */
    func processColdKey (event: KeyEvent) -> Bool
    
    /**
     * Method invoked when a mouse event is generated
     * - Parameter event: Contains the details about the mouse event.
     * - Returns: `true` if the event was handled, `false` otherwise
     */
    func mouseEvent (event: MouseEvent) -> Bool
    
    /**
     * Method invoked when a mouse event is generated for the first time.
     * - Parameter event: Contains the details about the mouse event.
     * - Returns: `true` if the event was handled, `false` otherwise
     */
    func mouseEnter (event: MouseEvent) -> Bool
    
    /**
     * Method invoked when a mouse event is generated for the last time.
     * - Parameter event: Contains the details about the mouse event.
     * - Returns: `true` if the event was handled, `false` otherwise
     */
    func mouseLeave (event: MouseEvent) -> Bool
    
    /**
     * Makes this the first responder object (has the focus)
     * - Returns: `true` if this became the first responder, `false` if not.
     */
    func becomeFirstResponder () -> Bool
    
    /**
     * Notifies this object that it should no longer have the focus (the first responder)
     * - Returns: `true` if this gave up being the first responder, `false` if not.
     */
    func resignFirstResponder() -> Bool

}
