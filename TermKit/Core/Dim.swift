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
    var n : Int
    func Anchor (_ width : Int) -> Int
    {
        return n
    }
    
    class DimFactor : Dim {
        var factor : Float
        init (_ n : Float)
        {
            factor = n
            super.init (0)
        }
        
        override func Anchor (_ width : Int) -> Int
        {
            return Int (Float (width) * factor)
        }
    }
    
    /**
     * Creates a percentage Pos object, the percentage is based on the dimension of the container
     *
     * - Parameter n: A value between 0 and 100 representing the percentage.
     */
    public static func percent (n : Float) -> Dim
    {
        let v = n < 0 || n > 100 ? 0 : n
        return DimFactor (v / 100)
    }
    
    class DimFill : Dim {
       
        override init (_ margin : Int)
        {
            super.init (margin)
        }
        
        override func Anchor (_ width : Int) -> Int
        {
            return width - n
        }
    }
    
    static var zeroMargin = DimFill (0)
    
    /**
     * Creates a dimension that fills until the end, leaving the specified margin at the end
     */
    public static func fill (_ margin : Int = 0) -> Dim
    {
        if (margin == 0){
            return zeroMargin
        }
        return DimFill (margin)
    }
    
    /// Creates a dimension object with the fixed value specified    /// Produces a dimension that adds the two specified dimensions together
    public init (_ n : Int)
    {
        self.n = n
    }
    
    class DimCombine : Dim {
        var left, right : Dim
        var add : Bool
        
        init (add : Bool, left : Dim, right : Dim)
        {
            self.add = add
            self.left = left
            self.right = right
            super.init (0)
        }
        
        override func Anchor (_ width : Int) -> Int
        {
            let la = left.Anchor (width)
            let ra = right.Anchor (width)
            return add ? la + ra : la - ra
        }
    }
    
    /// Produces a dimension that adds the two specified dimensions together
    public static func + (lhs : Dim, rhs : Dim) -> Dim
    {
        return DimCombine (add: true, left: lhs, right: rhs)
    }

    /// Produces a dimension that subtracts the second dimension value from the first
    public static func - (lhs : Dim, rhs : Dim) -> Dim
    {
        return DimCombine (add: false, left: lhs, right: rhs)
    }
    
    enum Side {
        case Height
        case Width
    }
    
    class DimView : Dim {
        var target : View
        var side : Side
        
        init (_ target : View, side : Side)
        {
            self.target = target
            self.side = side
            super.init (0)
        }
        
        override func Anchor (_ width : Int) -> Int
        {
            switch (side){
            case .Height:
                return target.frame.height
            case .Width:
                return target.frame.width
            }
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
    public static func width (view : View) -> Dim
    {
        return DimView (view, side: .Width)
    }
    
    /**
     * Creates a dimension that represents the height of the referenced view.
     *
     * There should be no cycles in the references, if there is a cycle, the
     * layout system will throw an error
     *
     * - Paramter view: the view from which the width will be computed
     */
    public static func height (view : View) -> Dim
    {
        return DimView (view, side: .Height)
    }

}
