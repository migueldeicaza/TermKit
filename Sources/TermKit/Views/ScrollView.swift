//
//  ScrollView.swift
//  TermKit
//
//  Created by Miguel de Icaza on 4/28/19.
//  Copyright © 2019 Miguel de Icaza. All rights reserved.
//
// TODO:
// - should have three modes for showing the scrollbar: never, auto, always
// - should figure out auto-focus, and scroll the view to the right place
//   based on what is focused
// - view.clear() does not work well with contentOffset, as it does not cover
//   the entire region
// - view.redraw() is getting the full size, not the visible size of the ScrollView
//   region affected (so everything has to draw from 0, even if not needed).  A child
//   view of say 100x100 inside a 10x10 where contenOffset=30,30 should get a region
//   with (30-30, w:10, h:10) so it can optimize its rendering.

import Foundation

/**
 * ScrollBarViews are views that display a 1-character scrollbar, either horizontal or vertical
 *
 * The scrollbar is drawn to be a representation of the Size, assuming that the
 * scroll position is set at `position`
 *
 * If the region to display the scrollbar is larger than three characters,
 * arrow indicators are drawn.
 */
open class ScrollBarView: View {
    var isVertical: Bool = false
    var size: Int
    var _position: Int
    
    /// This event is raised when the position on the scrollbar has changed.
    public var changedPosition: (_ sender: ScrollBarView, _ old: Int, _ new: Int)->Void = { x, y, z in }
    
    /**
     * Initializes the ScrollBarView
     *
     * - Parameter rect: the region where the scrollbar is displayed
     * - Paramter size: the size that this scrollbar represents
     * - Parameter position: The position of the scrollbar within the size
     * - Parameter isVertical: whether this is a vertical or horizontal scrollbar
     */
    public init (size: Int, position: Int, isVertical: Bool)
    {
        self._position = position
        self.size = size
        self.isVertical = isVertical
        super.init ()
        wantContinuousButtonPressed = true
    }
    
    func clampPosition (_ newPosition: Int) -> Int
    {
        let visibleSize = getBarSize ()
        let maxSize = max (0, size-visibleSize)
        if newPosition > maxSize {
            return maxSize
        } else {
            return newPosition
        }
    }
    
    /// The position to show the scrollbar at.
    public var position: Int {
        get {
            return _position
        }
        set {
            let clamped = clampPosition (newValue)
            guard _position != newValue else {
                return
            }
            let old = _position
            _position = clamped
            changedPosition (self, old, _position);
            setNeedsDisplay()
        }
    }
    
    open override func redraw(region: Rect, painter paint: Painter) {
        paint.attribute = colorScheme!.normal
        if isVertical {
            if region.right < bounds.width - 1 {
                return
            }
            let col = bounds.width - 1
            var bh = bounds.height
            var special: Unicode.Scalar
            if bh < 4 {
                let by1 = position * bh / size;
                let by2 = (position + bh) * bh / size;
                
                for y in 0..<bh {
                    paint.goto (col: col, row: y)
                    special = (y < by1 || y > by2) ? driver.stipple : driver.diamond
                    paint.add(rune: special);
                }

            } else {
                bh -= 2;
                let by1 = position * bh / size;
                let by2 = (position + bh) * bh / size;
                
                paint.goto(col: col, row: 0)
                paint.add (rune: "^")
                paint.goto (col: col, row: bounds.height - 1)
                paint.add (rune: "v");
            
                for y in 0..<bh {
                    paint.goto(col: col, row: y+1)
                    
                    if y < by1 || y > by2 {
                        special = driver.stipple
                    } else {
                        if by2 - by1 == 0 {
                            special = driver.diamond
                        } else {
                            if (y == by1) {
                                special = driver.topTee
                            } else if (y == by2) {
                                special = driver.bottomTee
                            } else {
                                special = driver.vLine
                            }
                        }
                        // TESTING: use a darker stipple?
                        special = "\u{2593}"
                    }
                    paint.add (rune: special);
                }
            }
        } else {
            if region.bottom < bounds.height - 1 {
                return
            }
            let row = bounds.height - 1;
            var bw = bounds.width;
            var special: Unicode.Scalar
            
            if (bw < 4) {
                let bx1 = position * bw / size;
                let bx2 = (position + bw) * bw / size;
                
                for x in 0..<bw {
                    moveTo(col: 0, row: x)
                    if x < bx1 || x > bx2 {
                        special = driver.stipple
                    } else {
                        special = driver.diamond
                    }
                    paint.add (rune: special)
                }
            } else {
                bw -= 2;
                let bx1 = position * bw / size
                let bx2 = (position + bw) * bw / size
                
                paint.goto (col: 0, row: row)
                paint.add (rune: "<");
                
                for x in 0..<bw {
                    if x < bx1 || x > bx2 {
                        special = driver.stipple
                    } else {
                        if bx2 - bx1 == 0 {
                            special = driver.diamond
                        } else {
                            if x == bx1 {
                                special = driver.leftTee
                            } else if x == bx2 {
                                special = driver.rightTee
                            } else {
                                special = driver.hLine
                            }
                        }
                        // TESTING: use a stronger shade?
                        special = "\u{2593}"
                    }
                    paint.add (rune: special);
                }
                paint.add (rune: ">");
            }
        }
    }
    
