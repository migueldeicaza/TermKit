//
//  Dim.swift - Implements the Dimension class, for layout
//  MiniGui
//
//  Created by Miguel de Icaza on 4/5/19.
//  Copyright © 2019 Miguel de Icaza. All rights reserved.
//

import Foundation

/**
 * Describes a dimension which can be an absolute value, a percentage, fill, or a reference to a dimension of another view
 *
 * To create a `Dim` object, you can choose from one of the following options:
 * - `Dim(n)` constructor creates an absolute dimension of size n
 * - `Dim.percent(n)` creates a dimension that reprensents the n% of the container
 * - `Dim.fill(margin)` creates a dimension that fills to the end of the container dimension, leaving the specified margin on the side
 * - `Dim.width(view)` and `Dim.heigh(view)` are used to reference the computed width or height of another view.
 *
 * Dim objects can be combined using the addition and substraction operators to create
 * various rules, like for example:
 * ```
 * password.width = Dim.width(login) - Dim(4)
 * ```
 */
public class Dim {
    func anchor (_ width: Int) -> Int
    {
        return 0
    }
    
    class DimFactor: Dim {
        var factor: Float
        public private(set) var remaining: Bool
        
        init (_ n: Float, _ r: Bool = false)
        {
            factor = n
            remaining = r
        }
        
        override func anchor (_ width: Int) -> Int
        {
            return Int (Float (width) * factor)
        }
        
        var debugDescription: String {
            return "DimFactor (\(factor))"
        }
    }
    
    /**
     * Creates a percentage Pos object, the percentage is based on the dimension of the container
     * This initializes a `TextField` that is centered horizontally, is 50% of the way down,
     * is 30% the height, and is 80% the width of the <see cref="View"/> it added to.
     * ```
     * var textView = TextView ()
     * textView.x = Pos.center (),
     * textView.y = Pos.percent (50)
     * textView.width = Dim.percent (80)
     * textView.height = Dim.percent (30)
     *
     * ```
     * - Parameter n: A value between 0 and 100 representing the percentage.
     * - Parameter remain: If `true` the Percent is computed based on the remaining space after the X/Y anchor positions.
     * otherwise it is computed on the whole original space.
     */
    public static func percent (n: Float) -> Dim
    {
        let v = n < 0 || n > 100 ? 0 : n
        return DimFactor (v / 100)
    }
    
    class DimAbsolute: Dim {
        var n: Int
        public init (n: Int)
        {
            self.n = n
        }
        
        override func anchor(_ width: Int) -> Int {
            return n
        }
        
        var debugDescription: String {
            return "DimAbsolute (\(n))"
        }
    }
    class DimFill: Dim {
        var margin: Int
        init (_ margin: Int)
        {
            self.margin = margin
        }
        
        override func anchor (_ width: Int) -> Int
        {
            return width - margin
        }
        
        var debugDescription: String {
            return "DimFill (margin=\(margin))"
        }
    }
    
    static var zeroMargin = DimFill (0)
    
    /**
     * Creates a dimension that fills until the end, leaving the specified margin at the end
     * - Parameter margin: optional, the margin to leave at the end
     * - Returns: a new dimension that can fill the dimension leaving the specified martin
     */
    public static func fill (_ margin: Int = 0) -> Dim
    {
        if (margin == 0){
            return zeroMargin
        }
        return DimFill (margin)
    }

    /**
     * Creates an Absolute `Dim` from the specified integer value.
     * - Parameter n: the size to allocate
     * - Returns: a new dimension that is set to the absolute size `n`
     */
    public static func sized (_ n: Int) -> Dim {
        return DimAbsolute(n: n)
    }
    
    class DimCombine: Dim {
        var left, right: Dim
        var add: Bool
        
        init (add: Bool, left: Dim, right: Dim)
        {
            self.add = add
            self.left = left
            self.right = right
        }
        
        override func anchor (_ width: Int) -> Int
        {
            let la = left.anchor (width)
            let ra = right.anchor (width)
            return add ? la + ra : la - ra
        }
        
        var debugDescription: String {
            return "DimCombine (\(left) \(add ? "+" : "-") \(right))"
        }
    }
    
    /// Produces a dimension that adds the two specified dimensions together
    public static func + (lhs: Dim, rhs: Dim) -> Dim
    {
        return DimCombine (add: true, left: lhs, right: rhs)
    }

    /// Produces a dimension that subtracts the second dimension value from the first
    public static func - (lhs: Dim, rhs: Dim) -> Dim
    {
        return DimCombine (add: false, left: lhs, right: rhs)
    }
    
    enum Side {
        case height
        case width
    }
    
    class DimView: Dim {
        var target: View
        var side: Side
        
        init (_ target: View, side: Side)
        {
            self.target = target
            self.side = side
        }
        
        override func anchor (_ width: Int) -> Int
        {
            switch (side){
            case .height:
                return target.frame.height
            case .width:
                return target.frame.width
            }
        }
        
        var debugDescription: String {
            return "DimView (side=\(side), target=\(target))"
        }
    }
    
    /**
     * Creates a dimension that represents the width of the referenced view.
     *
     * There should be no cycles in the references, if there is a cycle, the
     * layout system will throw an error
     *
     * - Paramter view: the view from which the width will be computed
     */
    public static func width (view: View) -> Dim
    {
        return DimView (view, side: .width)
    }
    
    /**
     * Creates a dimension that represents the height of the referenced view.
     *
     * There should be no cycles in the references, if there is a cycle, the
     * layout system will throw an error
     *
     * - Paramter view: the view from which the width will be computed
     */
    public static func height (view: View) -> Dim
    {
        return DimView (view, side: .height)
    }

}
