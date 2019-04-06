//
//  Dim.swift
//  MiniGui
//
//  Created by Miguel de Icaza on 4/5/19.
//  Copyright © 2019 Miguel de Icaza. All rights reserved.
//

import Foundation

public class Dim {
    func Anchor (_ width : Int) -> Int
    {
        return 0
    }
    
    class DimFactor : Dim {
        var factor : Float
        init (_ n : Float)
        {
            factor = n
        }
        
        override func Anchor (_ width : Int) -> Int
        {
            return Int (Float (width) * factor)
        }
    }
    
    public static func percent (n : Float) -> Dim
    {
        let v = n < 0 || n > 100 ? 0 : n
        return DimFactor (v / 100)
    }
    
    class DimAbsolute : Dim {
        var n : Int
        
        init (_ n:Int)
        {
            self.n = n
        }
        
        override func Anchor (_ width : Int) -> Int
        {
            return n
        }
    }
    
    class DimFill : Dim {
        var margin : Int
        
        init (_ margin : Int)
        {
            self.margin = margin
        }
        
        override func Anchor (_ width : Int) -> Int
        {
            return width - margin
        }
    }
    
    static var zeroMargin = DimFill (0)
    
    public static func fill (_ margin : Int = 0) -> Dim
    {
        if (margin == 0){
            return zeroMargin
        }
        return DimFill (margin)
    }
    
    public static func Dim (n : Int) -> Dim
    {
        return DimAbsolute (n)
    }
    
    class DimCombine : Dim {
        var left, right : Dim
        var add : Bool
        
        init (add : Bool, left : Dim, right : Dim)
        {
            self.add = add
            self.left = left
            self.right = right
        }
        
        override func Anchor (_ width : Int) -> Int
        {
            let la = left.Anchor (width)
            let ra = right.Anchor (width)
            return add ? la + ra : la - ra
        }
    }
    
    public static func + (lhs : Dim, rhs : Dim) -> Dim
    {
        return DimCombine (add: true, left: lhs, right: rhs)
    }

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
    
    public static func width (view : View) -> Dim
    {
        return DimView (view, side: .Width)
    }
    
    public static func height (view : View) -> Dim
    {
        return DimView (view, side: .Height)
    }

}
