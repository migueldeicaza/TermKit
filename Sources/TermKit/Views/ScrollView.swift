//
//  ScrollView.swift
//  TermKit
//
//  Created by Miguel de Icaza on 4/28/19.
//  Copyright © 2019 Miguel de Icaza. All rights reserved.
//

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
public class ScrollBarView : View {
    var isVertical: Bool = false
    var size: Int
    var _position: Int
    
    /// This event is raised when the position on the scrollbar has changed.
    public var changedPosition : (_ sender: ScrollBarView, _ old: Int, _ new: Int)->Void = { x, y, z in }
    
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
    
    public override func redraw(region: Rect) {
        let paint = getPainter ()
        paint.attribute = colorScheme!.normal
        if isVertical {
            if region.right < bounds.width - 1 {
                return
            }
            let col = bounds.width - 1
            var bh = bounds.height
            var special : Unicode.Scalar
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
                moveTo(col: col, row: bounds.height - 1)
                paint.add (rune: "v");
            
                for y in 0..<bh {
                    moveTo(col: col, row: y+1)
                    
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
            var special : Unicode.Scalar
            
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
                    }
                    paint.add (rune: special);
                }
                paint.add (rune: ">");
            }
        }
    }
    
    public override func mouseEvent(event: MouseEvent) -> Bool {
        if event.flags != .button1Clicked {
            return false
        }
        let location = isVertical ? event.y : event.x
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
    
    public override var debugDescription: String {
        return "ScrollView (\(super.debugDescription))"
    }
}


/// Scrollviews are views that present a window into a virtual space where
/// subviews are added.  Similar to the iOS UIScrollView.
///
/// The subviews that are added to this `Gui.ScrollView` are offset by the
/// ``contentOffset` property.  The view itself is a window into the
/// space represented by the `contentSize`

public class ScrollView : View {
    var contentView: View
    var vertical, horizontal: ScrollBarView
    var _showsHorizontalScrollIndicator = false
    var _showsVerticalScrollIndicator = false
    
    public override init ()
    {
        contentView = View ()
        vertical = ScrollBarView (size: 0, position: 0, isVertical: true)
        horizontal = ScrollBarView (size: 0, position: 0, isVertical: true)
        super.init()
        horizontal.changedPosition = { sender, old, new in
            
        }
        vertical.changedPosition = { sender, old, new in
            
        }
        super.addSubview(contentView)
        canFocus = true
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
    
    var _contentOffset : Point = Point.zero
    /// Represents the top left corner coordinate that is displayed by the scrollview
    public var contentOffset : Point {
        get {
            return _contentOffset
        }
        set(value) {
            _contentOffset = Point(x: -abs(value.x), y: -abs (value.y))
            contentView.frame = Rect(origin: _contentOffset, size: contentSize)
            vertical.position = max (0, -_contentOffset.y)
            horizontal.position = max (0, -_contentOffset.x)
            setNeedsDisplay()
        }
    }
    
    /// Adds the view to the scrollview.
    public override func addSubview(_ view: View) {
        contentView.addSubview(view)
    }
    
    /// Gets or sets the visibility for the horizontal scroll indicator
    public var showHorizontalScrollIndicator : Bool {
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
    public var showVerticalScrollIndicator : Bool {
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
    
    public override func redraw(region: Rect) {
        let oldClip = clipToBounds()
        driver.setAttribute(colorScheme!.normal)
        clear ()
        super.redraw(region: region)
        driver.clip = oldClip
        driver.setAttribute(colorScheme!.normal)
    }
    
    public override func positionCursor() {
        if subviews.count == 0 {
            driver.moveTo(col: 0, row: 0)
        } else {
            super.positionCursor()
        }
    }
    public override func removeAllSubviews() {
        contentView.removeAllSubviews()
    }
    
    /**
     * Scrolls the view up.
     * - Parameter lines: the number of lines to scroll up
     * - Returns: `true` if the it was scrolled
     */
    public func scrollUp (lines:Int) -> Bool
    {
        if _contentOffset.y < 0 {
            contentOffset = Point (x: contentOffset.x, y: min (contentOffset.y + lines, 0))
            return true
        }
        return false
    }

    /**
     * Scrolls the view down.
     * - Parameter lines: the number of lines to scroll down
     * - Returns: `true` if the it was scrolled
     */
    public func scrollDown (lines:Int) -> Bool
    {
        let ny = max (-contentSize.height, contentOffset.y - lines)
        if ny == contentOffset.y {
            return false
        }
        
        contentOffset = Point (x: contentOffset.x, y: ny)
        return true
    }
    
    /**
     * Scrolls the view left
     * - Parameter cols: the number of columns to scroll left
     * - Returns: `true` if the it was scrolled
     */
    public func scrollLeft (cols:Int) -> Bool
    {
        if contentOffset.x < 0 {
            contentOffset = Point (x: min (contentOffset.x + cols, 0), y: contentOffset.y)
            return true
        }
        return false
    }
    
    /**
     * Scrolls the view right.
     * - Parameter lines: the number of columns to scroll right
     * - Returns: `true` if the it was scrolled
     */
    public func scrollRight (cols:Int) -> Bool
    {
        let nx = max (-contentSize.width, contentOffset.x - cols)
        if nx == contentOffset.x {
            return false
        }
        
        contentOffset = Point (x: nx, y: contentOffset.y)
        return true
    }

    public override func processKey(event: KeyEvent) -> Bool {
        if super.processKey(event: event) {
            return true
        }
        switch event.key {
        case .cursorUp:
            return scrollUp(lines: 1)
        case .letter("v") where event.isAlt, .pageUp:
            return scrollUp(lines: bounds.height)
        case .controlV, .pageDown:
            return scrollDown(lines: bounds.height)
        case .cursorDown:
            return scrollDown(lines: 1)
        case .cursorLeft:
            return scrollLeft(cols: 1)
        case .cursorRight:
            return scrollRight(cols: 1)
        default:
            return false
        }
    }
    
    public override var debugDescription: String {
        return "ScrollView (\(super.debugDescription))"
    }
}
