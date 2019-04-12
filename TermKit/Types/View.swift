//
//  View.swift
//  TermKit
//
//  Created by Miguel de Icaza on 4/7/19.
//  Copyright © 2019 Miguel de Icaza. All rights reserved.
//

import Foundation

/**
 * View is the base class for all views on the screen and represents a visible element that can render itself and contains zero or more nested views.
 *
 * The View defines the base functionality for user interface elements in TermKit.  Views
 * can contain one or more subviews, can respond to user input and render themselves on the screen.
 *
 * Views can either be created by setting the X, Y, Width and Height properties on the view.    Coordinates are relative
 * to the container they are being added to.
 *
 * The `x`, and `y` properties are of type `Pos`, and you can use either absolute positions, percentages or anchor
 * points
 *
 * The `width` and `height` properties are of type `Dim`
 * and can use absolute position, percentages and anchors.   These are useful as they will
 * take care of repositioning your views if your view's frames are resized or if the
 * terminal size changes
 *
 * Subviews can be added to a View by calling the `addSubview` method.   The container of a view is the
 * Superview.
 *
 * Developers can call the `setNeedsDisplay` method on the view to flag a region or the entire view
 * as requiring to be redrawn.
 *
 * Views have a ColorScheme property that defines the default colors that subviews
 * should use for rendering.   This ensures that the views fit in the context where
 * they are being used, and allows for themes to be plugged in.   For example, the
 * default colors for windows and toplevels uses a blue background, while it uses
 * a white background for dialog boxes and a red background for errors.
 *
 * If a ColorScheme is not set on a view, the result of the ColorScheme is the
 * value of the SuperView and the value might only be valid once a view has been
 * added to a SuperView, so your subclasses should not rely on ColorScheme being
 * set at construction time.
 *
 * Using ColorSchemes has the advantage that your application will work both
 * in color as well as black and white displays.
 *
 * Views that are focusable should implement the `positionCursor` to make sure that
 * the cursor is placed in a location that makes sense.   Unix terminals do not have
 * a way of hiding the cursor, so it can be distracting to have the cursor left at
 * the last focused view.   So views should make sure that they place the cursor
 * in a visually sensible place.
 *
 * The metnod `layoutSubviews` is invoked when the size or layout of a view has
 * changed.   The default processing system will keep the size and dimensions
 * for views that use the LayoutKind.Absolute, and will recompute the
 * frames for the vies that use LayoutKind.Computed.

 */
open class View : Responder {

    var superView : View? = nil
    var focused : View? = nil
    var subViews : [View] = []
    var _frame : Rect = Rect.zero
    var id : String = ""
    var needDisplay : Rect = Rect.zero
    var _childNeedsDisplay : Bool = false
    var _canFocus : Bool = false
    
    public var canFocus : Bool {
        get {
            return _canFocus
        }
        set(value) {
            _canFocus = value
        }
    }
    var _hasFocus : Bool = false
    public var hasFocus : Bool {
        get {
            return _hasFocus
        }
        set(value) {
            if _hasFocus != value {
                setNeedsDisplay()
            }
            _hasFocus = value
            
            // Remove focus down the chain of subviews if focus was removed
            if !value && focused != nil {
                focused!.hasFocus = false
                focused = nil
            }
        }
    }
    
    var layoutNeeded : Bool = true
    
    /**
     * Points to the current driver in use by the view, it is a convenience property
     * for simplifying the development of new views.
     */
    var driver : ConsoleDriver {
        get {
            return Application.Shared.driver
        }
    }
    
