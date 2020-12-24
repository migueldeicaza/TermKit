//
//  Pos.swift - Implements the position class, used to layout objects
//  MiniGui
//
//  Created by Miguel de Icaza on 4/5/19.
//  Copyright © 2019 Miguel de Icaza. All rights reserved.
//

import Foundation

/**
 * Describes a position which can be an absolute value, a percentage, centered, or
 * relative to the ending dimension.   Integer values are implicitly convertible to
 * an absolute Pos.    These objects are created using the static methods `percent`,
 * `anchorEnd` and `center`.   The `Pos` objects can be combined with the addition and
 * subtraction operators.
 *
 * Use the `Pos` objects on the `x` or `y` properties of a view to control the position.
 *
 * These can be used to set the absolute position, when merely assigning an
 * integer value (via the implicit integer to `Pos` conversion), and they can be combined
 * to produce more useful layouts, like: `pos.center - 3`, which would shift the postion
 * of the view 3 characters to the left after centering for example.
 *
 * It is possible to reference coordinates of another view by using the methods
 * `left(of: view)`, `right(of: view)`, `bottom(of: View)`, `top(of: View)`.
 * The `x(of: View)` and `y(of: View)` are
 * aliases to `left(of: View)` and `top(of: View)` respectively.
 *
 * Examples:
 * ```
 * label = Label ("Hello world")
 * label.x = Pos.at (10)        // at column 10
 * label.y = Pos.percent (50)   // At 50%
 * label.x = Pos.center ()      // center position
 * // Center relative to another label
 * label.x = Pos.center () - Dim.width(anotherLabel)
 * ```
 */
public class Pos {
    func anchor (_ width: Int) -> Int { return 0 }
    
    class PosFactor: Pos {
        var factor: Float
        
        init (factor: Float)
        {
            self.factor = factor
        }
        
        override func anchor(_ width: Int) -> Int {
            return Int (Float(width) * factor);
        }
        
        var debugDescription: String {
            return "PosFactor (\(factor))"
        }
    }
    
    /**
     * Creates a Pos object the represents a percentage of the container's bounds
     *
     * This example creates a `TextView` that is centered horizontally, is 50% of the
     * way down is 30% in height and is 80% the width of the `View` it is added to
     * ```
     * let textView = TextView()
     * textView.x = Pos.center ()
     * textView.y = Pos.percent (50)
     * textView.width = Dim.percent (80)
     * textView.height = Dim.percent (30)
     * ```
     * - Parameter n: A value between 0 and 100 representing the percentage.
     */
    public static func percent (n: Float) throws -> Pos
    {
        if (n < 0 || n > 100){
            throw SizeError ()
        }
        return PosFactor (factor: n/100.0)
    }
    
    class PosAnchorEnd: Pos {
        var n: Int
        
        init (_ n: Int)
        {
            self.n = n
        }
        
        override func anchor (_ width: Int) -> Int
        {
            return width - n
        }
        
        var debugDescription: String {
            return "PosAnchorEnd (margin: \(n))"
        }
    }
    
    static var emptyAnchorEnd = PosAnchorEnd (0)
    
    /**
     * Creates a Pos object that is anchored to the end (right side or bottom)), useful to flush
     * the layout from the right or bottom.
     *
     * This example shows how to align a `Button` to the bottom-right of the `View`
     * ```
     * anchorButton.x = pos.anchorEnd () - (pos.right (anchorButton) - pos.left (anchorButton))
     * anchorButton.y = pos.anchorEnd (1)
     * ```
     * - Parameter margin: An optional margin from the end, defaults to zero.
     * - Returns: the `Pos` object anchored to the end (the bottom or the right side).
     */
    public static func anchorEnd (margin: Int = 0) -> Pos
    {
        let actual = margin < 0 ? 0 : margin
        if actual == 0 {
            return emptyAnchorEnd
        }
        return PosAnchorEnd (margin)
    }
    
    class PosCenter: Pos {
        override func anchor (_ width: Int) -> Int
        {
            return width / 2
        }
        
        var debugDescription: String {
            return "PosCenter ()"
        }
    }
    