    open override func mouseEvent(event: MouseEvent) -> Bool {
        if event.flags != .button1Clicked {
            return false
        }
        let location = isVertical ? event.pos.y : event.pos.x
        var barsize = getBarSize ()
        
        if barsize < 4 {
            // handle scrollbars with no buttons
            print ("TODO at ScrollBarView.mouseEvent for small scrollbars\n")
        } else {
            barsize -= 2
            // handle scrollbars with arrow buttons
            let pos = position
            if location == 0 {
                if pos > 0 {
                    position = pos - 1
                }
            } else if location == barsize + 1 {
                if pos + 1 + barsize < size {
                    position = pos + 1
                }
            } else {
                print ("Another todo at ScrollBarView.mouseevent")
            }
        }
        return true
    }
    
    func getBarSize () -> Int {
        isVertical ? bounds.height : bounds.width
    }
    
    open override var debugDescription: String {
        return "ScrollBarView (\(super.debugDescription))"
    }
}

class _ContentView: View {
    var scrollView: ScrollView!
    override init ()
    {
        super.init()
    }
    
    open override func redraw(region: Rect, painter: Painter) {
        // TODO: the region should be shifted, so the receiver knows what to not render
        super.redraw(region: region, painter: painter)
    }

    open override func positionCursor() {
        let pos = scrollView.viewToScreen(Point (x: 0, y: 0))
        driver.moveTo(col: pos.x, row: pos.y)
    }
    open override var debugDescription: String {
        get {
            "ScrollView._ContentView()"
        }
    }
}

/// Scrollviews are views that present a window into a virtual space where
/// subviews are added.  Similar to the iOS UIScrollView.
///
/// The subviews that are added to this `Gui.ScrollView` are offset by the
/// ``contentOffset` property.  The view itself is a window into the
/// space represented by the `contentSize`

open class ScrollView : View {
    var contentView: _ContentView!
    var vertical, horizontal: ScrollBarView
    var _showsHorizontalScrollIndicator = false
    var _showsVerticalScrollIndicator = false
    var settingContentOffset = false
    
    public override init ()
    {
        contentView = _ContentView()
        contentView.canFocus = true
        vertical = ScrollBarView (size: 0, position: 0, isVertical: true)
        horizontal = ScrollBarView (size: 0, position: 0, isVertical: false)
        super.init()
        contentView.scrollView = self
        horizontal.changedPosition = { sender, old, new in
            if self.settingContentOffset { return }
            self.contentOffset = Point(x: new, y: self.contentOffset.y)
        }
        vertical.changedPosition = { sender, old, new in
            if self.settingContentOffset { return }
            self.contentOffset = Point(x: self.contentOffset.x, y: new)
        }
        super.addSubview(contentView)
        canFocus = true
    }
    
    open override func redraw(region: Rect, painter: Painter) {
        //let oldClip = clipToBounds()
        super.redraw(region: region, painter: painter)
        //driver.clip = oldClip
    }
    
    public override func layoutSubviews () {
        let f = bounds
        
        contentView.frame = Rect(
            x: f.minX,
            y: f.minY,
            width: f.width-(_showsVerticalScrollIndicator ? 1 : 0),
            height: f.height-(_showsHorizontalScrollIndicator ? 1 : 0))
        try? contentView.layoutSubviews()
        if _showsVerticalScrollIndicator {
            vertical.frame = Rect (
                x: f.maxX-1,
                y: 0,
                width: 1,
                height: f.height)
        }
        if _showsHorizontalScrollIndicator {
            horizontal.frame = Rect (
                x: 0,
                y: f.maxY-1,
                width: f.width-1,
                height: 1)
        }
    }
    
    /// Represents the contents of the data shown inside the scrolview
    public var contentSize : Size = Size.empty {
        didSet {
            contentView.frame = Rect (origin: contentOffset, size: contentSize)
            vertical.size = contentSize.height
            horizontal.size = contentSize.width
            setNeedsDisplay()
        }
    }
    
    var _contentOffset: Point = Point.zero
    /// Represents the top left corner coordinate that is displayed by the scrollview
    public var contentOffset: Point {
        get {
            return _contentOffset
        }
        set(value) {
            settingContentOffset = true
            _contentOffset = Point(x: -abs(value.x), y: -abs (value.y))
            contentView.frame = Rect(origin: _contentOffset, size: contentSize)
            vertical.position = max (0, -_contentOffset.y)
            horizontal.position = max (0, -_contentOffset.x)
            settingContentOffset = false
            setNeedsDisplay()
        }
    }
    