    init ()
    {
        _frame = Rect(x:0, y: 0, width: 0, height: 0)
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
            return Rect (origin: Point.zero, size: frame.size)
        }
    }
    
    /**
     * Invoke to flag that this view needs to be redisplayed, by any code
     * that alters the state of the view.
     */
    public func setNeedsDisplay ()
    {
        setNeedsDisplay(bounds)
    }
    
    /**
     * Flags the specified rectangle region on this view as needing to be repainted.
     * - Parameter region: The region that must be flagged for repaint.
     */
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
            if view.frame.intersects(region){
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
            _canFocus = true
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
    
    /**
     * Converts a point from screen coordinates into the view coordinate space.
     * - Parameter x: X screen-coordinate point.
     * - Parameter x: Y screen-coordinate point.
     *
     * - Returns: the mapped point
     */
    public func screenToView (x : Int, y : Int) -> Point
    {
        if let container = superView {
            let parent = container.screenToView(x: x, y: y)
            return Point(x: parent.x - frame.minX, y: parent.y - frame.minY)
        } else {
            return Point (x: x - frame.minX, y: y - frame.minY)
        }
    }
    
    // Converts a rectangle in view coordinates to screen coordinates.
    func rectToScreen (_ rect: Rect) -> Rect
    {
        let (x, y) = viewToScreen(col: rect.minX, row: rect.minY, clipped: false)
        return Rect (x: x, y: y, width: rect.width, height: rect.height)
    }
    
     // Clips a rectangle in screen coordinates to the dimensions currently available on the screen
    func screenClip (_ rect : Rect) -> Rect
    {
        let (minx, miny, maxx, maxy) = (rect.minX, rect.minY, rect.maxX, rect.maxY)
        let x = minx < 0 ? 0 : minx
        let y = miny < 0 ? 0 : miny
        let w = maxx >= driver.cols ? driver.cols - minx : rect.width
        let h = maxy >= driver.rows ? driver.rows - miny : rect.height
        
        return Rect(x: x, y: y, width: w, height: h)
    }
    
    /**
     * Sets the Console driver's clip region to the current View's `bounds`.
     * - Paramater rect: xx
     * - Returns: The existing driver's Clip region, which can be then set by setting the Driver.clip property.
     */
    public func clipToBounds ()
    {
       self.setClip (bounds)
    }
    
    /**
     * Sets the clipping region to the specified region, the region is view-relative
     * - Parameter rect: Rectangle region to clip into, the region is view-relative.
     * - Returns: The previous clip region
     */
    public func setClip (_ rect: Rect) -> Rect
    {
        let bscreen = rectToScreen(rect)
        let previous = driver.clip
        driver.clip = screenClip (bscreen)
        return previous
    }
    
    /**
     * Draws a frame in the current view, clipped by the boundary of this view
     * - Parameter rect: Rectangular region for the frame to be drawn.
     * - Parameter padding: The padding to add to the drawn frame.
     * - Parameter fill: If set to `true` it fill will the contents.
     */
    public func drawFrame (_ rect : Rect, padding : Int = 0, fill : Bool = false)
    {
        let scrRect = rectToScreen(rect)
        let savedClip = driver.clip
        driver.clip = screenClip (rectToScreen(bounds))
        driver.drawFrame (scrRect, padding: padding, fill: fill)
        driver.clip = savedClip
    }
    
    /**
     * Utility function to draw strings that contain a hotkey, the hotkey is indicated by an underline string
     * - Parameter text: String to display, the underscoore before a letter flags the next letter as the hotkey.
     * - Parameter hotColor: color used to draw the hotkey
     * - Parameter normalColor: color used for the regular parts of the string
     */
    public func drawHotString (text : String, hotColor : Attribute, normalColor : Attribute)
    {
        driver.setAttribute(normalColor)
        for ch in text {
            if ch == "_" {
                driver.setAttribute(hotColor)
            } else {
                driver.addCharacter(ch)
                driver.setAttribute(normalColor)
            }
        }
    }
    
    /**
     * Utility function to draw strings that contains a hotkey using a colorscheme and the "focused" state.
     * - Parameter text: String to display, the underscoore before a letter flags the next letter as the hotkey.
     * - Parameter focused: If set to `true` this uses the focused colors from the color scheme, otherwise the regular ones.
     * - Parameter scheme: The color scheme to use
     */
    public func drawHotString (text : String, focused : Bool, scheme : ColorScheme)
    {
        if focused {
            drawHotString(text: text, hotColor: scheme.hotFocus, normalColor: scheme.focus)
        } else {
            drawHotString(text: text, hotColor: scheme.hotNormal, normalColor: scheme.normal)
        }
    }
    
    /**
     * This moves the cursor to the specified column and row in the view, any additional drawing operation will start at the specified location
     * - Parameter col: Column to move to
     * - Parameter row: Row to move to.
     */
    public func moveTo (col : Int, row: Int)
    {
        let (rcol, rrow) = viewToScreen(col: col, row: row)
        driver.moveTo(col: rcol, row: rrow)
    }
    
    /**
     * Positions the cursor in the right position based on the currently focused view in the chain.
     */
    public func positionCursor ()
    {
        if let f = focused {
            f.positionCursor()
        } else {
            moveTo (col: frame.minX, row: frame.minY)
        }
    }
    
    /**
     * Returns the most focused view in the chain of subviews (the leaf view that has the focus).
     */
    public func mostFocused () -> View?
    {
        if let f = focused {
            if let most = f.mostFocused() {
                return most
            }
            return f
        } else {
            return nil
        }
    }
    
    var _colorScheme : ColorScheme? = nil
    /**
     * The basic colorscheme used by this view
     */
    public var colorScheme : ColorScheme? {
        get {
            if _colorScheme == nil {
                if let s = superView {
                    return s.colorScheme
                }
                return nil
            }
            return _colorScheme
        }
        set(value) {
            _colorScheme = value
            setNeedsDisplay()
        }
    }
    
    /**
     * Sets the current attribute to use for drawing in the view
     */
    public func setAttribute (_ attr: Attribute)
    {
       driver.setAttribute(attr)
    }
    
    /**
     * Draws the rune at the last position set by moveTo, use only when you know that the rune wont compose, otherwise use addChar
     *
     * This will advance the logical cursor position
     */
    public func addRune (_ rune: rune)
    {
        driver.addRune(rune)
    }
    
    /**
     * Draws the rune at the specific location, use only when you know that the rune wont compose, otherwise use addChar
     *
     * This will advance the logical cursor position
     */
    public func addRune (rune: rune, col:Int, row:Int)
    {
        if (col < 0 || row < 0 || row > frame.height-1 || col > frame.width-1) {
            return
        }
        moveTo(col: col, row: row)
        driver.addRune(rune)
    }

    /**
     * Draws the character at the last position set by moveTo.
     *
     * This will advance the logical cursor position
     */
    public func addChar (_ char: Character)
    {
        driver.addCharacter(char)
    }
    
    /**
     * Draws the character at the specific location.
     *
     * This will advance the logical cursor position
     */
    public func addChar (char: Character, col:Int, row:Int)
    {
        if (col < 0 || row < 0 || row > frame.height-1 || col > frame.width-1) {
            return
        }
        moveTo(col: col, row: row)
        driver.addCharacter(char)
    }

    /**
     * Removes the SetNeedsDisplay and the ChildNeedsDisplay setting on this view.
     */
    public func clearNeedsDisplay ()
    {
        needDisplay = Rect.zero
        _childNeedsDisplay = false
    }
    
    /**
     * Performs a redraw of this view and its subviews, only redraws the views that have been flagged for a re-display.
     *
     * Views should set the color that they want to use on entry, as otherwise this will inherit
     * the last color that was set globaly on the driver.
     *
     * - Parameter region: The region to redraw, this is relative to the view itself.
     */
    public func redraw(region : Rect)
    {
        var clipRect = Rect (origin: Point.zero, size: Size.empty)
        for view in subViews {
            if !view.needDisplay.isEmpty || view._childNeedsDisplay {
                if view.frame.intersects(clipRect) && view.frame.intersects(region){
                    // TODO: optimize this by computing the intersection of region and view.Bounds
                    view.redraw (region: view.bounds)
                }
                view.needDisplay = Rect.zero
                view._childNeedsDisplay = false
            }
        }
        clearNeedsDisplay()
    }
    
    /**
     * Focuses the specified subview
     */
    public func setFocus (_ view: View?)
    {
        if let v = view {
            if !v.canFocus {
                return
            }
            if focused != nil && focused! === v {
                return
            }
            
            // Make sure that this view is a subview
            var c = v.superView
            while (c != nil){
                if (c! === self) {
                    break
                }
                c = c!.superView
            }
            if c == nil {
                // error
                return
            }
            if let nf = focused {
                nf.hasFocus = false
            }
            focused = view
            focused!.hasFocus = true
            focused!.ensureFocus()
            
            // Send focus upwards
            if let s = superView {
                s.setFocus (self)
            }
        }
    }
    
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
    public func processHotKey(event: KeyEvent) -> Bool
    {
        for view in subViews {
            if view.processHotKey(event: event) {
                return true
            }
        }
        return false
    }
    
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
    public func processKey(event: KeyEvent) -> Bool
    {
        if let f = focused {
            return f.processKey(event: event)
        }
        return false
    }
    
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
    public func processColdKey(event: KeyEvent) -> Bool
    {
        for view in subViews {
            if view.processColdKey(event: event) {
                return true
            }
        }
        return false
    }
    
    /**
     * Method invoked when a mouse event is generated
     */
    public func mouseEvent(event: MouseEvent) -> Bool
    {
        return false
    }
    
    /// Finds the first view in the hierarchy that wants to get the focus if nothing is currently focused, otherwise, it does nothing.
    public func ensureFocus ()
    {
        if focused == nil {
            focusFirst ()
        }
    }
    
    /// Focuses the first focusable subview if one exists.
    public func focusFirst ()
    {
        if subViews.count == 0 {
            superView?.setFocus(self)
            return
        }
        
        for view in subViews {
            if view.canFocus {
                setFocus (view)
                return
            }
        }
    }
    
    /// Focuses the last focusable subview if one exists.
    public func focusLast ()
    {
        if subViews.count == 0 {
            superView?.setFocus(self)
            return
        }
        
        for view in subViews.reversed() {
            if view.canFocus {
                setFocus (view)
                return
            }
        }
    }
    
    /**
     * Focuses the previous view in the focus chain
     * - Returns: `true` if previous was focused, `false` otherwise
     */
    public func focusPrev () -> Bool
    {
        if subViews.count == 0 {
            return false
        }
        if focused == nil {
            focusLast ()
            return true
        }
        var focusedIdx = -1
        var i = subViews.count
        while (i > 0){
            i -= 1
            let w = subViews [i]
            if w.hasFocus {
                if w.focusPrev () {
                    return true
                }
                focusedIdx = i
                continue
            }
            if w.canFocus && focusedIdx != -1 {
                focused!.hasFocus = false
                if w.canFocus {
                    w.focusLast ()
                }
                setFocus (w)
                return true
            }
        }
        if focusedIdx != -1 {
            focusLast ()
            return true
        }
        if focused != nil {
            focused?.hasFocus = false
            focused = nil
        }
        return false
    }
    
    /**
     * Focuses the next view in the focus chain
     * - Returns: `true` if previous was focused, `false` otherwise
     */
    public func focusNext () -> Bool
    {
        if subViews.count == 0 {
            return false
        }
        if focused == nil {
            focusFirst ()
            return focused != nil
        }
        var focusedIdx = -1
        var n = subViews.count
        for i in 0..<n {
            let w = subViews [i]
            if w.hasFocus {
                if w.focusNext () {
                    return true
                }
                focusedIdx = i
                continue
            }
            if w.canFocus && focusedIdx != -1 {
                focused!.hasFocus = false
                if w.canFocus {
                    w.focusFirst ()
                }
                setFocus (w)
                return true
            }
        }
        if focused != nil {
            focused?.hasFocus = false
            focused = nil
        }
        return false
    }
    
    var _x : Pos? = nil
    /// Gets or sets the X position for the view (the column).  This is only used when the LayoutStyle is Computed, if the
    /// LayoutStyle is set to Absolute, this value is ignored.
    public var x : Pos? {
        get { return _x }
        set(value) {
            _x = value
            setNeedsLayout()
        }
    }
    var _y : Pos? = nil
    /// Gets or sets the Y position for the view (the row).  This is only used when the LayoutStyle is Computed, if the
    /// LayoutStyle is set to Absolute, this value is ignored.
    public var y : Pos? {
        get { return _y }
        set(value) {
            _y = value
            setNeedsLayout()
        }
    }
    var _width : Dim? = nil
    /// Gets or sets the width for the view. This is only used when the LayoutStyle is Computed, if the
    /// LayoutStyle is set to Absolute, this value is ignored.
    public var width : Dim? {
        get { return _width }
        set(value) {
            _width = value
            setNeedsLayout()
        }
    }
    var _height : Dim? = nil
    /// Gets or sets the height for the view. This is only used when the LayoutStyle is Computed, if the
    /// LayoutStyle is set to Absolute, this value is ignored.
    public var height : Dim? {
        get { return _height }
        set(value) {
            _height = value
            setNeedsLayout()
        }
    }
    
    // Computes the RelativeLayout for the view, given the frame for its container.
    // hostFrame is the frame for the host
    func relativeLayout (hostFrame : Rect)
    {
        var ww, hh, xx, yy : Int
        
        if _x != nil && x is Pos.PosCenter {
            ww = _width == nil ? hostFrame.width : _width!.Anchor(hostFrame.width)
            xx = _x!.Anchor(hostFrame.width - ww)
        } else {
            xx = _x == nil ? 0 : x!.Anchor(hostFrame.width)
            ww = _width == nil ? hostFrame.width : _width!.Anchor(hostFrame.width-xx)
        }
        
        if _y != nil && y is Pos.PosCenter {
            
        }
    }
}
