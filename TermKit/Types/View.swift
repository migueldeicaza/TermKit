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
    
    /**
     * Points to the current driver in use by the view, it is a convenience property
     * for simplifying the development of new views.
     */
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
    
    
}
