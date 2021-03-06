//
//  View.swift - base class for all views
//  TermKit
//
//  Created by Miguel de Icaza on 4/7/19.
//  Copyright © 2019 Miguel de Icaza. All rights reserved.
//

import Foundation
import OpenCombine

/**
 * Determines the LayoutStyle for a view, if Absolute, during LayoutSubviews, the
 * value from the Frame will be used, if the value is Computer, then the Frame
 * will be updated from the X, Y Pos objets and the Width and Heigh Dim objects.
 */
public enum LayoutStyle {
    /// The position and size of the view are based on the Frame value.
    case fixed
    /// The position and size of the view will be computed based on the x, y, width and height
    /// properties and set on the Frame.
    case computed
}

/**
 * View is the base class for all views on the screen and represents a visible element that can render itself and contains zero or more nested views.
 *
 * The View defines the base functionality for user interface elements in TermKit.  Views
 * can contain one or more subviews, can respond to user input and render themselves on the screen.
 *
 * Views can either be created with a constructor that takes a `Rect` as the frame to used for the view,
 * which means that the view is using the `.fixed` LayoutStyle, or  with the empty construtor, and then
 * setting the `x`, `y`, `width` and `height` properties on the view which configures the view
 * to use the `.computed` layout style.
 *
 * The view layout system can be controlled by accessing the `layoutStyle` property, and is used
 * to transition from the fixed to the computed mode.
 *
 * The `x`, and `y` properties are of type `Pos`, and you can use either absolute positions, percentages or anchor
 * points.
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
open class View: Responder, Hashable, CustomDebugStringConvertible {
    enum FocusDirection {
        case forward
        case backward
    }
    /// The superview points to the container where this view was added, or nil if this view has not been added to a container
    public private(set) var superview: View? = nil
    
    /// Returns the currently focused view inside this view, or nil if nothing is focused.
    public private(set) var focused: View? = nil
    
    var _focusDirection: FocusDirection = .forward
    
    // Backing store for the views
    var _subviews: [View] = []
    var _frame: Rect = Rect.zero
    var viewId: Int
    var id: String = ""
    var needDisplay: Rect = Rect.zero
    var _canFocus: Bool = false
    static var globalId: Int = 0
    var _layoutStyle: LayoutStyle = .computed
    
    /// Event fired when a subview is being added to this view.
    public var subviewAdded = PassthroughSubject<View,Never> ()

    /// Event fired when a subview was removed from this view.
    public var subviewRemoved = PassthroughSubject<View,Never> ()

    /// Event fired when the view receives the mouse event for the first time.
    public var mouseEntered = PassthroughSubject<MouseEvent,Never> ()
    
    /// Event fired when the view receives a mouse event because the mouse is outside its boundary
    public var mouseLeft = PassthroughSubject<MouseEvent,Never> ()
    
    /// Event fired when a mouse event is generated.
    public var mouseClicked = PassthroughSubject<MouseEvent,Never> ()
    
    /// This is a payload that can be set by user code to any value it desires
    public var data: AnyObject? = nil
    
    internal var focusDirection: FocusDirection {
        get {
            superview?.focusDirection ?? _focusDirection
        }
        set(newValue) {
            if let sup = superview {
                sup.focusDirection = newValue
            } else {
                _focusDirection = newValue
            }
        }
    }
    
    /// The array containing the subviews added to this tree, sorted from back to front.
    public var subviews: [View] {
        get {
            return _subviews
        }
    }
    
    var _tabStop: Bool = true
    
    /// This only be `true` if the `CanFocus` is also `true` and the focus can be avoided by setting this to `false`
    public var tabStop: Bool {
        get { return _tabStop }
        set {
            if _tabStop != newValue {
                _tabStop = canFocus && newValue
            }
        }
    }
    
    /**
     * Controls how the view's `frame` is computed during the layoutSubviews method, if `absolute`, then
     * `layoutSubviews` does not change the `frame` properties, otherwise the `frame` is updated from the
     * values in x, y, width and height properties.
     */
    public var layoutStyle: LayoutStyle {
        get {
            return _layoutStyle
        }
        set(value) {
            if value != _layoutStyle {
                _layoutStyle = value
                if value == .computed {
                    convertLayoutToComputed()
                }
                setNeedsLayout()
            }
        }
    }
    
    public var canFocus: Bool {
        get {
            return _canFocus
        }
        set {
            if _canFocus != newValue {
                _canFocus = newValue
                if newValue && superview?.canFocus == false {
                        superview?.canFocus = newValue
                }
                tabStop = newValue
            }
        }
    }
        
    /// If this is true, it indicates that the current view has a pending layout operation
    var layoutNeeded: Bool = true
    var childNeedsLayout: Bool = true
    
    /**
     * Points to the current driver in use by the view, it is a convenience property
     * for simplifying the development of new views.
     */
    var driver: ConsoleDriver {
        get {
            return Application.driver
        }
    }
    
    static func nextGlobalId () -> Int
    {
        let r = globalId
        globalId += 1
        return r
    }
    
    /// Returns a value indicating if this View is currently on Top (Active)
    public var isCurrentTop: Bool {
        get {
            Application.current == self
        }
    }
    
    /**
     * Constructor for a view that will use computed layout style based on the values
     * in Pos object (x, y) and Dim objects (width and height)
     */
    public init ()
    {
        _frame = Rect(x:0, y: 0, width: 0, height: 0)
        viewId = View.nextGlobalId ()
    }
    
    /**
     * Constructor for a view that will use fixed layout style using `frame` as the
     * dimension.   When using this constructor, the view will not participate in
     * automatic layout, but you can manually update the frame by overriding
     * `layoutSubviews`
     */
    public init (frame: Rect)
    {
        self._frame = frame
        viewId = View.nextGlobalId ()
        layoutStyle = .fixed
    }
    
    /// Gets or sets a value indicating whether this `View` wants mouse position reports.
    public var wantMousePositionReports: Bool = false
    
    /// Gets or sets a value indicating whether this `View` want continuous button pressed event.
    public var wantContinuousButtonPressed: Bool = false
    
    /**
     * Gets or sets the frame for the view.
     *
     * The coordinate of the frame is relative to the parent, so
     * position 10,5 will position the view is the column 10, row 5 in the container.
     *
     * Altering the Frame of a view will trigger the redrawing of the
     * view as well as the redrawing of the affected regions in the superview and will
     * also set the `layoutStyle` to be `.fixed`
     */
    open var frame: Rect {
        get {
            return _frame
        }
        
        set (value){
            if value == _frame {
                return
            }
            if let parent = superview {
                parent.setNeedsDisplay (_frame)
                parent.setNeedsDisplay (value)
            }
            _frame = value
            setNeedsLayout ()
            setNeedsDisplay (bounds)
        }
    }
    
    /**
     * The bounds represent the View-relative rectangle used for this view.
     *
     * Updates to the Bounds update the Frame, and has the same side effects as updating
     * the frame.
     */
    open var bounds: Rect {
        get {
            return Rect (origin: Point.zero, size: frame.size)
        }
    }
    
    /// Convenience method to set one or more of x, y, width and height properties to their numeric values
    /// - Parameters:
    ///   - x: Optional value for the x property, equivalent to setting it to Pos.at (x)
    ///   - y: Optional value for the y property, equivalent to setting it to Pos.at (y)
    ///   - width: Optional value for the width property, equivalent to setting it to Dim.sized (width)
    ///   - height: Optional value for the height property, equivalent to setting it to Dim.sized (height)
    public func set (x: Int? = nil, y: Int? = nil, width: Int? = nil, height: Int? = nil) {
        if let xv = x {
            self.x = Pos.at (xv)
        }
        if let yv = y {
            self.y = Pos.at (yv)
        }
        if let widthv = width {
            self.width = Dim.sized (widthv)
        }
        if let heightv = height {
            self.height = Dim.sized (heightv)
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
     * - Parameter region: The region that must be flagged for repaint, this is in the coordinates of the receiver.
     */
    public func setNeedsDisplay (_ region: Rect)
    {
        var newRegion = region
        if needDisplay.isEmpty {
            needDisplay = region
        } else {
            let minX = min (needDisplay.minX, region.minX)
            let minY = min (needDisplay.minY, region.minY)
            let maxX = max (needDisplay.maxX, region.maxX)
            let maxY = max (needDisplay.maxY, region.maxY)
            newRegion = Rect (x: minX, y: minY, width: maxX-minX, height: maxY-minY)
            if newRegion == needDisplay {
                return
            }
            needDisplay = newRegion
        }
        log ("view: \(type (of: self)) adding region: \(region)")
        log ("    total: \(needDisplay)")
        if let container = superview {
            let containerRegion = Rect (origin: frame.origin+region.origin, size: newRegion.size)
            container.setNeedsDisplay(containerRegion.intersection (container.bounds))
        }
        if subviews.count == 0 {
            return
        }
        
        for view in subviews {
            if view.frame.intersects(newRegion){
                var childRegion = view.frame.intersection(newRegion)
                childRegion.origin.x -= view.frame.minX
                childRegion.origin.y -= view.frame.minY
                view.setNeedsDisplay (childRegion)
            }
        }
        Application.requestPostProcess()
    }
    
    func setNeedsLayout ()
    {
        if layoutNeeded {
            return
        }
        layoutNeeded = true
        var from = self
        while true {
            if let container = from.superview {
                container.childNeedsLayout = true
                from = container
            } else {
                break
            }
        }
        Application.requestPostProcess()
    }
    
    /**
     * Adds the provided view as a subview of this view
     */
    open func addSubview (_ view: View)
    {
        if view.superview != nil {
            print ("This view is already attached elsewhere")
            abort ()
        }
        _subviews.append (view)
        view.superview = self
        if view.canFocus {
            _canFocus = true
        }
        setNeedsLayout()
        setNeedsDisplay()
        subviewAdded.send (view)
    }
    
    /**
     * Sets the x, y, width and height to fill the container
     * - Parameter padding: any desired padding, if not specified, it defaults to zero
     */
    public func fill(padding: Int = 0) {
        self.x = Pos.at (padding)
        self.y = Pos.at (padding)
        self.width = Dim.fill(padding)
        self.height = Dim.fill (padding)
    }
    
    /// Sets the x, y, width and height to occupy the specified percentage of the container
    /// - Parameter percentage: Number between 0 and 100
    public func fill(percentage: Float) {
        self.x = try? Pos.percent(n: (100-percentage)/2)
        self.y = try? Pos.percent(n: (100-percentage)/2)
        self.width = Dim.percent(n: percentage)
        self.height = Dim.percent(n: percentage)
    }
    
    /**
     * Adds the provided views as subviews of this view
     */
    public func addSubviews (_ views: [View])
    {
        for view in views {
            addSubview(view)
        }
    }
    
    /// Removes the specified view from the container
    open func remove (_ view: View)
    {
        let touched = view.frame
        if let idx = subviews.firstIndex(of: view) {
            setNeedsLayout()
            setNeedsDisplay()

            _subviews.remove(at: idx)
            view.superview = nil
            
            if subviews.count < 1 {
                canFocus = false
            }
            
            for v in subviews {
                if v.frame.intersects(touched) {
                    v.setNeedsDisplay()
                }
            }
            subviewRemoved.send (view)
            if focused == view {
                focused = nil
            }
        }
    }
    
    /// Removes all views from this container
    open func removeAllSubviews ()
    {
        while subviews.count > 0 {
            remove (subviews [0])
        }
    }
    
    func performActionForSubview (_ view: View, action: (View) -> ())
    {
        if subviews.contains(view) {
            action (view)
            setNeedsDisplay()
            view.setNeedsDisplay()
        }
    }
    
    /// Brings the specified subview to the front so it is drawn on top of any other views.
    public func bringSubviewToFront (_ subview: View)
    {
        performActionForSubview(subview) { view in
            if let idx = subviews.firstIndex(of: view) {
                _subviews.remove(at: idx)
                _subviews.append(view)
            }
        }
    }
    
    /// Moves the subview backwards in the hierarchy, only one step
    public func sendSubviewToBack (_ subview: View)
    {
        performActionForSubview(subview) { view in
            if let idx = subviews.firstIndex(of: view) {
                _subviews.remove(at: idx)
                _subviews.insert(view, at: 0)
            }
        }
    }
    
    /// Moves the subview backwards in the hierarchy, only one step
    public func sendBackwards (subview: View)
    {
        performActionForSubview(subview) { view in
            if let idx = _subviews.firstIndex(of: view) {
                _subviews.remove(at: idx)
                _subviews.insert (view, at: idx-1)
            }
        }
    }

    /// Moves the subview backwards in the hierarchy, only one step
    public func bringForward (subview: View)
    {
        performActionForSubview(subview) { view in
            if let idx = _subviews.firstIndex(of: view) {
                if idx + 1 > _subviews.count {
                    _subviews.remove(at: idx)
                    _subviews.insert (view, at: idx+1)
                }
            }
        }
    }

    func viewToScreen (_ pos: Point, clipped: Bool = true) -> Point
    {
        // Computes the real row, col relative to the screen.
        var r = pos + frame.origin
        var ccontainer = superview
        while ccontainer != nil {
            r = r + ccontainer!.frame.origin
            ccontainer = ccontainer?.superview
        }
        
        // The following ensures that the cursor is always in the screen boundaries
        if clipped {
            let driver = Application.driver
            
            let rrow = max (0, min (r.y, driver.size.height - 1))
            let rcol = max (0, min (r.x, driver.size.width - 1))
            r = Point(x: rcol, y: rrow)
        }
        return r
    }
    
    /**
     * Converts a point from screen coordinates into the view coordinate space.
     * - Parameter x: X screen-coordinate point.
     * - Parameter x: Y screen-coordinate point.
     *
     * - Returns: the mapped point
     */
    public func screenToView (loc: Point) -> Point
    {
        if let container = superview {
            let parent = container.screenToView(loc: loc)
            return parent - frame.origin
        } else {
            return loc - frame.origin
        }
    }
    
    // Converts a rectangle in view coordinates to screen coordinates.
    func rectToScreen (_ rect: Rect) -> Rect
    {
        let pos = viewToScreen(rect.origin, clipped: false)
        return Rect (origin: pos, size: rect.size)
    }
    
    /**
     * This moves the cursor to the specified column and row in the view, any additional drawing operation will start at the specified location
     * - Parameter col: Column to move to
     * - Parameter row: Row to move to.
     */
    public func moveTo (col: Int, row: Int)
    {
        let pos = viewToScreen(Point (x: col, y: row))
        driver.moveTo(col: pos.x, row: pos.y)
    }
    
    /**
     * Positions the cursor in the right position based on the currently focused view in the chain.
     */
    open func positionCursor ()
    {
        if let f = focused {
            f.positionCursor()
        } else {
            moveTo (col: frame.minX, row: frame.minY)
        }
    }
    
    var _hasFocus: Bool = false
    
    
    /// True if this view currently has the focus (events go to this view)
    public var hasFocus: Bool {
        get {
            return _hasFocus
        }
    }
    
    func setHasFocus (other: View?, value: Bool)
    {
        if hasFocus != value {
            _hasFocus = value
            if _hasFocus {
                _ = becomeFirstResponder ()
            } else {
                _ = resignFirstResponder ()
            }
        }
        // Remove focus down the chain of subviews if focus is removed
        if let f = focused {
            if !value && focused != other {
                _ = f.resignFirstResponder()
                f.setHasFocus(other: other, value: false)
                focused = nil
            }
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
    
    var _colorScheme: ColorScheme? = nil
    /**
     * The colorscheme used by this view
     */
    open var colorScheme: ColorScheme! {
        get {
            if _colorScheme == nil {
                if let s = superview {
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
     * Removes the SetNeedsDisplay and the ChildNeedsDisplay setting on this view.
     */
    public func clearNeedsDisplay ()
    {
        needDisplay = Rect.zero
    }
    
    /**
     * Performs a redraw of this view and its subviews, only redraws the views that have been flagged for a re-display.
     *
     * Views should set the color that they want to use on entry, as otherwise this will inherit
     * the last color that was set globaly on the driver.
     *
     * - Parameter region: The region to redraw, this is relative to the view itself.
     */
    open func redraw(region: Rect, painter: Painter)
    {
        //painter.clear(needDisplay)
        let clipRect = Rect (origin: Point.zero, size: frame.size)
        for view in subviews {
            if view.frame.intersects(clipRect) && view.frame.intersects(region){
                // TODO: optimize this by computing the intersection of region and view.Bounds
                let childPainter = Painter (from: view, parent: painter)
                view.redraw (region: view.needDisplay, painter: childPainter)
            }
            view.needDisplay = Rect.zero
        }
        clearNeedsDisplay()
    }
    
    /**
     * Causes the specified view and the entire parent hierarchy to have the focused order updated.
     */
    public func setFocus (_ view: View?)
    {
        guard let theView = view else {
            return
        }
        if !theView.canFocus {
            return
        }
        
        if focused != nil && focused! === theView {
            return
        }
        
        // Make sure that this view is a subview
        var c = theView.superview
        while c != nil {
            if c! === self {
                break
            }
            c = c!.superview
        }
        if c == nil {
            // TODO raise error
            return
        }
        if let nf = focused {
            nf.setHasFocus(other: theView, value: false)
        }
        
        let oldFocused = focused
        focused = theView
        theView.setHasFocus(other: oldFocused, value: true)
        theView.ensureFocus()

        // Send focus upwards
        if let s = superview {
            s.setFocus (self)
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
    open func processHotKey(event: KeyEvent) -> Bool
    {
        for view in subviews {
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
    open func processKey(event: KeyEvent) -> Bool
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
    open func processColdKey(event: KeyEvent) -> Bool
    {
        for view in subviews {
            if view.processColdKey(event: event) {
                return true
            }
        }
        return false
    }
    
    /**
     * Method invoked when a mouse event is generated
     */
    open func mouseEvent(event: MouseEvent) -> Bool
    {
        return false
    }
    
    /// Finds the first view in the hierarchy that wants to get the focus if nothing is currently focused, otherwise, it does nothing.
    public func ensureFocus ()
    {
        if focused == nil && subviews.count > 0 {
            if focusDirection == .forward {
                focusFirst ()
            } else {
                focusLast ()
            }
        }
    }
    
    /// Focuses the first focusable subview if one exists.
    public func focusFirst ()
    {
        if subviews == [] {
            superview?.setFocus (self)
            return
        }
        
        for view in subviews {
            if view.canFocus && view.tabStop {
                setFocus (view)
                return
            }
        }
    }
    
    /// Focuses the last focusable subview if one exists.
    public func focusLast ()
    {
        if subviews == [] {
            superview?.setFocus (self)
            return
        }
        
        for view in subviews.reversed() {
            if view.canFocus && view.tabStop {
                setFocus (view)
                return
            }
        }
    }
    
    /**
     * Focuses the previous view in the focus chain
     * - Returns: `true` if previous was focused, `false` otherwise
     */
    @discardableResult
    public func focusPrev () -> Bool
    {
        focusDirection = .backward
        if subviews.count == 0 {
            return false
        }
        
        if focused == nil {
            focusLast ()
            return focused != nil
        }
        var focusedIdx = -1
        var i = subviews.count
        while (i > 0){
            i -= 1
            let w = subviews [i]
            if w.hasFocus {
                if w.focusPrev () {
                    return true
                }
                focusedIdx = i
                continue
            }
            if w.canFocus && focusedIdx != -1 && w.tabStop {
                focused!.setHasFocus(other: w, value: false)
                if w.canFocus && w.tabStop {
                    w.focusLast()
                }
                setFocus (w)
                return true
            }
        }
        if focused != nil {
            focused?.setHasFocus(other: self, value: false)
            focused = nil
        }
        return false
    }
    
    /**
     * Focuses the next view in the focus chain
     * - Returns: `true` if previous was focused, `false` otherwise
     */
    @discardableResult
    public func focusNext () -> Bool
    {
        focusDirection = .forward
        if subviews.count == 0 {
            return false
        }

        if focused == nil {
            focusFirst ()
            return focused != nil
        }
        var focusedIdx = -1
        let n = subviews.count
        for i in 0..<n {
            let w = subviews [i]
            if w.hasFocus {
                if w.focusNext () {
                    return true
                }
                focusedIdx = i
                continue
            }
            if w.canFocus && focusedIdx != -1 && w.tabStop {
                focused!.setHasFocus(other: w, value: false)
                if w.canFocus && w.tabStop {
                    w.focusFirst ()
                }
                setFocus (w)
                return true
            }
        }
        if focused != nil {
            focused?.setHasFocus(other: self, value: false)
            focused = nil
        }
        return false
    }
    
    /// Sets the View's `Frame` to the relative coordinates if its container, given the `Frame` for its container.
    func setRelativeLayout (hostFrame: Rect)
    {
        var w, h, _x, _y: Int

        if let rx = x as? Pos.PosCenter {
            if let rwidth = width {
                w = rwidth.anchor (hostFrame.width)
            } else {
                w = hostFrame.width
            }
            _x = rx.anchor (hostFrame.width - w)
        } else {
            if let rax = x {
                _x = rax.anchor (hostFrame.width)
            } else {
                _x = 0;
            }
            if let rwidth = width {
                if rwidth is Dim.DimFactor && !(rwidth as! Dim.DimFactor).remaining {
                    w = rwidth.anchor (hostFrame.width)
                } else {
                    w = max (rwidth.anchor (hostFrame.width - _x), 0)
                }
            } else {
                w = hostFrame.width - _x
            }
        }
        
        if let ry = y as? Pos.PosCenter {
            if let rheight = height {
                h = rheight.anchor (hostFrame.height)
            } else {
                h = hostFrame.height
            }
            _y = ry.anchor (hostFrame.height - h)
        } else {
            if let ray = y {
                _y = ray.anchor (hostFrame.height)
            } else {
                _y = 0
            }
            if let rheight = height {
                if rheight is Dim.DimFactor && !(rheight as! Dim.DimFactor).remaining {
                    h = rheight.anchor (hostFrame.height)
                } else {
                    h = max (rheight.anchor (hostFrame.height - _y), 0)
                }
            } else {
                h = hostFrame.height - _y
            }
        }
        
        let r = Rect (x: _x, y: _y, width: w, height: h)
        if frame != r {
            frame = r
        }
    }
    
    var _x: Pos? = nil
    /// Gets or sets the X position for the view (the column).  This is only used when the LayoutStyle is `computed`, if the
    /// LayoutStyle is set to `absolute`, this value is ignored.
    public var x: Pos? {
        get { return _x }
        set(value) {
            _x = value
            setNeedsLayout()
        }
    }
    var _y: Pos? = nil
    /// Gets or sets the Y position for the view (the row).  This is only used when the LayoutStyle is `computed`, if the
    /// LayoutStyle is set to `absolute`, this value is ignored.
    public var y: Pos? {
        get { return _y }
        set(value) {
            _y = value
            setNeedsLayout()
        }
    }
    var _width: Dim? = nil
    /// Gets or sets the width for the view. This is only used when the LayoutStyle is `computed`, if the
    /// LayoutStyle is set to `absolute`, this value is ignored.
    public var width: Dim? {
        get { return _width }
        set(value) {
            _width = value
            setNeedsLayout()
        }
    }
    var _height: Dim? = nil
    /// Gets or sets the height for the view. This is only used when the LayoutStyle is `computed`, if the
    /// LayoutStyle is set to `absolute`, this value is ignored.
    public var height: Dim? {
        get { return _height }
        set(value) {
            _height = value
            setNeedsLayout()
        }
    }
 
    func convertLayoutToComputed ()
    {
        if layoutStyle == .fixed {
            let f = frame
            _x = Pos.at (f.minX)
            _y = Pos.at (f.minY)
            _width = Dim.sized (f.width)
            _height = Dim.sized (f.height)
            layoutStyle = .computed
        }
    }
    
    // Computes the RelativeLayout for the view, given the frame for its container.
    // hostFrame is the frame for the host
    func relativeLayout (hostFrame: Rect)
    {
        var ww, hh, xx, yy: Int
        
        if _x != nil && x is Pos.PosCenter {
            ww = _width == nil ? hostFrame.width : _width!.anchor(hostFrame.width)
            xx = _x!.anchor(hostFrame.width - ww)
        } else {
            xx = _x == nil ? 0 : x!.anchor(hostFrame.width)
            ww = _width == nil ? hostFrame.width : _width!.anchor(hostFrame.width-xx)
        }
        
        if _y != nil && y is Pos.PosCenter {
            hh = _height == nil ? hostFrame.height : _height!.anchor(hostFrame.height)
            yy = _y!.anchor(hostFrame.height-hh)
        } else {
            yy = _y == nil ? 0 : y!.anchor(hostFrame.height)
            hh = _height == nil ? hostFrame.height : _height!.anchor(hostFrame.height-yy)
        }
        _frame = Rect (x: xx, y: yy, width: ww, height: hh)
    }
    
    public static func == (lhs: View, rhs: View) -> Bool {
        return lhs === rhs
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(viewId)
    }

    struct Edge: Hashable {
        var from, to: View
    }
    
    // https://en.wikipedia.org/wiki/Topological_sorting
    func topologicalSort (nodes: Set<View>, edges: inout Set<Edge>) -> [View]?
    {
        var result: [View] = []

        // Set of all nodes with no incoming edges
        var s = Set (nodes.filter ({(n:View) -> Bool in
            return edges.allSatisfy({$0.to !== n})
        }))
        
        while s.count > 0 {
            // remove a node n from S
            let n = s.first!
            s.remove(n)
            
            // add n to to tail of L
            result.append(n)
            
            // for each node m with an edge e from n to m do
            for e in edges.filter({$0.from === n}) {
                let m = e.to
                
                // remove the edge from the graph
                if n != self.superview {
                    edges.remove(e)
                }
                
                // if m has no other incoming edges then
                if edges.allSatisfy({$0.to != m && m != self.superview }) {
                    // insert m into S
                    s.insert(m)
                }
            }
        }
        // if graph has edges then
        if edges.count > 0 {
            // return error, graph has at least one cycle
            return nil
        }
        // return L (a topologically sorted order)
        return result
    }
    
    enum layoutError: Error {
        case recursive(msg:String)
    }
    
    func layout () {
        if layoutNeeded  {
            try? layoutSubviews()
            setNeedsDisplay()
        }
        if childNeedsLayout {
            for sub in subviews {
                sub.layout ()
            }
        }
        childNeedsLayout = false
    }
    
    open func layoutSubviews () throws
    {
        if !layoutNeeded {
            return
        }
        
        // Sort out the dependencies of the X, Y, Width, Height properties
        var nodes = Set<View>()
        var edges = Set<Edge>()
        
        func collect (pos: Pos?, from: View, update: inout Set<Edge>) {
            if let pv = pos as? Pos.PosView {
                update.insert (Edge (from: pv.target, to: from))
                return
            }
            if let pc = pos as? Pos.PosCombine {
                collect (pos: pc.left, from: from, update: &update)
                collect (pos: pc.right, from: from, update: &update)
            }
        }

        func collect (dim: Dim?, from: View, update: inout Set<Edge>) {
            if let dv = dim as? Dim.DimView {
                update.insert (Edge (from: dv.target, to: from))
                return
            }
            if let dc = dim as? Dim.DimCombine {
                collect (dim: dc.left, from: from, update: &update)
                collect (dim: dc.right, from: from, update: &update)
            }
        }

        for v in subviews {
            nodes.insert (v)
            if v.layoutStyle != .computed {
                continue
            }
            collect (pos: v.x, from: v, update: &edges)
            collect (pos: v.y, from: v, update: &edges)
            collect (dim: v.width, from: v, update: &edges)
            collect (dim: v.height, from: v, update: &edges)
        }
        guard let ordered = topologicalSort(nodes: nodes, edges: &edges) else {
            throw layoutError.recursive(msg: "There is a recursive cycle in the relative Pos/Dim in the views")
        }
        for v in ordered {
            if v.layoutStyle == .computed {
                v.setRelativeLayout(hostFrame: frame)
            }
            try v.layoutSubviews()
            v.layoutNeeded = false
        }
        
        if superview == Application.top && layoutNeeded && ordered.count == 0 && layoutStyle == .computed {
            setRelativeLayout(hostFrame: frame)
        }
        
        layoutNeeded = false
        childNeedsLayout = false
    }
    
    open func mouseEnter(event: MouseEvent) -> Bool {
        // TODO OnMouseEnter
        return true
    }
    
    public func mouseLeave(event: MouseEvent) -> Bool {
        // TODO OnMouseLeave
        return true
        
    }
    
    var oldFocused: View? = nil
    open func becomeFirstResponder() -> Bool {
        if let old = oldFocused {
            setFocus(old)
            if focused == old {
                _ = old.becomeFirstResponder()
            }
        }
        if let sup = superview {
            if sup.focused != self {
                sup.setFocus(self)
            }
        }
            
        setNeedsDisplay()
        oldFocused = nil
        return true
    }
    
    open func resignFirstResponder() -> Bool {
        oldFocused = focused
        setHasFocus(other: nil, value: false)
        setNeedsDisplay()
        return true
    }
    

    open var debugDescription: String {
        var subtext: String = ""
        
        for x in _subviews {
            subtext += "    --- "
            let slots = x.debugDescription.split (separator: "\n")
            for t in slots {
                subtext += "    \(t)\n"
            }
        }
        return "view \(type(of:self))-\(viewId) frame: \(frame)\n\n\(subtext)"
    }
    
    /// Helper utility that can be used to determine if the event contains a hotkey invocation, which is Alt+letter
    /// - Parameters:
    ///   - event: the event provided by the Application
    ///   - hotKey: A Character? that contains the letter that represents the hotkey
    /// - Returns: True if hotkey is not nil, and the letter alt + this character (uppercase or lowercase) is pressed.
    public static func eventTriggersHotKey (event: KeyEvent, hotKey: Character?) -> Bool
    {
        if let hk = hotKey, event.isAlt {
            switch event.key {
            case let .letter(ch) where ch == hk || ch.lowercased() == hk.lowercased():
                return true
                
            default:
                break
            }
        }
        return false

    }
}
