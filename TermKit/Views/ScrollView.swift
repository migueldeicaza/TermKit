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
    var vertical : Bool = false
    var size : Int
    
    /// This event is raised when the position on the scrollbar has changed.
    public var changedPosition : ()->Void = {}
    
    /**
     * Initializes the ScrollBarView
     *
     * - Parameter rect: the region where the scrollbar is displayed
     * - Paramter size: the size that this scrollbar represents
     * - Parameter position: The position of the scrollbar within the size
     * - Parameter isVertical: whether this is a vertical or horizontal scrollbar
     */
    public init (frame: Rect, size: Int, position: Int, isVertical: Bool)
    {
        self.position = position
        self.size = size
        super.init (frame: frame)
    }
    
    /// The position to show the scrollbar at.
    public var position: Int {
        didSet {
            setNeedsDisplay()
        }
    }
    
    public override func redraw(region: Rect) {
        driver.setAttribute(colorScheme!.normal)
        if vertical {
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
                    moveTo (col: col, row: y)
                    special = (y < by1 || y > by2) ? driver.stipple : driver.diamond
                    driver.addRune(special);
                }

            } else {
                bh -= 2;
                let by1 = position * bh / size;
                let by2 = (position + bh) * bh / size;
                
                moveTo(col: col, row: 0)
                driver.addRune ("^")
                moveTo(col: col, row: bounds.height - 1)
                driver.addRune ("v");
            
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
                    driver.addRune (special);
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
                    driver.addRune (special)
                }
            } else {
                bw -= 2;
                let bx1 = position * bw / size
                let bx2 = (position + bw) * bw / size
                
                moveTo (col: 0, row: row)
                driver.addRune ("<");
                
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
                    driver.addRune (special);
                }
                driver.addRune (">");
            }
        }
    }
    
    public override func mouseEvent(event: MouseEvent) -> Bool {
        if event.flags != .button1Clicked {
            return false
        }
        let location = vertical ? event.y : event.x
        
        return true
    }
    
    public override var debugDescription: String {
        return "ScrollView (\(super.debugDescription))"
    }
}

public class ScrollView : View {
    var contentView: View
    var vertical, horizontal: ScrollBarView
    var showsHorizontalScrollIndicator = false
    var showsVerticalScrollIndicator = false
    
    public override init ()
    {
        contentView = View ()
        vertical = ScrollBarView (frame: Rect.zero, size: 0, position: 0, isVertical: true)
        horizontal = ScrollBarView (frame: Rect.zero, size: 0, position: 0, isVertical: true)
        super.init()
        horizontal.changedPosition = {
            
        }
        vertical.changedPosition = {
            
        }
        super.addSubview(contentView)
        canFocus = true
    }
    
    public var contentSize : Size = Size.empty {
        didSet {
            contentView.frame = Rect (origin: contentOffset, size: contentSize)
            vertical.size = contentSize.height
            horizontal.size = contentSize.width
            setNeedsDisplay()
        }
    }
    
    var contentOffset : Point = Point.zero {
        didSet {
            
        }
    }
    
    public override var debugDescription: String {
        return "ScrollView (\(super.debugDescription))"
    }
}