    static var _center = PosCenter ()
    
    /**
     * Creates a `Pos` object that represents the center relative to the parent
     *
     *This creates a `TextField` that is centered horizontally, is 50% of the way down,
     *  is 30% the height, and is 80% the width of the `View` it added to.
     * ```
     * var textView = TextView ()
     * textView.x = Pos.center (),
     * textView.y = Pos.percent (50),
     * textView.width = Dim.percent (80),
     * textView.height = Dim.percent (30),
     * };
     * ```
     * - Returns: the center Position object
     */
    public static func center () -> Pos
    {
        return _center
    }
    
    class PosAbsolute: Pos {
        var n: Int
        
        init (_ n: Int)
        {
            self.n = n
        }
        
        override func anchor (_ width: Int) -> Int
        {
            return n
        }
        
        var debugDescription: String {
            return "PosAbsolute (\(n))"
        }
    }
    
    /**
     * Creates a new `Pos` object for the absolute position specified
     * - Parameter n: a specific location
     */
    public static func at (_ n: Int) -> Pos
    {
        return PosAbsolute (n)
    }
    
    class PosCombine: Pos {
        var left, right: Pos
        var add: Bool
        
        init (left: Pos, right: Pos, add: Bool)
        {
            self.left = left
            self.right = right
            self.add = add
        }
        
        override func anchor (_ width: Int) -> Int
        {
            let la = left.anchor (width)
            let ra = right.anchor (width)
            return add ? la + ra : la - ra
        }
        
        var debugDescription: String {
            return "PosCombine (\(left) \(add ? "+" : "-") \(right))"
        }
    }
    
    /// Produces a dimension that adds the two specified positions together
    public static func + (lhs:Pos, rhs: Pos) -> Pos
    {
        return PosCombine (left: lhs, right: rhs, add: true)
    }

    /// Produces a dimension that adds the two specified positions together
    public static func + (lhs:Pos, rhs: Int) -> Pos
    {
        return PosCombine (left: lhs, right: Pos.at(rhs), add: true)
    }

    /// Produces a dimension that subtracts the second position value from the first
    public static func - (lhs:Pos, rhs: Pos) -> Pos
    {
        return PosCombine (left: lhs, right: rhs, add: false)
    }

    /// Produces a dimension that subtracts the second position value from the first
    public static func - (lhs:Pos, rhs: Int) -> Pos
    {
        return PosCombine (left: lhs, right: Pos.at(rhs), add: false)
    }

    enum Side {
        case X
        case Y
        case Right
        case Bottom
    }
    
    class PosView: Pos {
        var target: View
        var side: Side
        
        init (_ view: View, side: Side)
        {
            self.target = view
            self.side = side
        }
       
        override func anchor (_ width: Int) -> Int
        {
            switch (side){
            case .X:
                return target.frame.minX
            case .Y:
                return target.frame.minY
            case .Right:
                return target.frame.right
            case .Bottom:
                return target.frame.bottom
            }
        }
        
        var debugDescription: String {
            return "PosView (\(side), target=\(target))"
        }
    }
    
    /// Creates a position object that references the left-side of the provided view
    public static func left (of view: View) -> Pos
    {
        return PosView (view, side: .X)
    }

    /// Creates a position object that references the colum coordinate of the provided view
    public static func x (of view: View) -> Pos
    {
        return PosView (view, side: .X)
    }

    /// Creates a position object that references the top (y or row) coordinate of the provided view
    public static func top (of view: View) -> Pos
    {
        return PosView (view, side: .Y)
    }
    
    /// Creates a position object that references the y (row) coordinate of the provided view
    public static func y (of view: View) -> Pos
    {
        return PosView (view, side: .Y)
    }

    /// Creates a position object that references the right side coordinate of the provided view
    public static func right (of view: View) -> Pos
    {
        return PosView (view, side: .Right)
    }

    /// Creates a position object that references the bottom side coordinate of the provided view
    public static func bottom (of view: View) -> Pos
    {
        return PosView (view, side: .Bottom)
    }
}