    public override func setNeedsDisplay (_ region: Rect) {
        super.setNeedsDisplay (region.intersection (bounds))
    }
    /// Adds the view to the scrollview.
    open override func addSubview(_ view: View) {
        contentView.addSubview(view)
    }
    
    /// Gets or sets the visibility for the horizontal scroll indicator
    public var showHorizontalScrollIndicator: Bool {
        get {
            return _showsHorizontalScrollIndicator
        }
        set(value) {
            if value == _showsHorizontalScrollIndicator {
                return
            }
            _showsHorizontalScrollIndicator = value
            setNeedsDisplay()
            if value {
                super.addSubview(horizontal)
            } else {
                remove (horizontal)
            }
        }
    }
    
    /// Gets or sets the visibility for the vertical scroll indicator
    public var showVerticalScrollIndicator: Bool {
        get {
            return _showsVerticalScrollIndicator
        }
        set(value) {
            if value == _showsVerticalScrollIndicator {
                return
            }
            _showsVerticalScrollIndicator = value
            setNeedsDisplay()
            if value {
                super.addSubview(vertical)
            } else {
                remove (vertical)
            }
        }
    }
    
    open override func positionCursor() {
        if subviews.count == 0 {
            driver.moveTo(col: 0, row: 0)
        } else {
            super.positionCursor()
        }
    }
    
    open override func removeAllSubviews() {
        contentView.removeAllSubviews()
    }
    
    /**
     * Scrolls the view up.
     * - Parameter lines: the number of lines to scroll up
     * - Returns: `true` if the it was scrolled
     */
    public func scrollUp (lines: Int) -> Bool
    {
        if _contentOffset.y < 0 {
            contentOffset = Point (x: contentOffset.x, y: min (contentOffset.y + lines, 0))
            setNeedsDisplay()
            return true
        }
        return false
    }

    /**
     * Scrolls the view down.
     * - Parameter lines: the number of lines to scroll down
     * - Returns: `true` if the it was scrolled
     */
    public func scrollDown (lines: Int) -> Bool
    {
        let ny = max (-contentSize.height, contentOffset.y - lines)
        if ny == contentOffset.y {
            return false
        }
        setNeedsDisplay()
        contentOffset = Point (x: contentOffset.x, y: ny)
        return true
    }
    
    /**
     * Scrolls the view left
     * - Parameter cols: the number of columns to scroll left
     * - Returns: `true` if the it was scrolled
     */
    public func scrollLeft (cols: Int) -> Bool
    {
        if contentOffset.x < 0 {
            contentOffset = Point (x: min (contentOffset.x + cols, 0), y: contentOffset.y)
            setNeedsDisplay()
            return true
        }
        return false
    }
    
    /**
     * Scrolls the view right.
     * - Parameter lines: the number of columns to scroll right
     * - Returns: `true` if the it was scrolled
     */
    public func scrollRight (cols: Int) -> Bool
    {
        let nx = max (-contentSize.width, contentOffset.x - cols)
        if nx == contentOffset.x {
            return false
        }
        setNeedsDisplay()
        contentOffset = Point (x: nx, y: contentOffset.y)
        return true
    }

    /// If this property is set to true, when the user reaches the end of the scrollview boundaries
    /// the event will not be processed, allowing automatically focusing the next view in the
    /// direction of the moevemnt
    public var autoNavigateToNextViewOnBoundary = false
    
    open override func processKey(event: KeyEvent) -> Bool {
        if super.processKey(event: event) {
            return true
        }
        switch event.key {
        case .cursorUp:
            return scrollUp(lines: 1) || !autoNavigateToNextViewOnBoundary
        case .letter("v") where event.isAlt, .pageUp:
            return scrollUp(lines: bounds.height) || !autoNavigateToNextViewOnBoundary
        case .controlV, .pageDown:
            return scrollDown(lines: bounds.height) || !autoNavigateToNextViewOnBoundary
        case .cursorDown:
            return scrollDown(lines: 1) || !autoNavigateToNextViewOnBoundary
        case .cursorLeft:
            return scrollLeft(cols: 1) || !autoNavigateToNextViewOnBoundary
        case .cursorRight:
            return scrollRight(cols: 1) || !autoNavigateToNextViewOnBoundary
        case .home:
            return scrollUp(lines: contentSize.height) || !autoNavigateToNextViewOnBoundary
        case .end:
            return scrollDown(lines: contentSize.height) || !autoNavigateToNextViewOnBoundary
        default:
            return false
        }
    }
    
    open override var debugDescription: String {
        return "ScrollView (\(super.debugDescription))"
    }
}
